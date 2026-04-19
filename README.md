# Neuroimaging Research Environment

A portable, reproducible neuroimaging pipeline environment using Docker Compose. Run identical terminal environments across Linux, macOS, and Windows — mount your data at runtime, keep your scripts in version control.

---

A very simple docker setup to unify and simplify my personal neuroimaging research environment across devices and operating systems.

---

## 1. Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (macOS / Windows)
- Docker Engine (Linux)
- Git
- AWS CLI

## 2. Setup on a new machine

```bash
git clone https://github.com/yourname/research-env.git
cd research-env
cp .env.example .env
vim .env # Specific for the machine

docker compose pull          # pulls freesurfer + mrtrix official images
docker compose build tools   # builds the small custom tools image
```

This only needs to be done once per machine. Subsequent `docker compose run` calls start instantly.

---

## 3. Day-to-day usage

### Run a pipeline script

```bash
docker compose run --rm mrtrix bash /research/path/inside/docker/to/script.zsh
docker compose run --rm freesurfer bash /research/path/inside/docker/to/script.zsh
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


## 4. Updating images

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
