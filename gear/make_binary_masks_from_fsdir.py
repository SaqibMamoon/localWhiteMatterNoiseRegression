import os

def make_binary_masks_from_fsdir(freesurfer_subject_folder, template_bold, fsl_identity_mat, freesurfer_environment_path, fsl_environment_path, output_path):
    
    # Load the labels file (aparc+aseg), brain and original T1 
    brain_mask = os.path.join(freesurfer_subject_folder, 'mri', 'brainmask.mgz')    
    white_and_gray_matter_segment = os.path.join(freesurfer_subject_folder, 'mri', 'aparc+aseg.mgz')
    orig_T1 = os.path.join(freesurfer_subject_folder, 'mri', 'orig.mgz')
     
    # Convert the original T1 and the skull stripped brain image to nifti
    converted_orig_T1_destination = os.path.join(output_path, 'niftiConvertedOrigT1.nii.gz')
    converted_brain_destination = os.path.join(output_path, 'niftiConvertedBrain.nii.gz')
    convert_raw = '%s %s %s' % (os.path.join(freesurfer_environment_path, 'mri_convert.bin'),
                                orig_T1, converted_orig_T1_destination)       
    convert_brain = '%s %s %s' % (os.path.join(freesurfer_environment_path, 'mri_convert.bin'),
                                  brain_mask, converted_brain_destination)
    os.system(convert_raw + ';' + convert_brain)    
    
    # Extract white and gray matter binary masks from the aparc+aseg labels and save as nifti
    converted_white_destination = os.path.join(output_path, 'binaryWhiteNoResampling.nii.gz') 
    converted_gray_destination = os.path.join(output_path, 'binaryGrayNoResampling.nii.gz')   
    extract_white = '%s --i %s --wm --o %s' % (os.path.join(freesurfer_environment_path, 'mri_binarize'),
                                               white_and_gray_matter_segment, converted_white_destination)  
    extract_gray = '%s --i %s --gm --o %s' % (os.path.join(freesurfer_environment_path, 'mri_binarize'),
                                              white_and_gray_matter_segment, converted_gray_destination)     
    os.system(extract_white + ';' + extract_gray)
    
    # Downsample the original T1 and the masks to the bold resolution
    resampled_orig_T1 = os.path.join(output_path, 'resampledOrigT1.nii.gz')
    resampled_brain_mask = os.path.join(output_path, 'resampledBrainMask.nii.gz')    
    binary_white_mask = os.path.join(output_path, 'binaryWhiteMask.nii.gz')
    binary_gray_mask = os.path.join(output_path, 'binaryGrayMask.nii.gz')   
    resample_command_T1 = '%s -in %s -ref %s -usesqform -applyxfm -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                              converted_orig_T1_destination, template_bold,
                                                                              resampled_orig_T1)     
    resample_command_brain = '%s -in %s -ref %s -usesqform -applyxfm -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                                 converted_brain_destination, template_bold,
                                                                                 resampled_brain_mask)    
    resample_command_white = '%s -in %s -ref %s -usesqform -applyxfm -interp nearestneighbour -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                                                          converted_white_destination, template_bold,
                                                                                                          binary_white_mask)
    resample_command_gray = '%s -in %s -ref %s -usesqform -applyxfm -interp nearestneighbour -out %s' % (os.path.join(fsl_environment_path, 'flirt'),
                                                                                                          converted_gray_destination, template_bold,
                                                                                                          binary_gray_mask)
    
    os.system(resample_command_T1 + ';' + resample_command_brain + ';' + resample_command_white + ';' + resample_command_gray)
    
    # Finally, binarize the resampled brain to make a brain mask
    binary_brain_mask = os.path.join(output_path, 'binaryBrainMask.nii.gz')
    binarize_brain_command = '%s %s -thr 50 -bin %s' % (os.path.join(fsl_environment_path, 'fslmaths'),
                                                        resampled_brain_mask, binary_brain_mask)
    os.system(binarize_brain_command)
    
    return (resampled_orig_T1, binary_brain_mask, binary_white_mask, binary_gray_mask)