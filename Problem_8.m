% Problem 13.10a – Digital Image Processing with MATLAB
% Brain Region Detection using Maximally Stable Extremal Regions (MSER)
% Required: MATLAB Computer Vision Toolbox
% Reference: Example 13.16

clear all; close all; clc;

% Read the CT image (grayscale)
f = imread('headCT.tif');

% Display original image
figure;
imshow(f);
title('Original Head CT Image');

% Detect MSER features to find the brain region
% Parameters chosen to isolate the brain region:
% - RegionAreaRange: [70000, 120000] targets large, contiguous brain region
%   while filtering out small structures (vessels, noise, artifacts)
regions = detectMSERFeatures(f, 'RegionAreaRange', [70000, 120000]);

% Create new figure for overlay display
figure;
imshow(f);
hold on;
plot(regions, 'showPixelList', true, 'showEllipses', false);
title('Brain Region Detected by MSER Superimposed on Original CT Image');
hold off;

% Display detection statistics
fprintf('Number of MSER regions detected: %d\n', regions.Count);

if regions.Count > 0
    % Handle case where PixelList is cell array (multiple regions) or 
    % int32 matrix (single region)
    if iscell(regions.PixelList)
        areas = cellfun(@length, regions.PixelList);
    else
        areas = size(regions.PixelList, 1);
    end
    
    fprintf('Region area range: %d to %d pixels\n', min(areas), max(areas));
    if length(areas) > 1
        fprintf('Mean region area: %.1f pixels\n', mean(areas));
    end
else
    fprintf('No regions detected with current parameters.\n');
    fprintf('Try adjusting RegionAreaRange values.\n');
end

% Optional: Display detected regions as a binary mask
if regions.Count > 0
    figure;
    mask = false(size(f));
    for i = 1:regions.Count
        if iscell(regions.PixelList)
            pixelList = regions.PixelList{i};
        else
            pixelList = regions.PixelList;
        end
        idx = sub2ind(size(f), pixelList(:,2), pixelList(:,1));
        mask(idx) = true;
    end
    imshow(mask);
    title('Binary Mask of Detected Brain Region');
end
