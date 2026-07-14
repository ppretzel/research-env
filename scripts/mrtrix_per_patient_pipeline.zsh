#!/bin/bash

# To be run from the structuralConnectivity folder
# This script processes data from a new patient, after their data
# has been converted into BIDS format 
# Script to bidsify new data is in $bids_dir/code

# following the pipeline in
# https://mrtrix.readthedocs.io/en/dev/fixel_based_analysis/mt_fibre_density_cross-section.html

subject_id=$1

if [[ -z "$subject_id" ]]; then
    echo "Error: no subject_id supplied. Usage: $0 <subject_id>"
    exit 1
fi

sub=$subject_id
echo Running pipeline for $sub


# Set the env folders
bids_dir=/bids
templatedir=/research/structuralConnectivity/template
statsdir=/research/structuralConnectivity/statistics
mrtrixdir=/research/structuralConnectivity
freesurferdir=/research/advancedVolumetry
wdir=/research/structuralConnectivity/mrtrix_derived_subject_data/$sub

# Create target folder and check whether it's empty, 
# ask to overwrite if not empty
mkdir -p $wdir
if [ -n "$(ls -A "$wdir" 2>/dev/null)" ]; then
  echo "The folder is not empty. Do you want to continue? (y/N)"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Exiting script."
    exit 1
  fi
fi

############ Preprocessing #########################################

#mkdir -p $wdir/preprocessing
#mrconvert $bids_dir/$sub/dwi/${sub}_dwi.nii.gz \
#    -fslgrad $bids_dir/$sub/dwi/${sub}_dwi.bvec $bids_dir/$sub/dwi/${sub}_dwi.bval \
#    $wdir/preprocessing/dwi.mif
#
## TODO ggf anpassen falls 3.1 rauskommt
## (zB preprocessing, dwi2mask algorithm choice etc)
#
#dwidenoise \
#    $wdir/preprocessing/dwi.mif \
#    $wdir/preprocessing/dwi_denoised.mif \
#    -noise $wdir/preprocessing/noise.mif
#mrdegibbs \
#    $wdir/preprocessing/dwi_denoised.mif \
#    $wdir/preprocessing/dwi_denoised_unringed.mif \
#    -axes 0,1
##As per https://mrtrix.readthedocs.io/en/latest/dwi_preprocessing/dwifslpreproc.html#dwifslpreproc-page
##and https://community.mrtrix.org/t/dwifslpreproc-unequal-number-of-b0-images/6096
##extract the first b0 in AP phase encoding and concatenate with b0 in PA
##to use in the fslpreproc step
#mrconvert $wdir/preprocessing/dwi.mif \
#   -coord 3 0 -axes 0,1,2 \
#   $wdir/preprocessing/b0_AP.mif
#echo $( mrinfo -shell_bvalues $wdir/preprocessing/b0_AP.mif )
## check whether the extracted shell really is a b0 shell
#if [[ "$(mrinfo -shell_bvalues $wdir/preprocessing/b0_AP.mif | tr -d '[:space:]')" != "0" ]]; then
#    echo b0_AP.mif b-value is not 0! Aborting
#    exit
#fi
#mrconvert $bids_dir/$sub/dwi/${sub}_acq-PA_dwi.nii.gz \
#   -fslgrad \
#        $bids_dir/$sub/dwi/${sub}_acq-PA_dwi.bvec \
#        $bids_dir/$sub/dwi/${sub}_acq-PA_dwi.bval \
#        $wdir/preprocessing/b0_PA.mif
#mrcat \
#    $wdir/preprocessing/b0_AP.mif \
#    $wdir/preprocessing/b0_PA.mif \
#   -axis 3 \
#   $wdir/preprocessing/b0s.mif
#dwifslpreproc  \
#    $wdir/preprocessing/dwi_denoised_unringed.mif \
#    $wdir/preprocessing/dwi_denoised_unringed_preproc.mif \
#    -pe_dir AP \
#    -rpe_pair -se_epi $wdir/preprocessing/b0s.mif
#
# # As of today, bias correction is not necessary
# #dwibiascorrect ants $wdir/dwi_denoised_unringed_preproc.mif $wdir/dwi_denoised_unringed_preproc_unbiased.mif
#
## Upsampling, brain masks, spherical deconvolution, normalization
#
#mrgrid $wdir/preprocessing/dwi_denoised_unringed_preproc.mif \
#    regrid -vox 1.25 \
#    $wdir/preprocessing/dwi_denoised_unringed_preproc_upsampled.mif
#
##dwi2mask $wdir/dwi_denoised_unringed_preproc_upsampled.mif \
##    $wdir/dwi_mask_upsampled.mif
## in case dwi2mask does not create a fitting mask use bet (comes with FSL)
# might have to play around with the -f parameter:
# default .5, smaller values give larger brain estimates
# e.g. for sub-101 it works best with 0.4
#mrconvert $wdir/preprocessing/dwi_denoised_unringed_preproc_upsampled.mif \
#          $wdir/preprocessing/dwi_denoised_unringed_preproc_upsampled.nii.gz
#/opt/fsl/bin/bet \
#    $wdir/preprocessing/dwi_denoised_unringed_preproc_upsampled.nii.gz \
#    $wdir/preprocessing/brain_only.nii.gz -f 0.4
#mrconvert \
#    $wdir/preprocessing/brain_only.nii.gz \
#    $wdir/preprocessing/brain_only.mif
#mrcalc \
#    $wdir/preprocessing/brain_only.mif 0 -gt \
#    $wdir/preprocessing/dwi_mask_upsampled.mif
#
#dwi2fod msmt_csd \
#    $wdir/preprocessing/dwi_denoised_unringed_preproc_upsampled.mif \
#    $wdir/../controls_average_response_wm.txt $wdir/wmfod.mif \
#    $wdir/../controls_average_response_gm.txt $wdir/gm.mif \
#    $wdir/../controls_average_response_csf.txt $wdir/csf.mif
#mtnormalise \
#        $wdir/wmfod.mif $wdir/wmfod_norm.mif \
#        $wdir/gm.mif $wdir/gm_norm.mif \
#        $wdir/csf.mif $wdir/csf_norm.mif \
#        -mask $wdir/preprocessing/dwi_mask_upsampled.mif
#
## mrregister might lead to better results if the cerebellum is masked out
#if [ ! -f dwi_mask_nocerebellum.mif ]; then
#    echo ~~~~~ Consider creating a dwi mask without the cerebellum for better registration ~~~~
#    exit
#fi

