%% Problem 6 - PCA on Color Image
% DIPWM3 - Principal Component Analysis
% Apply PCA to 'peppers.png' to create 3 principal component images

clear; clc; close all;

%% Step 1: Read the color image
I = imread('peppers.png');

% Display image dimensions
[rows, cols, channels] = size(I);
fprintf('Image size: %d x %d x %d\n', rows, cols, channels);

%% Step 2: Reshape image for PCA
% Convert image from 3D array to 2D matrix
% Each row = one pixel, each column = one color channel (R, G, B)
X = double(reshape(I, rows * cols, channels));

%% Step 3: Perform PCA using MATLAB's pca() function
% coeff  -> 3x3 matrix of principal component coefficients
% score  -> (rows*cols)x3 matrix of principal component scores
% latent -> 3x1 vector of eigenvalues (variances)
[coeff, score, latent] = pca(X);

% Display variance explained by each component
total_var = sum(latent);
fprintf('\nVariance explained by each principal component:\n');
for i = 1:channels
    fprintf('  PC%d: %.2f (%.1f%% of total variance)\n', i, latent(i), 100*latent(i)/total_var);
end

% Display principal component coefficients
fprintf('\nPrincipal component coefficients:\n');
fprintf('  PC1 = %.4f*R + %.4f*G + %.4f*B\n', coeff(1,1), coeff(2,1), coeff(3,1));
fprintf('  PC2 = %.4f*R + %.4f*G + %.4f*B\n', coeff(1,2), coeff(2,2), coeff(3,2));
fprintf('  PC3 = %.4f*R + %.4f*G + %.4f*B\n', coeff(1,3), coeff(2,3), coeff(3,3));

%% Step 4: Alternative approach - Transform using coefficients
% This matches the reference code approach: X * coeff
Itransformed = X * coeff;

% The scores from pca() should be the same as Itransformed
% score should equal X * coeff (centered data * coefficients)

%% Step 5: Reshape principal components into images
Ipc1 = reshape(Itransformed(:,1), rows, cols);
Ipc2 = reshape(Itransformed(:,2), rows, cols);
Ipc3 = reshape(Itransformed(:,3), rows, cols);

% Also reshape scores for comparison
pc1_score = reshape(score(:,1), rows, cols);
pc2_score = reshape(score(:,2), rows, cols);
pc3_score = reshape(score(:,3), rows, cols);

%% Step 6: Display original image
figure('Name', 'Original Image', 'Position', [100, 500, 400, 300]);
imshow(I);
title('Original Image: peppers.png');
drawnow;

%% Step 7: Display PCA component images
figure('Name', 'PCA Components', 'Position', [100, 100, 1000, 330]);

subplot(1,3,1);
imshow(Ipc1, []);
title(sprintf('PCA Image 1 (%.1f%% variance)', 100*latent(1)/total_var));
drawnow;

subplot(1,3,2);
imshow(Ipc2, []);
title(sprintf('PCA Image 2 (%.1f%% variance)', 100*latent(2)/total_var));
drawnow;

subplot(1,3,3);
imshow(Ipc3, []);
title(sprintf('PCA Image 3 (%.1f%% variance)', 100*latent(3)/total_var));
drawnow;

%% Step 8: Create pseudo-color image from PCA components
% Scale each PCA component to 8-bit range [0, 255]
R = im_scale(Ipc1);  % PC1 as Red channel
G = im_scale(Ipc2);  % PC2 as Green channel
B = im_scale(Ipc3);  % PC3 as Blue channel

% Combine into a pseudo-color RGB image
psuedo_color = cat(3, R, G, B);

%% Step 9: Display pseudo-color image
figure('Name', 'Pseudo-Color PCA', 'Position', [550, 500, 400, 300]);
imshow(psuedo_color);
title('Pseudo-Color Image formed from PCA Components');
drawnow;

%% Step 10: Optional - Compare original and PCA reconstruction
% Reconstruct using all components (should match original)
X_reconstructed = Itransformed * coeff';  % Inverse transform
I_reconstructed = reshape(X_reconstructed, rows, cols, channels);
I_reconstructed = uint8(I_reconstructed);

figure('Name', 'Reconstruction Comparison', 'Position', [550, 100, 400, 330]);
subplot(1,2,1);
imshow(I);
title('Original Image');

subplot(1,2,2);
imshow(I_reconstructed);
title('Reconstructed from all PCs');
sgtitle('Perfect Reconstruction Check');

%% Step 11: Display individual channels of pseudo-color image
figure('Name', 'Pseudo-Color Channels', 'Position', [100, 500, 900, 300]);
subplot(1,3,1);
imshow(R, []);
title('PC1 as Red Channel');

subplot(1,3,2);
imshow(G, []);
title('PC2 as Green Channel');

subplot(1,3,3);
imshow(B, []);
title('PC3 as Blue Channel');

sgtitle('Individual Channels of Pseudo-Color PCA Image');

%% Step 12: Additional Analysis - Scree plot
figure('Name', 'Scree Plot');
bar(latent);
title('Scree Plot - Eigenvalues of PCA Components');
xlabel('Principal Component');
ylabel('Eigenvalue (Variance)');
grid on;

% Add percentage labels on bars
for i = 1:length(latent)
    text(i, latent(i) + max(latent)*0.02, ...
         sprintf('%.1f%%', 100*latent(i)/total_var), ...
         'HorizontalAlignment', 'center');
end

%% ================ Helper Function =================
function scaled_image = im_scale(input_image)
% IM_SCALE Scale image to 8-bit range [0, 255]
% Handles both positive and negative values

    % Find minimum value
    input_min = min(min(input_image));
    
    % Shift to make all values non-negative
    if input_min < 0
        input_image = input_image + abs(input_min);
    else
        input_image = input_image - input_min;  % Shift to start from 0
    end
    
    % Find maximum value after shifting
    input_max = max(max(input_image));
    
    % Avoid division by zero
    if input_max == 0.0
        input_max = 1.0;
    end
    
    % Scale to [0, 255]
    scale_factor = 255.0 / input_max;
    scaled_image = uint8(input_image * scale_factor);
end
