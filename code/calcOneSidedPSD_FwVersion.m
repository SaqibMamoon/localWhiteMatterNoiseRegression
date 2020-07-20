function calcOneSidedPSD_FwVersion(rawTimeseriesPath, processedTimeseriesPath, grayMattermask, TRinSec, outputPath)
% Return the power spectral denisty of the input signal.
%
% Syntax:
%  [psd, freqSupport] = calcOneSidedPSD(rawTimeseriesPath, processedTimeseriesPath, grayMattermask, TRinSec, outputPath)
%
% Description:
%   The one-sided power spectrum of the signal. The time-base
%	is set to the one-sided frequency range (in Hz). The length
%   is one-half the input length. The values are in units of power, with
%   each row of the values field corresponding to each row of the values
%   field in the input dataStruct. The sum of the values in the one-sided
%   spectrum is equal to the variance of the input signal. Requires
%   freesurferMatlabLibrary.
%   This is a wrapper for regressLocalWhiteMatter gear. The original 
%   function is located in the forwardmodel repo in Aguirre Lab github. 
%   The code was modified to allow using MRI images as inputs and it       
%   compares two images before and after regression by plotting logarithmic
%   plots
%
%
% Inputs:
%   rawTimeseriesPath     - Timeseries image before regression. The format
%                           should be nifti
%   rawTimeseriesPath     - Timeseries image after regression. The format
%                           should be nifti
%   grayMattermask        - Gray matter binary mask in the same space with
%                           your timeseries images. Used to exclude other
%                           tissue in the brain for plotting
%   TRinSec               - Tr in seconds. Used to construct signal support
%   outputPath            - Output save path. Should not include the image
%                           name and extention
% Outputs:
%   None 
%

% Convert TR to number for the gear
TRinSec = str2num(TRinSec)

% Load unprocessed nifti
boldDataUnprocessed = load_nifti(rawTimeseriesPath);
timeseriesUnprocessed = boldDataUnprocessed.vol;

% Get the unprocessed signal size
signalSizeUnprocessed = size(timeseriesUnprocessed);

% Load processed nifti
boldDataProcessed = load_nifti(processedTimeseriesPath);
timeseriesProcessed = boldDataProcessed.vol;

% Get the processed signal size
signalSizeProcessed = size(timeseriesProcessed);

% Check if the processed and the unprocessed have the same size as the bold image
if signalSizeUnprocessed ~= signalSizeProcessed
    error('Your processed and unprocessed images have different resolutions')
end

% Reshape both images into 2D matrices
signalAllVoxelsUnprocessed = reshape(timeseriesUnprocessed,signalSizeUnprocessed(1)*signalSizeUnprocessed(2)*signalSizeUnprocessed(3),signalSizeUnprocessed(4));
signalAllVoxelsProcessed = reshape(timeseriesProcessed,signalSizeUnprocessed(1)*signalSizeUnprocessed(2)*signalSizeUnprocessed(3),signalSizeUnprocessed(4));

% Get the size of the 2D matrix
twoDSizeRaw = size(signalAllVoxelsUnprocessed);

% Load thegray matter mask and reshape
grayData = load_nifti(grayMattermask);
gray = grayData.vol;
grayAllVoxels = gray(:);
graySize = size(grayAllVoxels);

% Check if the gray matter image resolution is the same as timeseries
if twoDSizeRaw(1) ~= graySize(1)
    error('Voxel number of gray matter mask is not equal to bold image. Make sure they have the same resolution')
end

% Remove everything but gray matter from both timeseries
zeroIndicesGray = find(grayAllVoxels == 0);
signalAllVoxelsUnprocessed(zeroIndicesGray, :) = [];
signalAllVoxelsProcessed(zeroIndicesGray, :) = [];

% Get the new 2D matrix size
twoDSize = size(signalAllVoxelsUnprocessed);

% Drop the last timepoint if the timeseries length is not even
if mod(twoDSize(2),2)
    signalAllVoxelsUnprocessed = signalAllVoxelsUnprocessed(: , 1:end-1);
    signalAllVoxelsProcessed = signalAllVoxelsProcessed(: , 1:end-1);
    twoDSize(2) = twoDSize(2) - 1;
end

% Combine the two matrices in a cell
combinedMatrices = {signalAllVoxelsUnprocessed, signalAllVoxelsProcessed};

% Create the temporalSupport 
TRinMsec = TRinSec*1000;
lastTRTime = (twoDSize(2)-1) * TRinMsec;
signalSupport = (0:TRinMsec:lastTRTime);

% loop through the voxels of each matrices and calculate psd
beforeAndAfterPSD = {};
beforeAndAfterPSDSupport = {};
for item = combinedMatrices
    signalAllVoxels = item{1};
    
    % Allocate space with an empty matrix for all psd
    allPSD = zeros(twoDSize(1), twoDSize(2)/2);
    allPSDSupport = allPSD;
    
    for ii = 1:twoDSize(1)
        % Get the signal
        signal = signalAllVoxels(ii,:);

        % Run calcOneSidedPSD
        [psd, psdSupport] = calcOneSidedPSD(signal, signalSupport);

        % Append psd and psd support to new matrix 
        allPSD(ii,:) = psd;
        allPSDSupport(ii,:) = psdSupport;
    end
    
    % Append all PSD matrices to the empty cell
    beforeAndAfterPSD{end+1} = allPSD;
    beforeAndAfterPSDSupport{end+1} = allPSDSupport(1,:);
end

% Get the average psd for both cells (before and after)
beforeAndAfterPSD{1} = mean(beforeAndAfterPSD{1});
beforeAndAfterPSD{2} = mean(beforeAndAfterPSD{2});

% Create logarithmic plots for frequency-power and save
f = figure('visible','off');
loglog(beforeAndAfterPSDSupport{1},beforeAndAfterPSD{1}, 'DisplayName', 'beforeRegression')
xlabel('Frequency')
ylabel('Power')
hold on 
loglog(beforeAndAfterPSDSupport{2},beforeAndAfterPSD{2}, 'DisplayName', 'afterRegression')
xlabel('Frequency')
ylabel('Power')
hold off
legend
saveas(f, fullfile(outputPath, 'psdDiagnostics'), 'png')

end % function