## Register to all three compartment templates
#mrregister \
#    $wdir/wmfod_norm.mif $templatedir/wmfod_multi_template.mif \
#    $wdir/gm_norm.mif $templatedir/gm_multi_template.mif \
#    $wdir/csf_norm.mif $templatedir/csf_multi_template.mif \
#    -mask1 $wdir/preprocessing/dwi_mask_nocerebellum.mif \
#    -nl_warp $wdir/subject2template_warp.mif $wdir/template2subject_warp.mif \
#    -transformed $wdir/wmfod_norm_in_template_space.mif \
#    -transformed $wdir/gm_in_template_space.mif \
#    -transformed $wdir/csf_in_template_space.mif
#exit

# Also register using the original DWI mask
# While this increases accuracy around the brainstem and cerebral peduncles, 
# accuracy decreases supratentorially, which is precisely what we want to look at 
# in the study - therefore, keep the registration with the cerebellum masked out
#mrregister \
#    $wdir/wmfod_norm.mif $templatedir/wmfod_multi_template.mif \
#    $wdir/gm_norm.mif $templatedir/gm_multi_template.mif \
#    $wdir/csf_norm.mif $templatedir/csf_multi_template.mif \
#    -mask1 $wdir/preprocessing/dwi_mask_upsampled.mif \
#    -nl_warp $wdir/subject2template_warp_withcerebellum.mif $wdir/template2subject_warp_withcerebellum.mif
#    #-transformed $wdir/wmfod_norm_in_template_space.mif \
#    #-transformed $wdir/gm_in_template_space.mif \
#    #-transformed $wdir/csf_in_template_space.mif


