%% Load data:
% p = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\MM103\MM103_161001_retino';
% p = '\\intrinsicScope\D\Data\Matthias\MM105';
% p = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\MM104\MM104_161001_retino';
% p = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\MM110\MM110_160918_retino';
p = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\MM105\MM105_161017_retino';
% p = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\MM102\MM102_161011_retino';
% p = 'T:\';
% load(fullfile(p, '20160907_203252_retinotopy_MM102_resultsManualGoodMc.mat'));
% meta = load(fullfile(p, '20161011_182641_retinotopy_MM102.mat'));
% load(fullfile(p, '20160918_185914_retinotopy_MM111_results160919.mat'));
% meta = load(fullfile(p, '20160918_185914_retinotopy_MM111.mat'));
load(fullfile(p, '20161017_185611_retinotopy_MM105_results161018.mat'));
meta = load(fullfile(p, '20161017_185611_retinotopy_MM105.mat'));

warning('consider excluding the bins in which the mouse can''t see the bar anymore')

% p = 'T:\ltt\';
% load(fullfile(p, '20160719_133126_retinotopy_lightTightTest_results160719.mat'));
% meta = load(fullfile(p, '20160719_133126_retinotopy_lightTightTest.mat'));

% Check if bar position record is incorrect, i.e. flipped for 90 and 180
% degrees (this happened because I didn't take into account a rotation
% during the generation of visual stimuli):
isBarPositionSignIncorrect = meta.frame.past.barPosition_deg(...
    find(meta.frame.past.barDirection_deg == 90, 1, 'first')) < 0;

%% Get response phase:
nCond = numel(results);
conds = unique(meta.frame.past.barDirection_deg);

% Create working copy of response:
for i = 1:nCond
    results(i).tuningCorr = results(i).tuning;
    
    % Normalize by ninbin (the online analysis does not do this automatically):
    nrm = permute(nanRep(1./results(i).nInBin(:), 0), [2, 3, 1]);
    nrm(~isfinite(nrm)) = 0;
    results(i).tuningCorr = bsxfun(@times, results(i).tuningCorr, nrm);
    
    if isBarPositionSignIncorrect && (conds(i)==90 || conds(i)==180)
        results(i).tuningCorr = results(i).tuningCorr(:,:,end:-1:1);
    end
    
    results(i).isGoodFrame = results(i).nInBin>0;
end

for i = 1:nCond
    for ii = 1:size(results(i).tuning, 3)
        % Apply smoothing:
%         results(i).tuningCorr(:,:,ii) = imgaussfilt(results(i).tuningCorr(:,:,ii), 5);
    end
end

for i = 1:nCond
    
    % Get FFT at first non-DC frequency:
    tmp = fft(results(i).tuningCorr(:,:,results(i).isGoodFrame), [], 3);
%     tmp = fft(results(i).tuningCorr, [], 3);

    % We multiply by -1 to rotate the complex angle by 180 deg so that the
    % center of the trial (center of visual field) corresponds to zero
    % angle:
    results(i).fft = tmp(:,:,2) * -1;
end

% Get added and subtracted phase field as described in Kalatsky and
% Stryker:
for i = 1:2
    results(i).add = results(i).fft .* results(i+2).fft;
    results(i).subt = results(i).fft ./ results(i+2).fft;
end

%% Play movies for visual inspection:

for i = 1:nCond
%     movHere = results(i).tuning(:,:,results(i).isGoodFrame);
    movHere = results(i).tuningCorr(:,:,results(i).isGoodFrame);
    
%     normalizer = mean(mean(movHere(1:100, 1:100, :), 1), 2);
%     movHere = bsxfun(@rdivide, movHere, normalizer);
%     movHere = movHere(:,:,results(i).isGoodFrame);
%     movHere = bsxfun(@times, movHere, ~isVessel);
    movHere = bsxfun(@minus, movHere, median(movHere, 3));
    ijPlay(movHere, ...
        sprintf('Condition %d', i));
end

%% Plot
isBackwards = 0;

figure(1)
clf

subplot(2, 3, 1);
imagesc(wrapToPi(angle(results(1+2*isBackwards).fft)), [-pi pi])
% imagesc(wrapToPi(angle(results(3).fft)), [-pi pi])
colormap(gca, jet)
colorbar
axis equal
title('Vertical single condition')

subplot(2, 3, 4);
imagesc(-wrapToPi(angle(results(2+2*isBackwards).fft)), [-pi pi])
colormap(gca, jet)
colorbar
axis equal
title('Horizontal single condition')

subplot(2, 3, 2);
% meanVerti = wrapToPi((angle(results(1).fft)+angle(results(3).fft))/2);
meanVerti = wrapToPi(angle(results(1+2*isBackwards).fft));
imagesc(meanVerti, [-pi pi])
colormap(gca, jet)
colorbar
axis equal
title('Vertical mean (more positive = higher altitude)')
colorbar

