import os

def make_binary_masks_from_fsdir(freesurfer_subject_folder, template_bold, fsl_identity_mat, freesurfer_environment_path, fsl_environment_path, n_erode, output_path):
    
    '''
    This function creates binary brain, white and gray matter masks from 
    a recon-all folder. It was created to be used with fmriprep output in T1w  
    space, so the masks are resampled to the native func resolution as this
    is how fmriprep keeps the processed images in any output space specified.
    
    Inputs:
        - freesurfer_subject_folder: path to freesurfer recon-all output 
        - template_bold: bold target image to get the target resolution from.
        - fsl_identity_mat: Path to the fsl identity .mat file. Usually located
        in /fsl/etc/flirtsch/ident.mat. However, it can be placed somewhere 
        else if you download fsl with neurodebian.
        - freesurfer_environment_path: path to the bin file in the Freesurfer
        file directory.
        - fsl_environment_path: path to the bin file in the fsl file directory
        - n_erode: Number of voxels to erode from the white matter mask
        - output_path: output path to save all files.
        
    Output:
        - niftiConvertedOrigT1: nifti converted original T1
        - niftiConvertedBrain: nifti converted brain.mgz
        - niftiConvertedAparc+aseg: nifti converted aparc+aseg.mgz
        - resampledOrigT1: original T1 resampled to func resolution
        - resampledBrainMask: brain.mgz resampled to func resolution
        - resampledAparc+aseg: aparc+aseg.mgz resampled to func resolution 
        with nearestneighbour interpolation 
        - binaryBrainMask: Final binary brain mask
        - binaryWhiteMask: Final binary white mask
        - binaryGrayMask: Final binary gray mask
        
    '''
    
    # Load the labels file (aparc+aseg), brain and original T1 
    orig_T1 = os.path.join(freesurfer_subject_folder, 'mri', 'orig.mgz')    
    brain_wo_skull = os.path.join(freesurfer_subject_folder, 'mri', 'brain.mgz')    
    aparc_aseg_segment = os.path.join(freesurfer_subject_folder, 'mri', 'aparc+aseg.mgz')
   
    # Convert the original T1, aparc+aseg, and the skull stripped brain image to nifti
    converted_orig_T1_destination = os.path.join(output_path, 'niftiConvertedOrigT1.nii.gz')
    converted_brain_destination = os.path.join(output_path, 'niftiConvertedBrain.nii.gz')
    converted_aparc_aseg = os.path.join(output_path, 'niftiConvertedAparc+aseg.nii.gz')
    convert_raw = '%s %s %s' % (os.path.join(freesurfer_environment_path, 'mri_convert.bin'),
                                orig_T1, converted_orig_T1_destination)       
    convert_brain = '%s %s %s' % (os.path.join(freesurfer_environment_path, 'mri_convert.bin'),
                                  brain_wo_skull, converted_brain_destination)
    convert_aseg = '%s %s %s' % (os.path.join(freesurfer_environment_path, 'mri_convert.bin'),
                                  aparc_aseg_segment, converted_aparc_aseg)
    os.system(convert_raw + ';' + convert_brain + ';' + convert_aseg)
    
    # Downsample the original T1, brain mask and the aparc+aseg to the bold resolution
    resampled_orig_T1 = os.path.join(output_path, 'resampledOrigT1.nii.gz')
    resampled_brain_mask = os.path.join(output_path, 'resampledBrainMask.nii.gz')      
    resampled_aparc_aseg = os.path.join(output_path, 'resampledAparc+aseg.nii.gz')
    resample_command_T1 = '%s -in %s -ref %s -usesqform -applyxfm -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                              converted_orig_T1_destination, template_bold,
                                                                              resampled_orig_T1)     
    resample_command_brain = '%s -in %s -ref %s -usesqform -applyxfm -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                                 converted_brain_destination, template_bold,
                                                                                 resampled_brain_mask)    
    resample_command_aparc_aseg = '%s -in %s -ref %s -usesqform -applyxfm -interp nearestneighbour -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                                                               converted_aparc_aseg, template_bold,
                                                                                                               resampled_aparc_aseg)
    os.system(resample_command_T1 + ';' + resample_command_brain + ';' + resample_command_aparc_aseg)
    
    # Finally, binarize the resampled brain and make binary white and gray matter mask
    binary_brain_mask = os.path.join(output_path, 'binaryBrainMask.nii.gz')
    binary_white_mask = os.path.join(output_path, 'binaryWhiteMask.nii.gz')
    binary_gray_mask = os.path.join(output_path, 'binaryGrayMask.nii.gz')
    binarize_brain_command = '%s %s -thr 50 -bin %s' % (os.path.join(fsl_environment_path, 'fslmaths'),
                                                        resampled_brain_mask, binary_brain_mask)
    if n_erode != '0':
        binarize_white_command = '%s --i %s --wm --erode %s --o %s' % (os.path.join(freesurfer_environment_path, 'mri_binarize.bin'),
                                                                       resampled_aparc_aseg, n_erode, binary_white_mask)
    else:
        binarize_white_command = '%s --i %s --wm --o %s' % (os.path.join(freesurfer_environment_path, 'mri_binarize.bin'),
                                                            resampled_aparc_aseg, binary_white_mask)        
    binarize_gray_command = '%s --i %s --gm --o %s' % (os.path.join(freesurfer_environment_path, 'mri_binarize.bin'),
                                                       resampled_aparc_aseg, binary_gray_mask)    
    os.system(binarize_brain_command + ';' + binarize_white_command + ';' + binarize_gray_command)
    
    return (resampled_orig_T1, binary_brain_mask, binary_white_mask, binary_gray_mask)