## Warp FOD into template space, compute fixel and FD
#mrtransform $wdir/wmfod_norm.mif \
#    -warp $wdir/subject2template_warp.mif \
#    -reorient_fod no \
#    $wdir/fod_in_template_space_NOT_REORIENTED.mif
#fod2fixel -mask $templatedir/template_mask.mif \
#    $wdir/fod_in_template_space_NOT_REORIENTED.mif \
#    $wdir/fixel_in_template_space_NOT_REORIENTED \
#    -afd fd.mif
#fixelreorient $wdir/fixel_in_template_space_NOT_REORIENTED \
#    $wdir/subject2template_warp.mif \
#    $wdir/fixel_in_template_space
#rm -r $wdir/fixel_in_template_space_NOT_REORIENTED \
#      $wdir/fod_in_template_space_NOT_REORIENTED.mif
#
## Move FD into templace space, compute FC and FDC
#fixelcorrespondence $wdir/fixel_in_template_space/fd.mif \
#    $templatedir/fixel_mask \
#    $templatedir/fd $sub.mif
#warp2metric $wdir/subject2template_warp.mif \
#    -fc $templatedir/fixel_mask \
#    $templatedir/fc $sub.mif
#mrcalc $templatedir/fc/$sub.mif \
#    -log $templatedir/log_fc/$sub.mif
#mrcalc $templatedir/fd/$sub.mif \
#    $templatedir/fc/$sub.mif \
#    -mult \
#    $templatedir/fdc/$sub.mif
#
## Smoothe based on template fixel connectivity matrix
#fixelfilter $templatedir/fd/$sub.mif \
#    smooth -matrix $templatedir/matrix/ \
#    $templatedir/fd_smooth/$sub.mif
#fixelfilter $templatedir/log_fc/$sub.mif \
#    smooth -matrix $templatedir/matrix/ \
#    $templatedir/log_fc_smooth/$sub.mif
#fixelfilter $templatedir/fdc/$sub.mif \
#    smooth -matrix $templatedir/matrix/ \
#    $templatedir/fdc_smooth/$sub.mif
#
#exit

###################################################################
# Individual analysis - zscores against controls distribution

#individualAnalysisFolder=$statsdir/individualAnalysis
#mrcalc $templatedir/fd_smooth/$sub.mif \
#    $individualAnalysisFolder/fd_smooth_controls_mean.mif -subtract \
#    $individualAnalysisFolder/fd_smooth_controls_std.mif -divide \
#    $individualAnalysisFolder/${sub}_fd_zscore.mif
#mrcalc $templatedir/log_fc_smooth/$sub.mif \
#    $individualAnalysisFolder/log_fc_smooth_controls_mean.mif -subtract \
#    $individualAnalysisFolder/log_fc_smooth_controls_std.mif -divide \
#    $individualAnalysisFolder/${sub}_log_fc_zscore.mif
#mrcalc $templatedir/fdc_smooth/$sub.mif \
#    $individualAnalysisFolder/fdc_smooth_controls_mean.mif -subtract \
#    $individualAnalysisFolder/fdc_smooth_controls_std.mif -divide \
#    $individualAnalysisFolder/${sub}_fdc_zscore.mif

## Best to show it on the template background,
#  then threshold (by the same metric!), i.e. -2 on the right input field,
#  and then set the color scale from -2 to -6 or something like that
#exit


###################################################################
#### ACT Anatomically Constrained Tracography

# Extract brain from T1, extract bzero shells from DWI

#    mkdir -p $wdir/t1_registration
#    /opt/fsl/bin/bet \
#        $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#        $wdir/t1_registration/T1_bet.nii.gz
#    # Alternatively, if bet doesnt succeed,
#    # simply use the DWI mask on the native T1 image:
#    #mrgrid $wdir/preprocessing/dwi_mask_upsampled.mif \
#    #    regrid -template $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#    #    - | \
#    #mrcalc $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#    #    - \
#    #    -mult \
#    #    $wdir/t1_registration/T1_bet.nii.gz
#    dwiextract -bzero \
#        $wdir/preprocessing/dwi_denoised_unringed_preproc.mif \
#        $wdir/t1_registration/dwi_zero.mif
#    mrmath  \
#        $wdir/t1_registration/dwi_zero.mif \
#        mean -axis 3 \
#        $wdir/t1_registration/dwi_zero_mean.mif
#    mrconvert $wdir/t1_registration/dwi_zero_mean.mif \
#              $wdir/t1_registration/dwi_zero_mean.nii.gz

