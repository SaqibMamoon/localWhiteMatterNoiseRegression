function localWhiteMatterNoiseRegressionLocalHook
% localWhiteMatterNoiseRegression
%
% For use with the ToolboxToolbox.  If you copy this into your
% ToolboxToolbox localToolboxHooks directory (by default,
% ~/localToolboxHooks) and delete "LocalHooksTemplate" from the filename,
% this will get run when you execute tbUse({'forwardModelWrapperConfig'}) to set up for
% this project.  You then edit your local copy to match your local machine.
%
% The main thing that this does is define Matlab preferences that specify input and output
% directories.
%
% You will need to edit the project location and i/o directory locations
% to match what is true on your computer.

 
%% Define project
projectName = 'localWhiteMatterNoiseRegression';
 

%% Clear out old preferences
if (ispref(projectName))
    rmpref(projectName);
end


%% Specify and save project location
projectBaseDir = tbLocateProject(projectName);
setpref(projectName,'projectBaseDir',projectBaseDir);


%% Set flywheel API key as a preference
flywheelAPIKey = 'Copy your Flywheel API key here';
setpref(projectName,'flywheelAPIKey',flywheelAPIKey);

%% Get the userID
[~, userID] = system('whoami');
userID = strtrim(userID);

%% Paths to store input data downloaded from Flywheel and output path
if ismac
    % Code to run on Mac plaform
    setpref(projectName,'inputDataDir',fullfile('/Users/',userID,'/Documents/localWhiteInput'));
    setpref(projectName,'outputDataDir',fullfile('/Users/',userID,'/Documents/localWhiteOutput'));
elseif isunix
    % Code to run on Linux plaform
    setpref(projectName,'inputDataDir',fullfile('/home/',userID,'/Documents/localWhiteInput'));
    setpref(projectName,'outputDataDir',fullfile('/home/',userID,'/Documents/localWhiteOutput'));    
elseif ispc
    % Code to run on Windows platform
    warning('No supported for PC')
else
    disp('What are you using?')
end

% %% Ensure that python3 and neuopythy are installed
% 
% % Check for some flavor of Python v3
% if floor(str2double(pyversion)) ~= 3
% 	warning('localHook:pythonVersion',['The routines expect Python v3, but v' pyversion ' is installed']);
% end

end
