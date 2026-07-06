#!/bin/zsh

source /home/pablo/libraries/miniconda3/etc/profile.d/conda.sh
conda activate pch2a

bids_dir=/mnt/arbeit-ssd/original_scans/PCH2A/BIDS
templatedir=$PWD/template
freesurferdir=/mnt/arbeit-ssd/research/PCH2A/advancedVolumetry
subsdir=$PWD/mrtrix_derived_subject_data
statsdir=$PWD/statistics/
mkdir -p $subsdir

# General pipeline for controls 
# To be run from the PCH2A/structuralConnectivity folder
#
# Steps:
# - TODO check whether all steps are still necessary
# - Standard FBA pipeline, as far as applicable for only controls
# - Tractseg over template data as well as for each subject (latter still necessary?)
# - Register a subjects T1 into template space
#   and run the freesurfer pipeline to obtain a segmentation + parcellation
#   for nice glassbrain visualizations
#

## 01-03 Preprocessing
#for folder in $(ls $bids_dir/sub-0* -d)
#do
#    sub=$(basename $folder)
#    sub_out=$subsdir/$sub/preprocessing
#    mkdir $sub_out -p
#    echo Preprocessing sub $sub in folder $folder
#    mrconvert $folder/dwi/${sub}_dwi.nii.gz \
#        -fslgrad $folder/dwi/${sub}_dwi.bvec $folder/dwi/${sub}_dwi.bval \
#        $sub_out/dwi.mif
#    dwidenoise $sub_out/dwi.mif \
#        $sub_out/dwi_denoised.mif \
#        -noise $sub_out/noise.mif
#    mrdegibbs $sub_out/dwi_denoised.mif \
#        $sub_out/dwi_denoised_unringed.mif \
#        -axes 0,1
#    #As per https://mrtrix.readthedocs.io/en/latest/dwi_preprocessing/dwifslpreproc.html#dwifslpreproc-page
#    #and https://community.mrtrix.org/t/dwifslpreproc-unequal-number-of-b0-images/6096
#    #extract the first b0 in AP phase encoding and concatenate with b0 in PA
#    #to use in the fslpreproc step
#    mrconvert $sub_out/dwi.mif \
#       -coord 3 0 -axes 0,1,2 \
#       $sub_out/b0_AP.mif
#    mrconvert $folder/dwi/${sub}_acq-PA_dwi.nii.gz \
#       -fslgrad $folder/dwi/${sub}_acq-PA_dwi.bvec $folder/dwi/${sub}_acq-PA_dwi.bval \
#       $sub_out/b0_PA.mif
#    mrcat $sub_out/b0_AP.mif $sub_out/b0_PA.mif \
#       -axis 3 \
#       $sub_out/b0s.mif
#    dwifslpreproc $sub_out/dwi_denoised_unringed.mif \
#        $sub_out/dwi_denoised_unringed_preproc.mif \
#        -pe_dir AP \
#        -rpe_pair -se_epi $sub_out/b0s.mif
#        
#    #not necessary as of the current pipeline documentation
#    #dwibiascorrect ants $folder/dwi_denoised_unringed_preproc.mif \
#    #   $folder/dwi_denoised_unringed_preproc_unbiased.mif
#done
#
### 04 tissue response functions
#for folder in $(ls $subsdir/sub-0* -d)
#do
#    sub=$(basename $folder)
#    dwi2response dhollander $folder/preprocessing/dwi_denoised_unringed_preproc.mif \
#        $folder/response_wm.txt \
#        $folder/response_gm.txt \
#        $folder/response_csf.txt
#done

#responsemean $subsdir/sub-0*/response_wm.txt $subsdir/controls_average_response_wm.txt 
#responsemean $subsdir/sub-0*/response_gm.txt $subsdir/controls_average_response_gm.txt 
#responsemean $subsdir/sub-0*/response_csf.txt $subsdir/controls_average_response_csf.txt 