## Register T1 into DWI using FSL epi_reg
#  epi_reg does not work within the mrtrix docker image 
#  instead, run this step locally
#    /opt/fsl/bin/epi_reg \
#        --epi=$wdir/t1_registration/dwi_zero_mean.nii.gz \
#        --t1=$bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#        --t1brain=$wdir/t1_registration/T1_bet.nii.gz \
#        --out=$wdir/t1_registration/dwi2t1

# Transform T1 and Freesurfer segmentation into DWI space,
# Convert Freesurfer parcellation into 5TT file format for ACT
#transformconvert $wdir/t1_registration/dwi2t1.mat \
#                 $wdir/t1_registration/dwi_zero_mean.nii.gz \
#                 $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#                 flirt_import \
#                 $wdir/t1_registration/dwi2t1_warp.txt
#mrtransform $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#            -linear $wdir/t1_registration/dwi2t1_warp.txt \
#            -inverse \
#            $wdir/t1_registration/T1_in_dwi_space.mif
#mrtransform $freesurferdir/freesurfer_derived_subject_data/$sub/mri/aparc.DKTatlas+aseg.mgz \
#            -linear $wdir/t1_registration/dwi2t1_warp.txt \
#            -inverse \
#            $wdir/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz
# Check resulting registraton fit with aparc/aseg as an overlay to gm_norm.mif


###################################################################
#    Warp T1 into template space for easier visualization
#mrtransform $wdir/t1_registration/T1_in_dwi_space.mif \
#            -warp $wdir/subject2template_warp.mif \
#            $wdir/t1_registration/T1_in_template_space.mif
            

###########################################################################
#############   ACT

mkdir -p $wdir/ACT
echo "Performing ACT"

function addBrainstem {

    subfolder=$1
    height=$2
    midline=$3

    mkdir -p $subfolder/ACT

   # Prepare 5TT file with the brainstem as additional region
   # so that ACT can let tracks end there
   5ttgen      freesurfer \
               $subfolder/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz \
               $subfolder/ACT/5tt-DKT.mif \
               -scratch $wdir/ \
               -lut $freesurferdir/FreeSurferColorLUT.txt 
   # Add the brainstem (region 16, but only the bottom few slices,
   # and add to cortical grey matter in the 5tt file so tracking can begin/end there
   mrcalc $subfolder/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz 16 -eq - | \
       mrgrid - crop -axis 2 0:$height  - | \
       mrgrid - regrid -template $subfolder/ACT/5tt-DKT.mif - | \
       5ttedit $subfolder/ACT/5tt-DKT.mif -cgm - $subfolder/ACT/5tt-DKT-brainstem.mif

   # Edit the original freesurfer DKT parcellation to add separate brainstem LH and RH regions
   # so that later tracts can be separated correctly
   # Therefore, again take the bottom slices of the brainstem (region 16),
   # but this time regrid to the aparc.DTKatlas+aseg_in_dwi_space 
   # and separate into left and right brainstem masks
   # cropping from 0 up (0:125) can easily be padded,
   # but padding after cropping from further up (e.g. 125:200) is not,
   # so calculate the LH mask first and then just subtract from brainstem_total for RH
   mrcalc $subfolder/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz 16 -eq - | \
       mrgrid - crop -axis 2 0:$height - | \
       mrgrid - pad -as $subfolder/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz -all_axes \
              $subfolder/ACT/brainstem_total.mif
   mrgrid $subfolder/ACT/brainstem_total.mif crop -axis 0 0:$midline - | \
       mrgrid - pad -as $subfolder/ACT/brainstem_total.mif -all_axes $subfolder/ACT/brainstem_mask_lh.mif 
   mrcalc $subfolder/ACT/brainstem_total.mif $subfolder/ACT/brainstem_mask_lh.mif -sub $subfolder/ACT/brainstem_mask_rh.mif
   
   # Set the LH and RH brainstem regions to 15000 and 15001 
   # the numbers have to match the manually added entries in the LUT file
   mrcalc $subfolder/ACT/brainstem_mask_rh.mif \
          15000 $subfolder/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz \
          -if - | \
   mrcalc $subfolder/ACT/brainstem_mask_lh.mif \
          15001 - \
          -if \
          $subfolder/ACT/aparc.DKTatlas+brainstem.mif

}

