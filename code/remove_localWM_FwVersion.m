function remove_localWM_FwVersion(func,brainMask,whiteMatterMask,outputPath,radius)
% Creates local white matter timecourses for each voxel, and saves these
%   timecourses as a 4D volume ['w' func '.nii.gz']. The default 'func'
%   input is 'drf', so the final 4D volume will be 'wdrf.nii.gz'. Will
%   also return an output 4D matrix 'noWMtc'.
%
% Inputs:
%   func: Functional image
%   brainMask: Binary brain mask
%   whiteMatterMask: Binary white matter mask
%   outputPath: Path to save the cleaned up image
%   radius: String!! search radius
%
% Usage:
%   [noWMtc] = remove_localWM(session_dir,runNum,func,radius)
%
%   Written by Marcelo G Mattar  Dec 2015
%   Updated by Andrew S Bock Jan 2016 (minor filename and header changes)
%   Modified for a Flywheel Gear May 4
%% Set default parameters
if ~exist('radius','var')
    radius = 15;
else
    radius = str2num(radius)
end

%% Remove local white matter
% Load in brain and white matter masks, as well as the functional timecourse file
[~,~,brainMaskExt] = fileparts(brainMask); 
if strcmp(brainMaskExt, '.gz')
    brain = load_nifti(brainMask); 
    brain = brain.vol;
else
    brain = load_mgh(brainMask);
end    
[~,~,wmmaskMaskExt] = fileparts(whiteMatterMask); 
if strcmp(wmmaskMaskExt, '.gz')
    wmmask = load_nifti(whiteMatterMask); 
    WM = wmmask.vol;
else
    WM = load_mgh(whiteMatterMask);
end

fmri = load_nifti(func);
voxsize = fmri.pixdim(2);
dims=size(fmri.vol);
tc = reshape(fmri.vol,dims(1)*dims(2)*dims(3),dims(4));
% Get only voxels in the brain, non-WM, and with non-flat timecourses
GMmask = and(brain(:),~WM(:));
flatTC = (std(tc,[],2)==0);
GMind = find(and(GMmask,~flatTC));
numGMvox = numel(GMind);
% Get the x,y,z coordinates for the entire 3D volume
[Xbr,Ybr,Zbr] = ind2sub([dims(1),dims(2),dims(3)],GMind);
% WM
numWMvox = sum(WM(:)); % Number of WM voxels
WMind = find(WM(:)); % WM indices
radVox = radius/voxsize; % Define radius in terms of voxels
K = ceil(((4/3)*pi*radVox^3)); % maximum number of voxels inside a given sphere

%% Create sparse matrix with the corresponding local-WM voxels for each GM voxel
% wmSpheres is a vector with the non-zero indices of the NxN sparse matrix
disp('Creating a local WM timecourse around each voxel');
wmSpheres = sparse([],[],false,numGMvox,size(tc,1),numWMvox*K);
[Xwm,Ywm,Zwm] = ind2sub([dims(1),dims(2),dims(3)],WMind);
%progBar=ProgressBar(numWMvox,'Computing local-WM spheres...');
for iwm = 1:numWMvox
    sphereMask = ((Xwm(iwm)-Xbr).^2  +  (Ywm(iwm)-Ybr).^2  +  (Zwm(iwm)-Zbr).^2)  <  (radVox^2);
    wmSpheres(:,WMind(iwm)) = logical(sphereMask);
    %if ~mod(iwm,round(numWMvox/1000));progBar(iwm);end
end

%% Create local WM-tc around each GM voxel
localWMtc = zscore(wmSpheres*tc,[],2);

%% Calculate the beta-values for each voxelwise regression
disp('Removing local WM effect from each voxel');
tcZsc = zscore(tc(GMind,:),[],2);
% Pearson correlation coefficient
r = sum(tcZsc .* localWMtc,2)/(size(tc,2)-1);
% Convert to beta value
beta = r .* std(tc(GMind,:),[],2);

%% Remove the effect of local WM
tc(GMind,:) = tc(GMind,:) - (localWMtc .* repmat(beta,1,size(tc,2)));

%% Save output volume
noWMtc = reshape(tc,size(fmri.vol));
fmri.vol = noWMtc;

% Get the name of the func file
[~,name,ext] = fileparts(func); 
save_nifti(fmri, fullfile(outputPath, strcat('noWm_', name, ext)))
disp('done.')
end