## 05-08 Upsampling, brain masks, spherical deconvolution, normalization
#for folder in $(ls $subsdir/sub-0* -d)
#do
#    mrgrid $folder/preprocessing/dwi_denoised_unringed_preproc.mif \
#        regrid -vox 1.25 \
#        $folder/preprocessing/dwi_denoised_unringed_preproc_upsampled.mif
#    dwi2mask $folder/preprocessing/dwi_denoised_unringed_preproc_upsampled.mif \
#        $folder/preprocessing/dwi_mask_upsampled.mif
#    dwi2fod msmt_csd \
#        $folder/preprocessing/dwi_denoised_unringed_preproc_upsampled.mif \
#        $subsdir/controls_average_response_wm.txt $folder/wmfod.mif \
#        $subsdir/controls_average_response_gm.txt $folder/gm.mif \
#        $subsdir/controls_average_response_csf.txt $folder/csf.mif
#    mtnormalise \
#        $folder/wmfod.mif $folder/wmfod_norm.mif \
#        $folder/gm.mif $folder/gm_norm.mif \
#        $folder/csf.mif $folder/csf_norm.mif \
#        -mask $folder/preprocessing/dwi_mask_upsampled.mif
#done

## 09 Template (Multi-template, as per Pietsch 2019,
## leads to better alignment)
# This is best done on AWS, needs slightly different data preparation,
# changed the script on the fly and didnt save it
#mkdir -p $templatedir/wmfod_input $templatedir/gm_input $templatedir/csf_input $templatedir/mask_input
#for folder in $(ls subsdir/sub-0* -d); do
#    subjectname=$(basename $folder)
#    ln -sr $folder/wmfod_norm.mif $templatedir/wmfod_input/${subjectname}.mif
#    ln -sr $folder/gm_norm.mif $templatedir/gm_input/${subjectname}.mif
#    ln -sr $folder/csf_norm.mif $templatedir/csf_input/${subjectname}.mif
#    ln -sr $folder/preprocessing/dwi_mask_upsampled.mif $templatedir/mask_input/${subjectname}.mif
#done
#population_template \
#    $templatedir/wmfod_input $templatedir/wmfod_multi_template.mif \
#    $templatedir/gm_input $templatedir/gm_multi_template.mif \
#    $templatedir/csf_input $templatedir/csf_multi_template.mif \
#    -mask_dir $templatedir/mask_input \
#    -voxel_size 1.25
#
## 10 Register into template space
# also best done on AWS
#for folder in $(ls $subsdir/sub-0* -d); do
#    mrregister $folder/wmfod_norm.mif $templaredir/wmfod_multi_template.mif \
#    -mask1 $folder/preprocessing/dwi_mask_upsampled.mif \
#    -nl_warp \ $folder/subject2template_warp.mif $folder/template2subject_warp.mif
#done
#
## 11. Template mask
#for folder in $(ls $subsdir/sub-0* -d); do
#    mrtransform $folder/preprocessing/dwi_mask_upsampled.mif \
#        -warp $folder/subject2template_warp.mif \
#        -interp nearest -datatype bit \
#        $folder/dwi_mask_in_template_space.mif
#done
#mrmath $subsdir/sub-0*/dwi_mask_in_template_space.mif min \
#    $templatedir/template_mask.mif -datatype bit

## 12. White matter fixel analysis mask
#fod2fixel \
#    -mask $templatedir/template_mask.mif \
#    -fmls_peak_value 0.06 \
#    $templatedir/wmfod_multi_template.mif \
#    $templatedir/fixel_mask

