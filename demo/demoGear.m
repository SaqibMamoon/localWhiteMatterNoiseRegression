% DEMO_localWhiteMatterNoiseRegression 
%
% This routine downloads some fmriprep archive images flywheel and then
% submits the files for analysis

%% Find the python code to resample and niftify 
[~, userID] = system('whoami');
userID = strtrim(userID);
if ismac
    pythonScript = fullfile('/Users/', userID, '/Documents/MATLAB/projects/localWhiteMatterNoiseRegression/demo/niftify_and_resample.py');
elseif isunix 
    pythonScript = fullfile('/home/', userID, '/Documents/MATLAB/projects/localWhiteMatterNoiseRegression/demo/niftify_and_resample.py');
end
    %% Variable declaration
% Project name, input and output path
projectName = 'localWhiteMatterNoiseRegression';
inputDataDir = getpref(projectName,'inputDataDir');
outputDataDir = getpref(projectName,'outputDataDir');

% Fw project name, subject Id, and the session number
fwProjectName = 'mtSinaiFlicker';
subject = 'HEROgka1';
sessionNum = 1; % Session number according to chronological order. This is not the session label ! 

% Fmriprep related paths: analysisLabel, zip archive name and the name of 
% the bold file that we want to extract from the zip archive.
analysisLabel = 'fmriprep-fwheudiconv 04/21/2020 17:43:29'; 
zipName = 'fmriprep_sub-HEROgka1_5e9f6990fbc13931be1ee99d.zip';
boldName = 'sub-HEROgka1_ses-041416_task-LightFluxA_run-01_desc-preproc_bold.nii.gz';

% recon-All related paths: analysis label, zip file name, and the masks we
% want to download from the archive. 
reconAllAnalysisLabel = 'freesurfer-recon-all 04/16/2020 21:27:38';
reconAllZipName = 'freesurfer-recon-all_gka01_D04-17-20T17-23.zip';
whiteMatterMask = 'wm.seg.mgz';
brainMask = 'brainmask.mgz';

% remove_localWM related variables
radius = 15;

% Resample the masks to match the BOLD res for the localWM func - requires FSL and Freesurfer 
resample = true;

% Create the input and output dir if they do not exist
if ~exist(inputDataDir,'dir')
    mkdir(inputDataDir);
end
if ~exist(outputDataDir,'dir')
    mkdir(outputDataDir);
end
% Create a flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));

%% Load the analysis object, find and download the files
% Find the analysis object 
project = fw.projects.findFirst(strcat('label=', fwProjectName));
subject = project.subjects.findFirst(strcat('label=', subject));
session = subject.sessions.find{sessionNum};  % Get the first session. Label option doesn't work here for some reason
analysis = session.analyses.findFirst(strcat('label=', analysisLabel));

% Get the zip information from the analysis object
zipInfo = analysis.getFileZipInfo(zipName);
zipMembers = zipInfo.members;

% Loop through the members of the zip archive and find the path to the bold 
% file we want to download
fprintf('Downloading files from the fmriprep archive\n')
for ii = 1:length(zipMembers)
    [filepath,name,ext] = fileparts(zipMembers{ii}.path); 
    if strcmp(strcat(name,ext), boldName)
        boldPath = zipMembers{ii}.path;
    end
end    

% Once we have the bold path, we can find the confound file by simply 
% changing a part of the name as they are organized similarly 
confoundFile = strrep(boldPath, 'desc-preproc_bold.nii.gz', 'desc-confounds_regressors.tsv');

% Now download these files if they don't already exist
[~, name, ext] = fileparts(boldPath);
boldFinalSavePath = fullfile(inputDataDir, strcat(name,ext));
confoundFinalSavePath = strrep(boldFinalSavePath,'desc-preproc_bold.nii.gz', 'desc-confounds_regressors.tsv');
if ~isfile(boldFinalSavePath)
    analysis.downloadFileZipMember(zipName, boldPath, boldFinalSavePath);
end
if ~isfile(confoundFinalSavePath)
    analysis.downloadFileZipMember(zipName, confoundFile, confoundFinalSavePath);
end

%% Download the recon-all stuff
% Set the analysis name
analysisRecon = session.analyses.findFirst(strcat('label=', reconAllAnalysisLabel));

% Get the zip information from the analysis object
zipInfo = analysisRecon.getFileZipInfo(reconAllZipName);
reconAllzipMembers = zipInfo.members;

% Loop through the members of the zip archive and find the path to the white 
% matter file.
fprintf('Downloading files from the recon-all archive\n')
for ii = 1:length(reconAllzipMembers)
    [filepath,name,ext] = fileparts(reconAllzipMembers{ii}.path); 
    if strcmp(strcat(name,ext), whiteMatterMask)
        whiteMatterMaskPath = reconAllzipMembers{ii}.path;
    elseif strcmp(strcat(name,ext), brainMask)
        brainMaskPath = reconAllzipMembers{ii}.path;
    end
end    

% Download the white matter and brain masks
whiteMatterMaskFinalSavePath = fullfile(inputDataDir, 'wm.seg.mgz');
brainMaskFinalSavePath = fullfile(inputDataDir, 'brainmask.mgz');
if ~isfile(whiteMatterMaskFinalSavePath)
    analysisRecon.downloadFileZipMember(reconAllZipName, whiteMatterMaskPath, whiteMatterMaskFinalSavePath);
end
if ~isfile(brainMaskFinalSavePath)
    analysisRecon.downloadFileZipMember(reconAllZipName, brainMaskPath, brainMaskFinalSavePath);
end

% Convert to nifti and resample
if resample
    newNiftiWhite = fullfile(inputDataDir, 'wm.seg.nii.gz');
    newNiftiBrain = fullfile(inputDataDir, 'brainmask.nii.gz');
    if ~isfile(newNiftiWhite)
        command1 = ['python3 ' pythonScript ' ' whiteMatterMaskFinalSavePath ' ' boldFinalSavePath ' ' newNiftiWhite];
        system(command1)
    end
    if ~isfile(newNiftiBrain)
        command2 = ['python3 ' pythonScript ' ' brainMaskFinalSavePath ' ' boldFinalSavePath ' ' newNiftiBrain];
        system(command2);
    end
    fprintf('Calling remove_localWM')
    remove_localWM_FwVersion(boldFinalSavePath, newNiftiBrain, newNiftiWhite, outputDataDir, radius)
% Run the function without resampling if your images are same size
else
    fprintf('Calling remove_localWM')
    remove_localWM_FwVersion(boldFinalSavePath, brainMaskFinalSavePath, whiteMatterMaskFinalSavePath, outputDataDir, radius)
end
