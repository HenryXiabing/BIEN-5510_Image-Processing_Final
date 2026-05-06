%% Problem 1 - Point Detection using Laplacian Kernel
% DIPWM3 Project 11.1
% Task: Find the embedded single bright point in the sphere image

clear; clc; close all;

fw = imread('sphere-with-embedded-white-point.tif');
figure; imshow(fw); drawnow;
[yres, xres] = size(fw);
% From Example 11.1
w = [-1 -1 -1; -1 8 -1; -1 -1 -1];
gw = abs(imfilter(double(fw), w));
T = max(gw(:));
gw = gw >= T;
% Enlarge the point to make it easier to see
gw1 = imdilate( gw, ones(3));
figure; imshow(gw1);drawnow;
% Find coordinates of the max point
L1 = gw(1:xres, 1:yres);
[max_val, max_idx] = max(L1(:)); % Find max value and its index
[max_row, max_col] = ind2sub(size(L1), max_idx); % Convert index to row and column
disp(['max row = ', num2str(max_row), ', max column = ', num2str(max_col)]);