# Add brainstem masks to the DKT atlas for connectome creation
# syntax: addBrainstem $wdir <height> <midline>
# Set height so that the upper end of the mask sits below the cerebellum,
# so that streamlines are separated between cerebellar peduncles and brainstem
#
# Dont remove these function calls to keep the parameters for documentation
#addBrainstem $wdir 97 70 #sub-101
#addBrainstem $wdir 132 88 #sub-103
#addBrainstem $wdir 112 84 #sub-106

exit


## Perform ACT
tckgen \
    -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 \
    $wdir/wmfod_norm.mif \
    -seed_gmwmi $wdir/preprocessing/dwi_mask_upsampled.mif \
    -act $wdir/ACT/5tt-DKT-brainstem.mif \
    -mask $wdir/preprocessing/dwi_mask_upsampled.mif \
    -select 2000000 -cutoff 0.10 \
    $wdir/ACT/tracks_2m_ACT.tck
tcksift2 \
    $wdir/ACT/tracks_2m_ACT.tck \
    $wdir/wmfod_norm.mif \
    $wdir/ACT/tracks_2m_tcksift2_weights.txt \
    -act $wdir/ACT/5tt-DKT-brainstem.mif \
    -out_mu $wdir/ACT/tracks_2m_tcksift2_mu.txt

exit

# Connectome 
labelconvert \
    $wdir/ACT/aparc.DKTatlas+brainstem.mif \
    $freesurferdir/FreeSurferColorLUT.txt \
    $mrtrixdir/fs_default_adapted.txt \
    $wdir/ACT/nodes.mif
# IMPORTANT! If this step fails, check that in FreeSurferColorLUT the asterisks have been removed from Thalamus_proper!!

tck2connectome \
    $wdir/ACT/tracks_2m_ACT.tck \
    -tck_weights_in $wdir/ACT/tracks_2m_tcksift2_weights.txt \
    $wdir/ACT/nodes.mif \
    $wdir/ACT/connectome.csv \
    -out_assignments $wdir/ACT/streamline_assignments

mkdir -p $wdir/ACT/streamlines/raw
connectome2tck \
    $wdir/ACT/tracks_2m_ACT.tck \
    $wdir/ACT/streamline_assignments \
    $wdir/ACT/streamlines/raw/edge- \
    -tck_weights_in $wdir/ACT/tracks_2m_tcksift2_weights.txt \
    -prefix_tck_weights_out $wdir/ACT/streamlines/raw/weights- 

############## Extract the relevant tracks
#  TODO might think about streamlining this later; the entirety of all tracks takes several GB
brainstem_l=87
brainstem_r=86
cerebellum_l=35
cerebellum_r=84
thalamus_l=36
thalamus_r=43
precentral_l=23
precentral_r=72
postcentral_l=21
postcentral_r=70

linkTract () {

    start=$1
    end=$2
    tractname=$3

    ln $wdir/ACT/streamlines/raw/edge-${start}-${end}.tck $wdir/ACT/streamlines/$tractname.tck -rs
    ln $wdir/ACT/streamlines/raw/weights-${start}-${end}.csv $wdir/ACT/streamlines/$tractname-weights.csv -rs

}

