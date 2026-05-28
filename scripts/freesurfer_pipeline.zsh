#!/bin/bash

# Main freesurfer pipeline
# To be run from the pch2a/advancedVolumetry directory

subs_dir=/research/advanvedVolumetry/freesurfer_derived_subject_data
bids_dir=/bids


mkdir $subs_dir -p
export SUBJECTS_DIR=$subs_dir

######### SUBJECTS ################################################################################


########### sub-107 ############

recon-all -autorecon1 -s sub-107 -i $bids_dir/sub-107/anat/sub-107_acq_isoSag1mm_T1w.nii.gz



######### CONTROLS #################################################################################
#controlslist=$(ls -d $bids_dir/sub-0* | xargs -n 1 basename)
#
#Temporary controlslist to update missing subjects
#controlslist="sub-001 sub-002 sub-006 sub-007 sub-030 sub-034 sub-035 sub-036 sub-038 sub-042 sub-053"
#echo Processing controls: $controlslist

# Autorecon 1: Skull stripping
#parallel --progress --jobs 8 \
#    /home/ubuntu/freesurfer/bin/recon-all -autorecon1 -s {} -i $bids_dir/{}/anat/{}_acq-isoSag1mm_T1w.nii.gz \
#    -wsthresh 30 -gcut \
#    ::: $controlslist
#correctionlist=(004 017 024 029 032 037 049 050)
#echo Correcting skullstripping for $correctionlist and sub-047
#parallel --progress --jobs 8 \
#    recon-all -skullstrip -wsthresh 50 -no-wsgcaatlas -gcut -clean-bm -subjid sub-{} \
#    ::: $correctionlist
#recon-all -skullstrip -wsthresh 30 -no-wsgcaatlas -gcut -clean-bm -subjid sub-047

# Check brainmasks

#parallel --progress --jobs 8 \
#    recon-all -autorecon2 -subjid {} \
#    ::: $controlslist

# Check WM masks

#parallel --progress --jobs 6 \
#    recon-all -autorecon3 -subjid {} \
#    ::: $controlslist

# Check surfaces

# parallel --progress --jobs 8 recon-all -s {} -qcache ::: $subjectslist

