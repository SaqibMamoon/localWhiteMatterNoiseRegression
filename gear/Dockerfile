FROM neurodebian:xenial
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Initialize flywheel v0 and move the required files into the container 
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY lmake_binary_masks_from_fsdir.py make_binary_masks_from_fsdir.py ${FLYWHEEL}
COPY compiled_localWM/ /opt/compiled_localWM
RUN chmod +x /flywheel/v0/run

# Install required packages    
RUN apt-get update \
    && apt-get install -y \
    git \
    python3 \
    python3-pip \
    wget \
    zip \
    unzip \
    fsl-core

# Install python packages
RUN pip3 install --upgrade pip
RUN pip3 install matplotlib nibabel imageio 

# Download and install MCR on call
RUN wget http://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/2/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_2_glnxa64.zip
RUN mkdir matlabins
RUN unzip MATLAB_Runtime_R2019b_Update_2_glnxa64.zip -d /matlabins/
RUN /matlabins/install -mode silent -agreeToLicense yes

# Download and install Freesurfer on call
RUN wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz
RUN mkdir freesurfer
RUN tar -zxf freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz 
COPY license.txt /freesurfer/license.txt
ENV FREESURFER_HOME /freesurfer

# Set the entrypoint  
# ENTRYPOINT /flywheel/v0/run