subplot(2, 3, 5);

% meanHori = wrapToPi((angle(results(2).fft)+angle(results(4).fft))/2);
meanHori = wrapToPi(angle(results(2+2*isBackwards).fft));
imagesc(meanHori, [-pi pi])
colormap(gca, jet)
colorbar
axis equal
title('Horizontal mean (more positive = more temporal)')
colorbar

subplot(2, 3, 3);
powerCombined = abs(results(1).fft) ...
    + abs(results(3).fft) ...
    + abs(results(2).fft) ...
    + abs(results(4).fft);
imagesc(powerCombined, prctile(powerCombined(:), [0.5 99.5]))
% imagesc(powerCombined, [0 3000])
colormap(gca, jet)
axis equal
title('Combined power')

%%%
% rotd = 0;
% rotd = rotd-10; % Use this to find the perfect rotation angle to remove
% discontinuities.
rotd = 0;

rot = complex(cosd(rotd), sind(rotd));
meanVertiGrad = wrapToPi((angle(results(1).fft*rot)+angle(results(3).fft*rot))/2);
meanHoriGrad = wrapToPi((angle(results(2).fft*rot)+angle(results(4).fft*rot))/2);

% Single condition:
% meanVertiGrad = wrapToPi((angle(results(1+2*isBackwards).fft*rot)+angle(results(3).fft*rot))/2);
% meanHoriGrad = wrapToPi((angle(results(2+2*isBackwards).fft*rot)+angle(results(4).fft*rot))/2);

subplot(2, 3, 6);
smoothRad = 5;
[Gmag, Gdir1] = imgradient(imgaussfilt(meanVertiGrad, smoothRad));
[~, Gdir2] = imgradient(imgaussfilt(meanHoriGrad, smoothRad));
fieldSign = sind(Gdir1 - Gdir2);
fs = imgaussfilt(fieldSign, smoothRad);
fs = fs .* powerCombined;
imagesc(fs, [-1 1] .* prctile(abs(fs(:)), 95))
colormap(gca, jet)
title('Field sign')
axis equal

return

%% Save field sign:
p = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\MM102\map';
n = '20161011_182641_retinotopy_MM102';
imwrite(ceil(mat2gray(fs, [-1 1] .* prctile(abs(fs(:)), 95))*255), jet(255), fullfile(p, [n '_fieldsign.png']))

%% Get delay:
if false
    subplot(2, 3, 6);
    h = impoly;
    isV1 = createMask(h);
    delay = angle(median(results(2).subt(isV1)))/2;
end

delay = 0;

for i = 1:2
    results(i).angleNoDelay = angle(results(i).fft) - delay ;
end

for i = 3:4
    results(i).angleNoDelay = angle(results(i).fft) - delay;
end

% Plot after subtracting delay:
% figure(11101)
% imagesc(wrapToPi(results(2).angleNoDelay), [-pi pi])
% colormap(hsv)
% axis equal

subplot(2, 3, 2);
meanHori = wrapToPi((results(1).angleNoDelay+results(3).angleNoDelay)/2);
imagesc(meanHori, [-pi pi]/1.5)
colormap(gca, jet)
title('Vertical mean (more positive = higher altitude)')
colorbar
axis equal

subplot(2, 3, 5);
meanVerti = wrapToPi((results(2).angleNoDelay+results(4).angleNoDelay)/2);
imagesc(meanVerti, [-pi pi]/1.5)
colormap(gca, jet)
title('Horizontal mean (more positive = more temporal)')
colorbar
axis equal

% Note: Field sign is not affected by subtractind delay.
subplot(2, 3, 6);
[~, Gdir1] = imgradient(imgaussfilt(meanVerti, smoothRad));
[~, Gdir2] = imgradient(imgaussfilt(meanHori, smoothRad));
fieldSign = sind(Gdir2 - Gdir1);
fieldSign = imgaussfilt(fieldSign, smoothRad);
imagesc(fieldSign)
colormap(gca, jet)
title('Field sign')
axis equal

%% Save data:
wfDir = '\\research.files.med.harvard.edu\Neurobio\HarveyLab\Matthias\data\imaging\widefield\';
mapDir = fullfile(wfDir, 'MM104\map');
if ~exist(mapDir, 'dir')
    mkdir(mapDir);
end

fname = [meta.settings.expName '_retino'];

imInd = gray2ind(mat2gray(powerCombined), 255);
imwrite(imInd, jet(255), fullfile(mapDir, [fname, '_power.png']));

imInd = gray2ind(mat2gray(fieldSign), 255);
imwrite(imInd, jet(255), fullfile(mapDir, [fname, '_fieldSign.png']));
