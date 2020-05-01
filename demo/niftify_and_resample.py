import nibabel
import nilearn
import sys
from nilearn import image

def niftify_and_resample(inputim, targetim, outputim):
    input_img = nibabel.load(inputim)
    target_image = nibabel.load(targetim)
    resampled_img = image.resample_to_img(input_img, target_image)
    nibabel.save(resampled_img, outputim)
niftify_and_resample(*sys.argv[1:]) 