## 13./14./15./16. Warp subject FODs into template space, calculate fixels and FD, reorient,
## establish subject-template fixel correspondence
#for folder in $(ls $subsdir/sub-0* -d); do
#    mrtransform $folder/wmfod_norm.mif \
#        -warp $folder/subject2template_warp.mif \
#        -reorient_fod no \
#        $folder/fod_in_template_space_NOT_REORIENTED.mif
#    fod2fixel -mask $templatedir/template_mask.mif \
#        $folder/fod_in_template_space_NOT_REORIENTED.mif \
#        $folder/fixel_in_template_space_NOT_REORIENTED \
#        -afd fd.mif
#    fixelreorient $folder/fixel_in_template_space_NOT_REORIENTED \
#        $folder/subject2template_warp.mif $folder/fixel_in_template_space
#    rm -r $folder/fixel_in_template_space_NOT_REORIENTED \
#        $folder/fod_in_template_space_NOT_REORIENTED.mif
#    fixelcorrespondence $folder/fixel_in_template_space/fd.mif \
#        $templatedir/fixel_mask $templatedir/fd $folder:t.mif
#done
#
## 17. Compute FC
#for folder in $(ls $subsdir/sub-0* -d); do
#    warp2metric \
#        $folder/subject2template_warp.mif \
#        -fc $templatedir/fixel_mask $templatedir/fc \
#        $folder:t.mif
#done
#mkdir $templatedir/log_fc
#cp $templatedir/fc/index.mif $templatedir/fc/directions.mif $templatedir/log_fc
#for folder in $(ls $subsdir/sub-0* -d); do
#    mrcalc $templatedir/fc/$folder:t.mif -log $templatedir/log_fc/$folder:t.mif
#done
#
## 18. Compute FDC
#mkdir $templatedir/fdc
#cp $templatedir/fc/index.mif $templatedir/fc/directions.mif $templatedir/fdc
#for folder in $(ls $subsdir/sub-0* -d); do
#    mrcalc $templatedir/fd/$folder:t.mif $templatedir/fc/$folder:t.mif \
#        -mult $templatedir/fdc/$folder:t.mif
#done
#
#
## 20./21. Perform template tractography & SIFT 
## temporarily create smaller datasets first for inspection
#tckgen \
#    -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 \
#    template/wmfod_multi_template.mif \
#    -seed_image template/template_mask.mif \
#    -mask template/template_mask.mif \
#    -select 20000000 -cutoff 0.10 \
#    template/tracks_20_million.tck
#tcksift \
#    template/tracks_20_million.tck \
#    template/wmfod_multi_template.mif \
#    template/tracks_2_million_sift.tck \
#    -term_number 2000000
#
## 22./23. Fixel connectivity matrix, smooth fixel data
#fixelconnectivity \
#    $templatedir/fixel_mask/ \
#    $templatedir/tracks_2_million_sift.tck \
#    $templatedir/matrix/
#fixelfilter \
#    $templatedir/fd smooth \
#    $templatedir/fd_smooth \
#    -matrix $templatedir/matrix/
#fixelfilter \
#    $templatedir/log_fc smooth \
#    $templatedir/log_fc_smooth \
#    -matrix $templatedir/matrix/
#fixelfilter \
#    $templatedir/fdc smooth \
#    $templatedir/fdc_smooth \
#    -matrix $templatedir/matrix/

###################################################################
#### ACT Anatomically Constrained Tracography

# Preparations: extract brain from T1, extract bzero shells from DWI
for folder in $subsdir/sub-0*; do
    sub=$(basename $folder )

    mkdir -p $folder/t1_registration
#    bet \
#        $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#        $folder/t1_registration/T1_bet.nii.gz
#    dwiextract -bzero \
#        $folder/preprocessing/dwi_denoised_unringed_preproc.mif \
#        $folder/t1_registration/dwi_zero.mif
#    mrmath  \
#        $folder/t1_registration/dwi_zero.mif \
#        mean -axis 3 \
#        $folder/t1_registration/dwi_zero_mean.mif
#    mrconvert $folder/t1_registration/dwi_zero_mean.mif \
#              $folder/t1_registration/dwi_zero_mean.nii.gz
done

## Register T1 into DWI using FSL epi_reg
#list=$(ls $subsdir/sub-0* -d)
#echo $list | parallel \
#    epi_reg \
#        --epi={}/t1_registration/dwi_zero_mean.nii.gz \
#        --t1=$bids_dir/{/}/anat/{/}_acq-isoSag1mm_T1w.nii.gz \
#        --t1brain={}/t1_registration/T1_bet.nii.gz \
#        --out={}/t1_registration/dwi2t1

# Transform T1 and Freesurfer segmentation into DWI space,
for folder in $subsdir/sub-0*; do
    sub=$(basename $folder )

