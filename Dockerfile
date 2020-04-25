FROM neurodebian:xenial
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Initialize flywheel v0 and move the required files into the container 
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY denoiser-master.zip /tmp/denoiser-master.zip
RUN chmod +x /flywheel/v0/run

# Install required packages    
RUN apt-get update \
    && apt-get install -y \
    git \
    python3 \
    python3-pip \
    zip \
    unzip
RUN unzip -q /tmp/denoiser-master.zip -d /tmp

# Install python packages
RUN pip3 install --upgrade pip
RUN pip3 install -r /tmp/denoiser-master/requirements.txt

# Download and install MCR on call
RUN wget http://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/2/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_2_glnxa64.zip
RUN mkdir matlabins
RUN unzip MATLAB_Runtime_R2019b_Update_2_glnxa64.zip -d /matlabins/
RUN /matlabins/install -mode silent -agreeToLicense yes

# Set the entrypoint  
# ENTRYPOINT /flywheel/v0/run



