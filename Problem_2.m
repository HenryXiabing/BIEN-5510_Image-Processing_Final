%% Problem 2 - Sobel Edge Detection on a White Square
% DIPWM3 Project 11.2(a)
% Generate 512x512 black image with 256x256 white square at center,
% compute Sobel gradient magnitude, and analyze perimeter values.

clear; clc; close all;

%% Step 1: Generate the image (512x512 black background with white square)
img_size = 512;
square_size = 256;

% Create black image
f = zeros(img_size, img_size, 'uint8');

% Calculate starting indices to center the square
start_idx = (img_size - square_size) / 2 + 1;  % = 129
end_idx = start_idx + square_size - 1;          % = 384

% Set the central square to white (255)
f(start_idx:end_idx, start_idx:end_idx) = 255;

%% Step 2: Compute gradients using Sobel kernels
% Convert to double for gradient computation
f_double = double(f);

% Define Sobel kernels
Sx = [-1 0 1; -2 0 2; -1 0 1];   % Horizontal gradient (detects vertical edges)
Sy = [-1 -2 -1; 0 0 0; 1 2 1];   % Vertical gradient (detects horizontal edges)

% Convolve with Sobel kernels
Gx = conv2(f_double, Sx, 'same');
Gy = conv2(f_double, Sy, 'same');

% Compute gradient magnitude
Gmag = sqrt(Gx.^2 + Gy.^2);

%% Step 3: Analyze perimeter values
% Extract the four edges of the square
% Top edge: row = start_idx, col from start_idx to end_idx
top_edge = Gmag(start_idx, start_idx:end_idx);

% Bottom edge: row = end_idx, col from start_idx to end_idx
bottom_edge = Gmag(end_idx, start_idx:end_idx);

% Left edge: col = start_idx, row from start_idx to end_idx
left_edge = Gmag(start_idx:end_idx, start_idx);

% Right edge: col = end_idx, row from start_idx to end_idx
right_edge = Gmag(start_idx:end_idx, end_idx);

% Combine all edge values
all_edges = [top_edge(:); bottom_edge(:); left_edge(:); right_edge(:)];

% Check if all perimeter values are the same
min_perimeter = min(all_edges);
max_perimeter = max(all_edges);
unique_values = unique(all_edges);

fprintf('=== Perimeter Analysis ===\n');
fprintf('Number of unique gradient magnitude values along perimeter: %d\n', ...
        length(unique_values));
fprintf('Minimum perimeter value: %.2f\n', min_perimeter);
fprintf('Maximum perimeter value: %.2f\n', max_perimeter);
fprintf('Are all perimeter values the same? %s\n', ...
        string(~(max_perimeter > min_perimeter)));

% Examine corner vs. edge-center values
% Four corners
corner_values = [Gmag(start_idx, start_idx);    % Top-left
                 Gmag(start_idx, end_idx);       % Top-right
                 Gmag(end_idx, start_idx);       % Bottom-left
                 Gmag(end_idx, end_idx)];        % Bottom-right

% Edge centers
center_x = round((start_idx + end_idx) / 2);
center_y = center_x;
edge_center_values = [Gmag(start_idx, center_x);  % Top edge center
                      Gmag(end_idx, center_x);     % Bottom edge center
                      Gmag(center_y, start_idx);   % Left edge center
                      Gmag(center_y, end_idx)];    % Right edge center

fprintf('\n=== Corner vs Edge-Center Values ===\n');
fprintf('Corner values (TL, TR, BL, BR): %.2f, %.2f, %.2f, %.2f\n', ...
        corner_values);
fprintf('Edge-center values (T, B, L, R): %.2f, %.2f, %.2f, %.2f\n', ...
        edge_center_values);
fprintf('Ratio (corner/edge-center): %.2f\n', ...
        mean(corner_values) / mean(edge_center_values));

%% Step 4: Display results

% Figure 1: Original image
figure;
imshow(f, []);
title('Original Image: 512×512 with 256×256 White Square at Center');

% Figure 2: Sobel filtered images
figure;
% Subplot 2(a): Gradient in x-direction
subplot(1,3,1);
imshow(abs(Gx), []);
title('|G_x| (Sobel Horizontal Gradient)');
colorbar;

% Subplot 2(b): Gradient in y-direction
subplot(1,3,2);
imshow(abs(Gy), []);
title('|G_y| (Sobel Vertical Gradient)');
colorbar;

% Subplot 2(c): Gradient magnitude
subplot(1,3,3);
imshow(Gmag, []);
title('Gradient Magnitude sqrt(G_x^2 + G_y^2)');
colorbar;

% Figure 3: Confirm corner points have different values
figure;

% Subplot 3(a): Gradient magnitude with zoomed region of interest
subplot(1,2,1);
imshow(Gmag, []);
title('Gradient Magnitude with Corner Analysis');
hold on;
% Mark corners with red circles
plot(start_idx, start_idx, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
plot(start_idx, end_idx, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
plot(end_idx, start_idx, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
plot(end_idx, end_idx, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
% Mark edge centers with green circles
plot(start_idx, center_x, 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(end_idx, center_x, 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(center_y, start_idx, 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(center_y, end_idx, 'go', 'MarkerSize', 10, 'LineWidth', 2);
legend('Corners', 'Edge Centers', 'Location', 'best');
hold off;

% Subplot 3(b): Profile along a horizontal line through top edge
% showing corner vs. edge-center difference
subplot(1,2,2);
x_coords = start_idx:end_idx;
y_top = Gmag(start_idx, x_coords);
plot(x_coords, y_top, 'b-', 'LineWidth', 1.5);
hold on;
% Mark corners on this profile
plot(start_idx, Gmag(start_idx, start_idx), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
plot(end_idx, Gmag(start_idx, end_idx), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
% Mark edge center on this profile
plot(center_x, Gmag(start_idx, center_x), 'go', 'MarkerSize', 8, 'LineWidth', 2);
xlabel('Column Index');
ylabel('Gradient Magnitude');
title('Gradient Magnitude Profile Along Top Edge');
legend('Profile', 'Corners', 'Edge Center', 'Location', 'best');
grid on;
hold off;

% Overlay gradient magnitude values as text near corners
figure;
imshow(Gmag, []);
title('Gradient Magnitude Values at Key Points (Corners vs Edges)');
hold on;
% Annotate corners with values
text(start_idx-15, start_idx-15, sprintf('%.1f', Gmag(start_idx, start_idx)), ...
     'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold');
text(start_idx-15, end_idx+15, sprintf('%.1f', Gmag(start_idx, end_idx)), ...
     'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold');
text(end_idx+15, start_idx-15, sprintf('%.1f', Gmag(end_idx, start_idx)), ...
     'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold');
text(end_idx+15, end_idx+15, sprintf('%.1f', Gmag(end_idx, end_idx)), ...
     'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold');
% Annotate edge centers with values
text(center_x-15, start_idx-15, sprintf('%.1f', Gmag(start_idx, center_x)), ...
     'Color', 'green', 'FontSize', 10, 'FontWeight', 'bold');
text(center_x-15, end_idx+15, sprintf('%.1f', Gmag(end_idx, center_x)), ...
     'Color', 'green', 'FontSize', 10, 'FontWeight', 'bold');
text(start_idx-15, center_y-15, sprintf('%.1f', Gmag(center_y, start_idx)), ...
     'Color', 'green', 'FontSize', 10, 'FontWeight', 'bold');
text(end_idx+15, center_y-15, sprintf('%.1f', Gmag(center_y, end_idx)), ...
     'Color', 'green', 'FontSize', 10, 'FontWeight', 'bold');
hold off;