%% Problem 4 - Complete Breast Implant Segmentation
% Combines intensity correction approach with adaptive region growing
% DIPWM3 Example 11.11 - Enhanced Version
clear; clc; close all;

%% Step 1: Read and preprocess the image
f = imread('breast-implant.tif');
f_double = double(f);
[rows, cols] = size(f_double);

fprintf('Image size: %d x %d\n', rows, cols);

%% Step 2: Apply intensity correction (from original approach)
% Compensate for brighter pixels near coils (if needed)
% This helps normalize the image before region growing
apply_intensity_correction = true;  % Set to false to skip

if apply_intensity_correction
    % Create magnitude ramp - values determined empirically
    intensity_correct = zeros(rows, cols);
    intensity_correct_row = linspace(0.75, 12.0, cols);
    for i = 1:rows
        intensity_correct(i, :) = intensity_correct_row;
    end
    
    % Apply correction
    f_corrected = f_double .* intensity_correct;
    
    % Normalize to original intensity range
    f_corrected = f_corrected * (max(f_double(:)) / max(f_corrected(:)));
else
    f_corrected = f_double;
end

%% Step 3: Light Gaussian smoothing
% Use light smoothing to reduce noise while preserving edges
sigma = 1.5;  % Can adjust between 1.0-2.0
f_smooth = imgaussfilt(f_corrected, sigma);

%% Step 4: Automatic seed point detection
% Find the brightest region (implant appears bright in MRI)
% Use a window-based approach to find the center of the implant

% Method 1: Use center of mass of bright pixels
threshold_bright = mean(f_smooth(:)) + 1.5 * std(f_smooth(:));
bright_mask = f_smooth > threshold_bright;

% Clean up bright mask
bright_mask = imclose(bright_mask, strel('disk', 10));
bright_mask = imfill(bright_mask, 'holes');

% Find connected components and select the largest
CC = bwconncomp(bright_mask);
if CC.NumObjects > 0
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~, largest_idx] = max(numPixels);
    largest_region = false(size(bright_mask));
    largest_region(CC.PixelIdxList{largest_idx}) = true;
    
    % Find centroid of largest bright region
    stats = regionprops(largest_region, 'Centroid');
    seed = round(stats.Centroid);
    seed = seed([2, 1]);  % Convert to [row, col]
    
    fprintf('Automatically detected seed at (%d, %d)\n', seed(1), seed(2));
else
    % Fallback: use center of image
    seed = round([rows/2, cols/2]);
    fprintf('Using fallback seed at (%d, %d)\n', seed(1), seed(2));
end

%% Step 5: Compute local statistics around the seed
% Define ROI around seed to learn implant intensity characteristics
roi_size = 20;  % Size of local region for statistics
r_min = max(1, seed(1) - roi_size);
r_max = min(rows, seed(1) + roi_size);
c_min = max(1, seed(2) - roi_size);
c_max = min(cols, seed(2) + roi_size);

seed_roi = f_smooth(r_min:r_max, c_min:c_max);
seed_mean = mean(seed_roi(:));
seed_std = std(seed_roi(:));

fprintf('Seed region statistics:\n');
fprintf('  Mean intensity: %.2f\n', seed_mean);
fprintf('  Std deviation:  %.2f\n', seed_std);

%% Step 6: Adaptive region growing
% Compute thresholds based on local statistics
global_threshold = max(2.5 * seed_std, 50);   % Global tolerance
local_threshold = 1.5 * seed_std;              % Local tolerance

fprintf('Thresholds:\n');
fprintf('  Global threshold: %.2f\n', global_threshold);
fprintf('  Local threshold:  %.2f\n', local_threshold);

% Perform region growing
implant_raw = region_grow_local(f_smooth, seed, global_threshold, local_threshold);
fprintf('Raw region growing: %d pixels\n', sum(implant_raw(:)));