#    transformconvert $folder/t1_registration/dwi2t1.mat \
#                     $folder/t1_registration/dwi_zero_mean.nii.gz \
#                     $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#                     flirt_import \
#                     $folder/t1_registration/dwi2t1_warp.txt
#    mrtransform $bids_dir/$sub/anat/${sub}_acq-isoSag1mm_T1w.nii.gz \
#                -linear $folder/t1_registration/dwi2t1_warp.txt \
#                -inverse \
#                $folder/t1_registration/T1_in_dwi_space.mif
#    mrtransform $freesurferdir/freesurfer_derived_subject_data/$sub/mri/uparc.DKTatlas+aseg.mgz \
#                -linear $folder/t1_registration/dwi2t1_warp.txt \
#                -inverse \
#                $folder/t1_registration/aparc.DKTatlas+aseg_in_dwi_space.mgz
done

############## ACT

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


# Set values and compute masks individually for each subject
# function call is addBrainstem $folder $height $midline
# increase $height: brainstem mask will extend more cranially
# increase $midline: midline will move to the right
#addBrainstem mrtrix_derived_subject_data/sub-001/ 120 125
#addBrainstem mrtrix_derived_subject_data/sub-002/ 125 127
#addBrainstem mrtrix_derived_subject_data/sub-003/ 110 123
#addBrainstem mrtrix_derived_subject_data/sub-004/ 108 123
#addBrainstem mrtrix_derived_subject_data/sub-005/ 110 126
#addBrainstem mrtrix_derived_subject_data/sub-006/ 112 122
#addBrainstem mrtrix_derived_subject_data/sub-007/ 115 125
#addBrainstem mrtrix_derived_subject_data/sub-009/ 110 130
#addBrainstem mrtrix_derived_subject_data/sub-015/ 116 123
#addBrainstem mrtrix_derived_subject_data/sub-016/ 113 125
#addBrainstem mrtrix_derived_subject_data/sub-017/ 124 122
#addBrainstem mrtrix_derived_subject_data/sub-018/ 116 127
#addBrainstem mrtrix_derived_subject_data/sub-020/ 120 127
#addBrainstem mrtrix_derived_subject_data/sub-022/ 125 125
#addBrainstem mrtrix_derived_subject_data/sub-023/ 112 127
#addBrainstem mrtrix_derived_subject_data/sub-024/ 110 125
#addBrainstem mrtrix_derived_subject_data/sub-025/ 125 126
#addBrainstem mrtrix_derived_subject_data/sub-026/ 115 125
#addBrainstem mrtrix_derived_subject_data/sub-027/ 115 125
#addBrainstem mrtrix_derived_subject_data/sub-029/ 115 126
#addBrainstem mrtrix_derived_subject_data/sub-030/ 110 126
#addBrainstem mrtrix_derived_subject_data/sub-031/ 100 128
#addBrainstem mrtrix_derived_subject_data/sub-032/ 118 122
#addBrainstem mrtrix_derived_subject_data/sub-034/ 120 127
#addBrainstem mrtrix_derived_subject_data/sub-035/ 100 130
#addBrainstem mrtrix_derived_subject_data/sub-036/ 110 125
#addBrainstem mrtrix_derived_subject_data/sub-037/ 110 126
#addBrainstem mrtrix_derived_subject_data/sub-038/ 115 125
#addBrainstem mrtrix_derived_subject_data/sub-042/ 95 126
#addBrainstem mrtrix_derived_subject_data/sub-045/ 110 123
#addBrainstem mrtrix_derived_subject_data/sub-046/ 110 125
#addBrainstem mrtrix_derived_subject_data/sub-047/ 110 125
#addBrainstem mrtrix_derived_subject_data/sub-048/ 110 127
#addBrainstem mrtrix_derived_subject_data/sub-049/ 115 126
#addBrainstem mrtrix_derived_subject_data/sub-050/ 115 128
#addBrainstem mrtrix_derived_subject_data/sub-052/ 106 128
#addBrainstem mrtrix_derived_subject_data/sub-053/ 110 127
#addBrainstem mrtrix_derived_subject_data/sub-054/ 110 124

## Better pause and check whether all brainstems have been separated correctly 
#  i.e. both the ACT/5tt-DKT-brainste.mif for the correct height
#  as well as the ACT/brainstem_mask_lh and rh.mif for the correct midline separation
for folder in $subsdir/sub-0*; do

