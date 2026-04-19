# Neuroimaging Research Environment

A portable, reproducible neuroimaging pipeline environment using Docker Compose. Run identical terminal environments across Linux, macOS, and Windows — mount your data at runtime, keep your scripts in version control.

---

## Architecture

```
Host machine
├── docker-compose.yml       orchestration
├── .env                     machine-specific paths (not committed)
├── Dockerfile.tools         custom utilities image
└── scripts/                 your pipeline scripts (committed)
    ├── pipeline.sh
    └── recon_all.sh

                    ┌─────────────────────────────────────────┐
                    │           docker-compose.yml            │
                    │                                         │
                    │  ┌───────────┐  ┌───────────┐          │
                    │  │ freesurfer│  │  mrtrix   │          │
                    │  │  7.4.1   │  │  latest   │          │
                    │  └─────┬─────┘  └─────┬─────┘          │
                    │        │              │                 │
                    │  ┌─────┴──────────────┴─────┐          │
                    │  │         tools             │          │
                    │  │  vim · htop · tmux · zsh  │          │
                    │  └───────────────────────────┘          │
                    └─────────────────────────────────────────┘

Volumes (bind-mounted from host at runtime):
  /bids         ← BIDS source data         (read-only in all containers)
  /freesurfer   ← FreeSurfer output
  /mrtrix       ← MRtrix output
  /scripts      ← pipeline scripts
```

### Key design decisions

- **No data inside the image.** All data lives on the host and is mounted at runtime via `.env` paths. The image contains only software.
- **Official images for core tools.** `freesurfer/freesurfer` and `mrtrix3/mrtrix3` are pulled directly — no custom layers on top of them.
- **Custom `tools` image** for everything else: utilities (htop, vim, tmux, fzf), Python (nibabel, nilearn, pandas), and zsh.
- **Profiles** prevent all services starting at once. Each service only runs when explicitly called.
- **Orchestration happens on the host.** The host shell (or a wrapper script) calls `docker compose run` for each step in sequence. Containers don't call each other.
- **FreeSurfer license** is mounted from the host at runtime — never committed to the repo.

---

## Repository structure

```
research-env/
├── docker-compose.yml
├── Dockerfile.tools
├── .env                  ← created locally, never committed
├── .env.example          ← template, committed
├── .gitignore
├── scripts/
│   ├── pipeline.sh
│   └── recon_all.sh
└── README.md
```

---

## First-time setup

### 1. Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (macOS / Windows)
- Docker Engine (Linux)
- Git

### 2. Clone the repo

```bash
git clone https://github.com/yourname/research-env.git
cd research-env
```

### 3. Configure local paths

```bash
cp .env.example .env
```

Edit `.env` with paths for this machine:

```env
BIDS_DIR=/path/to/your/bids
FREESURFER_OUTPUT=/path/to/your/freesurfer_output
MRTRIX_OUTPUT=/path/to/your/mrtrix_output
SCRIPTS_DIR=/path/to/your/scripts
FS_LICENSE=/path/to/your/license.txt
```

### 4. Pull images and build tools

```bash
docker compose pull          # pulls freesurfer + mrtrix official images
docker compose build tools   # builds the small custom tools image
```

This only needs to be done once per machine. Subsequent `docker compose run` calls start instantly.

---

## Day-to-day usage

### Run a pipeline script

```bash
# MRtrix pipeline
docker compose run --rm mrtrix bash /scripts/pipeline.sh

# FreeSurfer recon-all
docker compose run --rm freesurfer bash /scripts/recon_all.sh
```

### Interactive session

```bash
# Drop into a container shell
docker compose run --rm mrtrix
docker compose run --rm freesurfer
docker compose run --rm tools       # zsh with htop, vim, python etc.
```

### Orchestrate multiple steps from the host

```bash
#!/bin/bash
# run_full_pipeline.sh — run this on the host, not inside a container

docker compose run --rm mrtrix bash /scripts/step1_preproc.sh
docker compose run --rm freesurfer bash /scripts/step2_recon.sh
docker compose run --rm mrtrix bash /scripts/step3_tractography.sh
```

### Monitor resource usage

```bash
# Per-container live stats (run in a separate terminal)
docker stats

# Full host resource view
docker compose run --rm tools   # then run htop inside
```

---

## Writing pipeline scripts

Scripts live in `scripts/` and use container-internal paths, not host paths. Define paths as variables at the top:

```bash
#!/bin/bash
# scripts/pipeline.sh

BIDS=/bids
FS_DIR=/freesurfer
OUT=/output

mrconvert ${BIDS}/sub-01/dwi/sub-01_dwi.nii.gz ${OUT}/sub-01.mif \
  -fslgrad ${BIDS}/sub-01/dwi/sub-01_dwi.bvec \
            ${BIDS}/sub-01/dwi/sub-01_dwi.bval
```

The container-internal paths (`/bids`, `/output` etc.) are fixed and identical on every machine. Only the host-side paths in `.env` vary.

---

## Volume mount reference

| Container path | Host path (from `.env`) | Access |
|---|---|---|
| `/bids` | `BIDS_DIR` | read-only |
| `/output` (freesurfer) | `FREESURFER_OUTPUT` | read/write |
| `/output` (mrtrix) | `MRTRIX_OUTPUT` | read/write |
| `/freesurfer` (mrtrix) | `FREESURFER_OUTPUT` | read-only |
| `/scripts` | `SCRIPTS_DIR` | read/write |
| `/usr/local/freesurfer/license.txt` | `FS_LICENSE` | read-only |

---

## Updating images

```bash
# Pull latest official images
docker compose pull

# Rebuild tools image after Dockerfile.tools changes
docker compose build tools
```

To pin to a specific version for reproducibility, edit `docker-compose.yml`:
```yaml
image: mrtrix3/mrtrix3:3.0.4   # instead of :latest
```

---

## Deploying on a new machine

```bash
git clone https://github.com/yourname/research-env.git
cd research-env
cp .env.example .env
# edit .env with local paths and FS_LICENSE location
docker compose pull
docker compose build tools
```

That's it. Every machine runs an identical environment.

---

## Notes

- **macOS / Windows**: Docker Desktop runs a lightweight Linux VM transparently. Containers behave identically to Linux but volume I/O across the VM boundary can be marginally slower for large datasets.
- **HPC clusters**: If you need to run on a SLURM cluster, convert the Docker image to Singularity/Apptainer format (`apptainer pull docker://mrtrix3/mrtrix3`). Apptainer is Docker-compatible and runs without root privileges.
- **GUI tools** (FSLeyes, ITK-SNAP): Install these natively on each host — they cannot run inside a container without extra X11/VNC configuration.
- **Image size**: FreeSurfer is ~15 GB. First pull will be slow. Subsequent starts are instant — the image is cached on disk.