%% Step 7: Post-processing - Clean up the mask
% Fill interior holes
implant_filled = imfill(implant_raw, 'holes');

% Keep only the largest connected component
CC = bwconncomp(implant_filled);
if CC.NumObjects > 0
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~, largest_idx] = max(numPixels);
    implant_largest = false(size(implant_filled));
    implant_largest(CC.PixelIdxList{largest_idx}) = true;
else
    implant_largest = implant_filled;
end

% Morphological smoothing
se1 = strel('disk', 3);  % For closing (fill small gaps)
se2 = strel('disk', 2);  % For opening (remove small protrusions)

implant_smooth = imclose(implant_largest, se1);
implant_smooth = imopen(implant_smooth, se2);

% Final cleanup - remove small objects
implant_smooth = bwareaopen(implant_smooth, 100);

fprintf('Final mask: %d pixels\n', sum(implant_smooth(:)));

%% Step 8: Extract boundary
boundaries = bwboundaries(implant_smooth, 'noholes');
if ~isempty(boundaries)
    % Use the largest boundary
    [~, idx] = max(cellfun(@length, boundaries));
    boundary = boundaries{idx};
    fprintf('Boundary extracted: %d points\n', length(boundary));
else
    boundary = [];
    warning('No boundary found!');
end

%% Step 9: Visualization - Create comprehensive figure display
figure('Position', [100, 100, 1200, 800]);

