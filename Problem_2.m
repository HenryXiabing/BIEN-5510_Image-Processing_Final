%% Problem 2 - Sobel Edge Detection on a White Square
% DIPWM3 Project 11.2(a)
% Generate 512x512 black image with 256x256 white square at center,
% compute Sobel gradient magnitude, and analyze perimeter values.

clear; clc; close all;

f = zeros(512);
f(128:384, 128:384)=1;
figure; imshow(f); drawnow;
% Sobel Filter
wh = fspecial('sobel');
wv = wh';
gx = imfilter(f, wh, 'replicate');
gy = imfilter(f, wv, 'replicate');
G = sqrt( gx.^2 + gy.^2);
figure; imshow(G); drawnow;
% The corner points have larger values than the borders
Gm = G == max(G(:));
% Enlarge the points to make them easier to see
Gmd = imdilate(Gm ,ones(5));
figure; imshow(Gmd); drawnow;