#    mrview $folder/ACT/5tt-DKT-brainstem.mif \
#        -roi.load $folder/ACT/brainstem_mask_lh.mif \
#        -roi.load $folder/ACT/brainstem_mask_rh.mif

done

## Generate tracks based on the 5tt information          
for folder in $subsdir/sub-0*; do
    sub=$(basename $folder )

#   tckgen \
#       -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 \
#       $folder/wmfod_norm.mif \
#       -seed_gmwmi $folder/preprocessing/dwi_mask_upsampled.mif \
#       -act $folder/ACT/5tt-DKT-brainstem.mif \
#       -mask $folder/preprocessing/dwi_mask_upsampled.mif \
#       -select 100000 -cutoff 0.10 \
#       $folder/ACT/tracks_2m_ACT.tck
#   tcksift2 \
#       $folder/ACT/tracks_2m_ACT.tck \
#       $folder/wmfod_norm.mif \
#       $folder/ACT/tracks_2m_tcksift2_weights.txt \
#       -act $folder/ACT/5tt-DKT-brainstem.mif \
#       -out_mu $folder/ACT/tracks_2m_tcksift2_mu.txt

done

# Connectome 
for folder in $subsdir/sub-0*; do
    sub=$(basename $folder )


#    # The LUT is taken from
#    # https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT
#    # IMPORTANT! Remove asterisks from Thalamus_proper
#    # And add regions 15000 brainstem_rh and 15001 brainstem_lh!
#
#    labelconvert \
#        $folder/ACT/aparc.DKTatlas+brainstem.mif \
#        $freesurferdir/FreeSurferColorLUT.txt \
#        fs_default_adapted.txt \
#        $folder/ACT/nodes.mif
##    # IMPORTANT! If this step fails, check that in FreeSurferColorLUT the asterisks have been removed from Thalamus_proper!!
##
#    tck2connectome \
#        $folder/ACT/tracks_2m_ACT.tck \
#        -tck_weights_in $folder/ACT/tracks_2m_tcksift2_weights.txt \
#        $folder/ACT/nodes.mif \
#        $folder/ACT/connectome.csv \
#        -out_assignments $folder/ACT/streamline_assignments
#
#    mkdir -p $folder/ACT/streamlines/raw
#    connectome2tck \
#        $folder/ACT/tracks_2m_ACT.tck \
#        $folder/ACT/streamline_assignments \
#        $folder/ACT/streamlines/raw/edge- \
#        -tck_weights_in $folder/ACT/tracks_2m_tcksift2_weights.txt \
#        -prefix_tck_weights_out $folder/ACT/streamlines/raw/weights-

done


## Extract the relevant tracks
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

    for folder in $subsdir/sub-0*; do

        ln $folder/ACT/streamlines/raw/edge-${start}-${end}.tck $folder/ACT/streamlines/$tractname.tck -rs
        ln $folder/ACT/streamlines/raw/weights-${start}-${end}.csv $folder/ACT/streamlines/$tractname-weights.csv -rs

    done

}

#linkTract $brainstem_l $precentral_l CST_L 
#linkTract $brainstem_r $precentral_r CST_R
#linkTract $brainstem_l $cerebellum_l inferior_cerebellar_l
#linkTract $brainstem_r $cerebellum_r inferior_cerebellar_r
#linkTract $thalamus_l $cerebellum_r thalamus_l_cerebellum_r
#linkTract $thalamus_r $cerebellum_l thalamus_r_cerebellum_l
#linkTract $thalamus_r $precentral_r thalamus_r_radiation
#linkTract $thalamus_l $precentral_l thalamus_l_radiation
#linkTract $cerebellum_l $cerebellum_r pons sub-001


##############################################################
##### Prepare files for individual analysis 
#     of zscores, based on the Mito 2024 paper

