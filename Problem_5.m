% gabor_segmentation.m -  Image segmentation using Gabor Filtering
% Marquette University
% Fred J. Frigo, Ph.D.
% 
% Image Processing
%
% See https://www.mathworks.com/help/images/texture-segmentation-using-gabor-filters.html
%
A = imread("kobi.png");
A = imresize(A,0.25);
Agray = im2gray(A);
figure; imshow(A); title('Original Image'); drawnow;

imageSize = size(A);
numRows = imageSize(1);
numCols = imageSize(2);

wavelengthMin = 4/sqrt(2);
wavelengthMax = hypot(numRows,numCols);
n = floor(log2(wavelengthMax/wavelengthMin));
wavelength = 2.^(0:(n-2)) * wavelengthMin;

deltaTheta = 45;
orientation = 0:deltaTheta:(180-deltaTheta);

g = gabor(wavelength,orientation);

% Extract Gabor magnitude features from source image.
gabormag = imgaborfilt(Agray,g);

% Post-process the Gabor Magnitude Images into Gabor Features
for i = 1:length(g)
    sigma = 0.5*g(i).Wavelength;
    K = 3;
    gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),K*sigma); 
end

X = 1:numCols;
Y = 1:numRows;
[X,Y] = meshgrid(X,Y);
featureSet = cat(3,gabormag,X);
featureSet = cat(3,featureSet,Y);

numPoints = numRows*numCols;
X = reshape(featureSet,numRows*numCols,[]);

% Normalize the features to be zero mean, unit variance.
X = bsxfun(@minus, X, mean(X));
X = bsxfun(@rdivide,X,std(X));

coeff = pca(X);
feature2DImage = reshape(X*coeff(:,1),numRows,numCols);
figure; imshow(feature2DImage,[]); title('Gabor Features'); drawnow;

L = kmeans(X,2,"Replicates",5);
% Visualize segmentation using label2rgb
L = reshape(L,[numRows numCols]);
figure; imshow(label2rgb(L)); title('Foreground and Background mask');drawnow;

Aseg1 = zeros(size(A),"like",A);
Aseg2 = zeros(size(A),"like",A);
BW = L == 2;
BW = repmat(BW,[1 1 3]);
Aseg1(BW) = A(BW);
Aseg2(~BW) = A(~BW);
figure; montage({Aseg1,Aseg2}); title('Final Images'); drawnow;