linkTract $brainstem_l $precentral_l CST_L 
linkTract $brainstem_r $precentral_r CST_R
linkTract $brainstem_l $cerebellum_l inferior_cerebellar_l
linkTract $brainstem_r $cerebellum_r inferior_cerebellar_r
linkTract $thalamus_l $cerebellum_r thalamus_l_cerebellum_r
linkTract $thalamus_r $cerebellum_l thalamus_r_cerebellum_l
linkTract $thalamus_r $precentral_r thalamus_r_radiation
linkTract $thalamus_l $precentral_l thalamus_l_radiation
linkTract $cerebellum_l $cerebellum_r pons sub-001


exit

####################################################################3
#  Archive of old stuff, not used any more



# Extra: Whole-brain tractography in both subject and template space
#tckgen \
#    -angle 22.5 \
#    -maxlen 250 -minlen 10 \
#    -power 1.0 \
#    wmfod_norm.mif \
#    -seed_image dwi_mask_upsampled.mif \
#    -mask dwi_mask_upsampled.mif \
#    -select 2000000 \
#    -cutoff 0.06 \
#    tracks_2_million_subject_space.tck
#tcksift tracks_2_million_subject_space.tck \
#    wmfod_norm.mif \
#    -term_number 200000 \
#    tracks_200k_subject_space.tck

#mrtransform dwi_mask_upsampled.mif \
#    -warp subject2template_warp.mif \
#    dwi_mask_upsampled_in_template_space.mif
#tckgen \
#    -angle 22.5 \
#    -maxlen 250 -minlen 10 \
#    -power 1.0 \
#    wmfod_norm_in_template_space.mif \
#    -seed_image dwi_mask_upsampled_in_template_space.mif \
#    -mask dwi_mask_upsampled_in_template_space.mif \
#    -select 2000000 \
#    -cutoff 0.06 \
#    tracks_2_million_template_space.tck
#tcksift tracks_2_million_template_space.tck \
#    wmfod_norm_in_template_space.mif \
#    -term_number 200000 \
#    tracks_200k_template_space.tck


## Use FSL to skullstrip T1 and register into DWI space
#mrconvert t1.mif t1.nii.gz
#mrconvert dwi_denoised_unringed_preproc_unbiased_upsampled.mif dwi_preprocessed_upsampled.nii.gz
#/opt/fsl/bin/bet t1.nii.gz t1_brainonly.nii.gz
#/opt/fsl/bin/epi_reg --epi=dwi_preprocessed_upsampled.nii.gz \
#    --t1=t1.nii.gz \
#    --t1brain=t1_brainonly.nii.gz \
#    --out=dwi2t1
#
#transformconvert dwi2t1.mat \
#    dwi_preprocessed_upsampled.nii.gz \
#    t1.nii.gz \
#    flirt_import dwi2t1_warp.txt
#
#mrtransform t1.mif \
#    -linear dwi2t1_warp.txt \
#    -inverse \
#    t1_in_dwi_space.mif
#mrtransform t1_brainonly.nii.gz \
#    -linear dwi2t1_warp.txt \
#    -inverse \
#    t1_brainonly_in_dwi_space.mif
#
#rm t1.nii.gz dwi_preprocessed_upsampled.nii.gz dwi2t1.nii.gz


###### Tractseg tract extraction both in subject and template space
# Left this out for now, don't think tractseg is appropriate in 
# pathologically altered brains...

# pip install dipy pandas torch TractSeg

## Subject space:
#wdir=tractseg/subjectspace
#mkdir -p $wdir
#
#sh2peaks wmfod_norm.mif \
#    $wdir/peaks.nii.gz
#
#TractSeg -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output \
#         --output_type tract_segmentation
#TractSeg -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output/ \
#         --output_type endings_segmentation
#TractSeg -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output/ \
#         --output_type TOM
#Tracking -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output 

## Template space:
#wdir=tractseg/templatespace
#mkdir -p $wdir
#
#sh2peaks wmfod_norm_in_template_space.mif \
#         $wdir/peaks.nii.gz
#
#TractSeg -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output \
#         --output_type tract_segmentation
#TractSeg -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output/ \
#         --output_type endings_segmentation
#TractSeg -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output/ \
#         --output_type TOM
#Tracking -i $wdir/peaks.nii.gz \
#         -o $wdir/tractseg_output 