individualAnalysisFolder=$statsdir/individualAnalysis
#mkdir -p $individualAnalysisFolder
#
#Need to copy the directions and index base file first
#cp $templatedir/fd_smooth/directions.mif \
#    $templatedir/fd_smooth/index.mif \
#    $individualAnalysisFolder/
##
#mrmath $templatedir/fd_smooth/sub-0*.mif \
#    mean $individualAnalysisFolder/fd_smooth_controls_mean.mif
#mrmath $templatedir/fd_smooth/sub-0*.mif \
#    std $individualAnalysisFolder/fd_smooth_controls_std.mif
#mrmath $templatedir/log_fc_smooth/sub-0*.mif \
#    mean $individualAnalysisFolder/log_fc_smooth_controls_mean.mif
#mrmath $templatedir/log_fc_smooth/sub-0*.mif \
#    std $individualAnalysisFolder/log_fc_smooth_controls_std.mif
#mrmath $templatedir/fdc_smooth/sub-0*.mif \
#    mean $individualAnalysisFolder/fdc_smooth_controls_mean.mif
#mrmath $templatedir/fdc_smooth/sub-0*.mif \
#    std $individualAnalysisFolder/fdc_smooth_controls_std.mif

exit




#################################
#  Old stuff, kept for reference, probably not necessary any more
#################################
exit

####### Perform tractseg for each control subject

# pip install dipy pandas torch TractSeg
#mkdir -p tractseg/subjects
#for folder in subjects/*; do
#    subjectname=$(basename $folder)
#    targetfolder=tractseg/subjects/$subjectname
#    mkdir -p $targetfolder
#    sh2peaks subjects/$subjectname/wmfod_norm.mif \
#        $targetfolder/wmfod_norm_peaks.nii.gz
#    TractSeg -i $targetfolder/wmfod_norm_peaks.nii.gz \
#             -o $targetfolder/tractseg_output \
#             --output_type tract_segmentation
#    TractSeg -i $targetfolder/wmfod_norm_peaks.nii.gz \
#             -o $targetfolder/tractseg_output  \
#             --output_type endings_segmentation
#    TractSeg -i $targetfolder/wmfod_norm_peaks.nii.gz \
#             -o $targetfolder/tractseg_output \
#             --output_type TOM
#    Tracking -i $targetfolder/wmfod_norm_peaks.nii.gz \
#             -o $targetfolder/tractseg_output 
#done


####### Perform tractseg over the template
# pip install dipy pandas torch TractSeg

targetfolder=template/tractseg/
#mkdir -p $targetfolder
#
#sh2peaks template/wmfod_multi_template.mif \
#    $targetfolder/wmfod_multitemplate_peaks.nii.gz
#
#TractSeg -i $targetfolder/wmfod_multitemplate_peaks.nii.gz \
#         -o $targetfolder/tractseg_output \
#         --output_type tract_segmentation
#TractSeg -i $targetfolder/wmfod_multitemplate_peaks.nii.gz \
#         -o $targetfolder/tractseg_output \
#         --output_type endings_segmentation
#TractSeg -i $targetfolder/wmfod_multitemplate_peaks.nii.gz \
#         -o $targetfolder/tractseg_output \
#         --output_type TOM
#Tracking -i $targetfolder/wmfod_multitemplate_peaks.nii.gz \
#         -o $targetfolder/tractseg_output \

