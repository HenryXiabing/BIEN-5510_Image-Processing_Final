%% Problem 1 - Point Detection using Laplacian Kernel
% DIPWM3 Project 11.1
% Task: Find the embedded single bright point in the sphere image

clear; clc; close all;

%% Step 1: Read the original image
f = imread('sphere-with-embedded-white-point.tif');

% Convert to double for convolution operations
f_double = double(f);

%% Step 2: Apply Laplacian kernel
% Define a 3x3 Laplacian kernel (center-positive, sum = 0)
laplacian_kernel = [0  1  0;
                    1 -4  1;
                    0  1  0];

% Convolve the image with the Laplacian kernel
% 'same' option outputs array of same size as input
laplacian_response = conv2(f_double, laplacian_kernel, 'same');

%% Step 3: Thresholding to locate the point
% The isolated bright point will produce a strong negative response
% (dark point on bright background) after Laplacian filtering.
% We take the absolute value to capture both positive and negative peaks.
abs_response = abs(laplacian_response);

% Find the maximum absolute response value
max_response = max(abs_response(:));

% Set threshold as a fraction of the maximum response
% Adjust threshold_factor if needed (e.g., 0.5 to 0.9)
threshold_factor = 0.7;
threshold = threshold_factor * max_response;

% Create binary mask where response exceeds threshold
point_mask = abs_response >= threshold;

%% Step 4: Verify that only a single point is found
% Find the coordinates of detected points
[row, col] = find(point_mask);
num_points = length(row);

fprintf('Number of detected points: %d\n', num_points);

if num_points == 1
    fprintf('SUCCESS: Single point detected at (row, col) = (%d, %d)\n', ...
            row(1), col(1));
elseif num_points == 0
    fprintf('WARNING: No point detected. Try lowering the threshold.\n');
else
    fprintf('WARNING: %d points detected. Try adjusting the threshold.\n', ...
            num_points);
    % If multiple clustered points, compute centroid
    centroid_row = round(mean(row));
    centroid_col = round(mean(col));
    fprintf('Using centroid at (row, col) = (%d, %d)\n', ...
            centroid_row, centroid_col);
end

%% Step 5: Display results
% Figure 1: Original image
figure;
imshow(f, []);
title('Original Image: sphere-with-embedded-white-point.tif');

% Figure 2: Detected point marked on the image
figure;
imshow(f, []);
hold on;
if num_points >= 1
    % If single point, mark it; if multiple, mark centroid
    if num_points == 1
        plot(col, row, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
    else
        plot(centroid_col, centroid_row, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
    end
end
title('Detected Single Point (marked in red)');
hold off;

% Figure 3 (optional): Laplacian response for visual verification
figure;
subplot(1,2,1);
imshow(laplacian_response, []);
title('Laplacian Filtered Response');
subplot(1,2,2);
imshow(point_mask, []);
title('Binary Mask After Thresholding');