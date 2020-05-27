function calcOneSidedPSD(rawTimeseriesPath, processedTimeseriesPath, grayMattermask, TRinSec, outputPath)
% Return the power spectral denisty of the input signal.
%
% Syntax:
%  [psd, freqSupport] = calcOneSidedPSD( signal, temporalSupport )
%
% Description:
%   The one-sided power spectrum of the signal. The time-base
%	is set to the one-sided frequency range (in Hz). The length
%   is one-half the input length. The values are in units of power, with
%   each row of the values field corresponding to each row of the values
%   field in the input dataStruct. The sum of the values in the one-sided
%   spectrum is equal to the variance of the input signal. Requires
%   freesurferMatlabLibrary.
%
% Inputs:
%   signal                - 1xn vector of values that is the time-series
%                           data. Must be of even length (sorry!).
%   signalSupport         - 1xn vector of values (in units of msecs) that
%                           is the temporal support for the signal.
%
% Outputs:
%   psd                   - 1x(n/2) vector of values that is the power at
%                           each frequency
%   psdSupport            - 1x(n/2) vector of values (in units of Hz) that
%                           is the frequency support for the power
%                           spectrum.
%

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

% Load thegray matter mask and remove everything else from the brain
grayData = load_nifti(grayMattermask);
gray = grayData.vol;
grayAllVoxels = gray(:);
graySize = size(grayAllVoxels);
if twoDSizeRaw(1) ~= graySize(1)
    error('Voxel number of gray matter mask is not equal to bold image. Make sure they have the same resolution')
end
zeroIndicesGray = find(grayAllVoxels == 0);
signalAllVoxelsUnprocessed(zeroIndicesGray, :) = [];
signalAllVoxelsProcessed(zeroIndicesGray, :) = [];

% Get the twoDSize again for the new gray matter matrices
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
        signal = signalAllVoxels(ii,:);

        % Length of the signal
        dataLength = length(signal);

        % Apologize for not having the solution for odd-length vectors yet
        if mod(dataLength,2)
            error('Currently implemented for even-length signals only. Sorry.');
        end

        % derive the deltaT from the stimulusTimebase (units of msecs)
        check = diff(signalSupport);
        deltaT = check(1);

        % meanCenter
        signal = signal - mean(signal);

        % Calculate the FFT
        X=fft(signal);
        psd=X.*conj(X)/(dataLength^2);
        psd=psd(1:dataLength/2);

        % Produce the psd support in Hz
        psdSupport = (0:dataLength/2-1)/(deltaT*dataLength/1000);

        % Append to new matrix 
        allPSD(ii,:) = psd;
        allPSDSupport(ii,:) = psdSupport;
    end
    
    beforeAndAfterPSD{end+1} = allPSD;
    beforeAndAfterPSDSupport{end+1} = allPSDSupport(1,:);
end

beforeAndAfterPSD{1} = mean(beforeAndAfterPSD{1});
beforeAndAfterPSD{2} = mean(beforeAndAfterPSD{2});

f = figure('visible','off');
plot(beforeAndAfterPSDSupport{1},beforeAndAfterPSD{1}, 'DisplayName', 'beforeRegression')
xlabel('Frequency')
ylabel('Power')
hold on 
plot(beforeAndAfterPSDSupport{2},beforeAndAfterPSD{2}, 'DisplayName', 'afterRegression')
xlabel('Frequency')
ylabel('Power')
hold off
legend
saveas(f, fullfile(outputPath, 'psdDiagnostics'), 'png')
end % function