# Manually create the SCP, which for some reason doesn't cross in the tragseg output
# Need to manually define the through_upper_thalamus region, which is just a few axial slices
# across the entire brain at approx. the height of the upper thalamus
# Also, delete the SCP generated from tractseg for easier subsequent processing
#rm template/tractseg/tractseg_output/TOM_trackings/SCP*.tck
#tractfolder=template/tracts
#fsfolder=template/t1_in_template_space/freesurfer/sub-003/
#parcellation=$fsfolder/mri/aparc.a2009s+aseg.mgz
#regionsfolder=template/regions
#mkdir -p template/tracts
#mrcalc $parcellation \
#      49 -eq -datatype bit $regionsfolder/Thalamus_R.mif --force
#mrcalc $parcellation \
#      10 -eq -datatype bit \
#      $regionsfolder/Thalamus_L.mif
#tckedit \
#    template/tracks_2_million_sift.tck \
#    -include $regionsfolder/SCP_L.mif \
#    -include $regionsfolder/Thalamus_R.mif \
#    -exclude $regionsfolder/Thalamus_L.mif \
#    $tractfolder/tmp-SCP_L.tck --force 
#tckedit $tractfolder/tmp-SCP_L.tck \
#    -mask $regionsfolder/Thalamus_R.mif \
#    -inverse \
#    --force \
#    $tractfolder/tmp-SCP_L.tck 
#tckedit $tractfolder/tmp-SCP_L.tck \
#    -minlength 30 \
#    -exclude $regionsfolder/Thalamus_R.mif \
#    -exclude $regionsfolder/throughUpperThalamus.mif \
#    $tractfolder/tmp-SCP_L.tck --force
#~/diss/scripts/tractanalysis/tractremovespurious2 \
#    $tractfolder/tmp-SCP_L.tck \
#    template/wmfod_multi_template.mif \
#    $tractfolder/SCP_left.tck
#rm $tractfolder/tmp-SCP_L.tck
#tckedit \
#    template/tracks_2_million_sift.tck \
#    -include $regionsfolder/SCP_R.mif \
#    -include $regionsfolder/Thalamus_L.mif \
#    -exclude $regionsfolder/Thalamus_R.mif \
#    $tractfolder/tmp-SCP_R.tck --force 
#tckedit $tractfolder/tmp-SCP_R.tck \
#    -mask $regionsfolder/Thalamus_L.mif \
#    -inverse \
#    --force \
#    $tractfolder/tmp-SCP_R.tck 
#tckedit $tractfolder/tmp-SCP_R.tck \
#    -minlength 40 \
#    -exclude $regionsfolder/Thalamus_L.mif \
#    -exclude $regionsfolder/throughUpperThalamus.mif \
#    $tractfolder/tmp-SCP_R.tck --force
#~/diss/scripts/tractanalysis/tractremovespurious2 \
#    $tractfolder/tmp-SCP_R.tck \
#    template/wmfod_multi_template.mif \
#    $tractfolder/SCP_right.tck
#rm $tractfolder/tmp-SCP_R.tck

##### Copy some of the useful tractseg tracts into the tracts folder for easier access
tractsegfolder=template/tractseg/tractseg_output/TOM_trackings
cp $tractsegfolder/MCP.tck $tractsegfolder/ICP_*.tck template/tracts/


###### Register a control subject T1 (for now sub 003) into template space for visualization
t1folder=template/t1_in_template_space
t1_orig=../BIDS/subjects/sub-003/anat/sub-003_T1w.nii.gz 
#mkdir -p $t1folder
#mrconvert subjects/kikli_EBP_TUE_003-control/dwi_denoised_unringed_preproc_upsampled.mif \
#          $t1folder/dwi_upsampled.nii.gz
#bet $t1_orig \
#    $t1folder/sub-003_t1_brainonly.nii.gz
#epi_reg  --epi=$t1folder/dwi_upsampled.nii.gz \
#         --t1=$t1_orig \
#         --t1brain=$t1folder/sub-003_t1_brainonly.nii.gz \
#         --out=$t1folder/dwi2t1
#transformconvert $t1folder/dwi2t1.mat \
#                 $t1folder/dwi_upsampled.nii.gz \
#                 $t1_orig \
#                 flirt_import $t1folder/dwi2t1_warp.txt
#mrtransform $t1_orig \
#            -linear $t1folder/dwi2t1_warp.txt \
#            -inverse \
#            - | \
#mrtransform - \
#            -warp subjects/kikli_EBP_TUE_003-control/subject2template_warp.mif \
#            $t1folder/sub-003_t1_in_template_space.nii.gz

# Run freesurfer on the t1 in template space for segmentation and parcellation for visualization
#freesurferfolder=$t1folder/freesurfer
#mkdir -p $freesurferfolder
#source /user/local/freesurfer/7.4.1/SetUpFreesurfer.sh
#export SUBJECTS_DIR=$freesurferfolder
#recon-all -all -subjid sub-003 \
#          -i $t1folder/sub-003_t1_in_template_space.nii.gz \
#          -wsthresh 30 -gcut \
#          -sd $freesurferfolder
