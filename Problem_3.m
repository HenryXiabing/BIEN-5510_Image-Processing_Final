%% Problem 3 - Region Growing for Dental Fillings Extraction
% DIPWM3 Project 11.7(a)
% Extract the two bright fillings in upper and lower molars

clear; clc; close all;

%% Step 1: Read the image
f = imread('dentalXray.tif');

% Convert to double for processing
f_double = double(f);

%% Step 2: Use the suggested seed points from the prompt
% The prompt suggests using these coordinates for the seeds
tolerance = 20; % default is 32 for grayscale, using 20 as suggested

% Extract upper filling using grayconnected (built-in function)
top_filling = grayconnected(f, 250, 400, tolerance);

% Extract lower filling using grayconnected (built-in function)  
bot_filling = grayconnected(f, 460, 400, tolerance);

%% Step 3: Display results using built-in function
figure;
subplot(2,2,1);
imshow(f);
title('Original Dental X-ray Image');

subplot(2,2,2);
imshow(top_filling);
title('Upper Filling (Built-in grayconnected)');

subplot(2,2,3);
imshow(bot_filling);
title('Lower Filling (Built-in grayconnected)');

subplot(2,2,4);
combined_filling = top_filling | bot_filling;
imshow(combined_filling);
title('Combined Fillings');

%% Step 4: Compare with custom region growing implementation
% Parameters for custom region growing
threshold_T = 20; % Matching the tolerance used above

% Define seed points based on the coordinates from grayconnected
seed_top = [250, 400]; % [row, col] for upper filling
seed_bot = [460, 400]; % [row, col] for lower filling

fprintf('Seed 1 (Upper filling): row = %d, col = %d, intensity = %.1f\n', ...
        seed_top(1), seed_top(2), f_double(seed_top(1), seed_top(2)));
fprintf('Seed 2 (Lower filling): row = %d, col = %d, intensity = %.1f\n', ...
        seed_bot(1), seed_bot(2), f_double(seed_bot(1), seed_bot(2)));

% Region growing using custom function
mask_top = region_grow_improved(f_double, seed_top, threshold_T);
mask_bot = region_grow_improved(f_double, seed_bot, threshold_T);

%% Step 5: Display custom implementation results
figure;
subplot(2,3,1);
imshow(f);
hold on;
plot(seed_top(2), seed_top(1), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
plot(seed_bot(2), seed_bot(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);
title('Original with Seed Points');
legend('Upper Seed', 'Lower Seed');
hold off;

subplot(2,3,2);
imshow(mask_top);
title('Custom: Upper Filling');

subplot(2,3,3);
imshow(mask_bot);
title('Custom: Lower Filling');

subplot(2,3,4);
% Show difference between built-in and custom for upper filling
diff_top = xor(top_filling, mask_top);
imshow(diff_top);
title('Difference: Upper Filling');

subplot(2,3,5);
% Show difference between built-in and custom for lower filling
diff_bot = xor(bot_filling, mask_bot);
imshow(diff_bot);
title('Difference: Lower Filling');

subplot(2,3,6);
% Overlay boundaries on original image
imshow(f);
hold on;
boundaries_top = bwboundaries(mask_top, 'noholes');
boundaries_bot = bwboundaries(mask_bot, 'noholes');
for k = 1:length(boundaries_top)
    boundary = boundaries_top{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2);
end
for k = 1:length(boundaries_bot)
    boundary = boundaries_bot{k};
    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
end
title('Extracted Fillings Overlay');
legend('Upper Filling', 'Lower Filling');
hold off;

%% ================ Improved Region Growing Function =================
function grown_mask = region_grow_improved(image, seed, threshold)
% REGION_GROW_IMPROVED Performs region growing from a single seed point
% using 8-connectivity and BFS approach
%
% Inputs:
%   image     - 2D grayscale image (double)
%   seed      - 1x2 vector [row, col] of seed point
%   threshold - Maximum allowed absolute intensity difference from seed
%
% Output:
%   grown_mask - Binary mask of the grown region

    [rows, cols] = size(image);
    
    % Initialize binary mask (all zeros)
    grown_mask = false(rows, cols);
    
    % Get seed intensity
    seed_intensity = image(seed(1), seed(2));
    
    % Initialize queue for BFS
    % Using cell array for better performance with dynamic sizing
    queue_row = seed(1);
    queue_col = seed(2);
    queue_front = 1;
    queue_back = 1;
    
    % Mark seed as visited
    grown_mask(seed(1), seed(2)) = true;
    
    % Define 8-connected neighborhood offsets
    neighbor_offsets = [-1, -1; -1, 0; -1, 1;
                         0, -1;          0, 1;
                         1, -1;  1, 0;  1, 1];
    
    % Process queue using BFS
    while queue_front <= queue_back
        % Get current pixel from queue
        current_row = queue_row(queue_front);
        current_col = queue_col(queue_front);
        queue_front = queue_front + 1;
        
        % Check all 8 neighbors
        for n = 1:size(neighbor_offsets, 1)
            % Calculate neighbor coordinates
            neighbor_row = current_row + neighbor_offsets(n, 1);
            neighbor_col = current_col + neighbor_offsets(n, 2);
            
            % Check if neighbor is within image boundaries
            if neighbor_row >= 1 && neighbor_row <= rows && ...
               neighbor_col >= 1 && neighbor_col <= cols
                
                % If neighbor hasn't been visited yet
                if ~grown_mask(neighbor_row, neighbor_col)
                    % Calculate intensity difference from seed
                    intensity_diff = abs(image(neighbor_row, neighbor_col) - seed_intensity);
                    
                    % Check if pixel satisfies the similarity criterion
                    if intensity_diff <= threshold
                        % Mark as part of region
                        grown_mask(neighbor_row, neighbor_col) = true;
                        
                        % Add to queue
                        queue_back = queue_back + 1;
                        queue_row(queue_back) = neighbor_row;
                        queue_col(queue_back) = neighbor_col;
                    end
                end
            end
        end
    end
    
    % Optional: Apply morphological closing to fill small gaps
    % grown_mask = imclose(grown_mask, strel('disk', 2));
    
    fprintf('Region grown: %d pixels (%.2f%% of image)\n', ...
            sum(grown_mask(:)), 100*sum(grown_mask(:))/(rows*cols));
end