% Subplot 1: Original Image
subplot(2, 3, 1);
imshow(f, []);
title('Original Image', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Column'); ylabel('Row');

% Subplot 2: Intensity Corrected & Smoothed
subplot(2, 3, 2);
imshow(f_smooth, []);
hold on;
plot(seed(2), seed(1), 'r*', 'MarkerSize', 10, 'LineWidth', 2);
hold off;
title('Preprocessed Image with Seed Point', 'FontSize', 12, 'FontWeight', 'bold');

% Subplot 3: Raw Region Growing Result
subplot(2, 3, 3);
imshow(implant_raw, []);
title(sprintf('Raw Region Growing\n(%d pixels)', sum(implant_raw(:))), ...
    'FontSize', 12, 'FontWeight', 'bold');

% Subplot 4: After Filling and Largest Component
subplot(2, 3, 4);
imshow(implant_largest, []);
title(sprintf('After Fill + Largest CC\n(%d pixels)', sum(implant_largest(:))), ...
    'FontSize', 12, 'FontWeight', 'bold');

% Subplot 5: Final Smoothed Mask
subplot(2, 3, 5);
imshow(implant_smooth, []);
title(sprintf('Final Segmented Mask\n(%d pixels)', sum(implant_smooth(:))), ...
    'FontSize', 12, 'FontWeight', 'bold');

% Subplot 6: Final Result - Boundary Overlay
subplot(2, 3, 6);
imshow(f, []);
hold on;
if ~isempty(boundary)
    plot(boundary(:,2), boundary(:,1), 'r-', 'LineWidth', 2);
    plot(seed(2), seed(1), 'g*', 'MarkerSize', 10, 'LineWidth', 2);
end
hold off;
title('Original with Implant Boundary', 'FontSize', 12, 'FontWeight', 'bold');
legend('Boundary', 'Seed', 'Location', 'southoutside');

sgtitle('Breast Implant Segmentation Pipeline', 'FontSize', 14, 'FontWeight', 'bold');

%% Step 10: Create final result figures (as specified in original)
% Figure 1: Original image
figure;
imshow(f, []);
title('Original Image: Breast Implant MRI', 'FontSize', 12);

% Figure 2: Mask of the implant
figure;
imshow(implant_smooth, []);
title('Segmented Breast Implant Mask', 'FontSize', 12);

% Figure 3: Original with boundary overlay
figure;
imshow(f, []);
hold on;
if ~isempty(boundary)
    plot(boundary(:,2), boundary(:,1), 'r-', 'LineWidth', 2);
end
hold off;
title('Breast Implant Boundary Overlay', 'FontSize', 12);

%% Step 11: Calculate and display metrics
implant_area = sum(implant_smooth(:));
implant_percentage = 100 * implant_area / (rows * cols);

fprintf('\n=== Segmentation Summary ===\n');
fprintf('Image dimensions: %d x %d\n', rows, cols);
fprintf('Implant area: %d pixels (%.2f%% of image)\n', ...
    implant_area, implant_percentage);
fprintf('Boundary length: %d points\n', length(boundary));
fprintf('Seed point: (%d, %d)\n', seed(1), seed(2));

%% ============= Region Growing with Local Criterion Function =============
function mask = region_grow_local(img, seed, global_thresh, local_thresh)
    % REGION_GROW_LOCAL - Region growing with both global and local criteria
    % 
    % Inputs:
    %   img - Input image (2D)
    %   seed - Seed point [row, col]
    %   global_thresh - Maximum allowed difference from seed value
    %   local_thresh - Maximum allowed difference from local grown mean
    %
    % Output:
    %   mask - Binary mask of grown region
    
    [rows, cols] = size(img);
    mask = false(rows, cols);
    
    % Initialize with seed
    mask(seed(1), seed(2)) = true;
    seed_val = img(seed(1), seed(2));
    
    % Initialize BFS queue
    queue = [seed(1), seed(2)];
    queue_ptr = 1;  % Pointer for efficient queue processing
    
    % 8-connected neighborhood offsets
    offsets = [-1, -1; -1, 0; -1, 1; ...
                0, -1;  0, 1; ...
                1, -1;  1, 0;  1, 1];
    
    % Local window size for computing local mean
    window_size = 7;
    half_win = floor(window_size / 2);
    
    % Progress tracking
    processed_pixels = 0;
    fprintf('Region growing in progress...\n');
    
    while queue_ptr <= size(queue, 1)
        current = queue(queue_ptr, :);
        queue_ptr = queue_ptr + 1;
        processed_pixels = processed_pixels + 1;
        
        % Display progress every 1000 pixels
        if mod(processed_pixels, 1000) == 0
            fprintf('  Processed %d pixels, queue size: %d\n', ...
                processed_pixels, size(queue, 1) - queue_ptr + 1);
        end
        
        % Check all 8 neighbors
        for n = 1:size(offsets, 1)
            nr = current(1) + offsets(n, 1);
            nc = current(2) + offsets(n, 2);
            
            % Check bounds
            if nr < 1 || nr > rows || nc < 1 || nc > cols
                continue;
            end
            
            % Skip if already in mask
            if mask(nr, nc)
                continue;
            end
            
            pixel_val = img(nr, nc);
            
            % Criterion 1: Global similarity to seed
            global_ok = abs(pixel_val - seed_val) <= global_thresh;
            
            if ~global_ok
                continue;
            end
            
            % Criterion 2: Local similarity to grown neighbors
            % Define local window around the candidate pixel
            r1 = max(1, nr - half_win);
            r2 = min(rows, nr + half_win);
            c1 = max(1, nc - half_win);
            c2 = min(cols, nc + half_win);
            
            % Find already-grown pixels in local window
            local_mask = mask(r1:r2, c1:c2);
            
            if any(local_mask(:))
                % Compute mean of grown pixels in local window
                local_img = img(r1:r2, c1:c2);
                local_mean = sum(local_img(local_mask)) / sum(local_mask(:));
                local_ok = abs(pixel_val - local_mean) <= local_thresh;
            else
                % No local information yet, rely on global criterion
                local_ok = true;
            end
            
            % Add pixel if both criteria are satisfied
            if local_ok
                mask(nr, nc) = true;
                queue = [queue; nr, nc];
            end
        end
    end
    
    fprintf('Region growing complete. Total pixels: %d\n', sum(mask(:)));
end
