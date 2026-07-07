#!/bin/zsh

# Script to invoke the mrtrix per patient pipeline
# (mrtrix_per_patient_pipeline.zsh) inside the research-env docker environment.
# The script is in research-env/scripts/, which is mounted into the docker env at /scripts/

subject_id=$1

if [[ -z "$subject_id" ]]; then
    echo "Error: no subject_id supplied. Usage: $0 <subject_id>"
    exit 1
fi

sudo docker compose run --rm \
    --user 1000:1000 \
    mrtrix \
    bash /scripts/mrtrix_per_patient_pipeline.zsh "$subject_id"
