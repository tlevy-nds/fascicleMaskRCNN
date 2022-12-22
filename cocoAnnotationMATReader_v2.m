function  out = cocoAnnotationMATReader_v2(filename, trainImgFolder, bnds)

% Copyright 2020 The MathWorks, Inc.

load(filename, "imageName", "bbox", "label", "masks");

im = imread(strcat(trainImgFolder, filesep(), imageName));
% For grayscale images, simulate RGB images by repeating the intensity
% values for all three color channels

if isa(im, 'uint16')
    im = uint8(round(255 * double(im) / 55000));
end

if size(im,3) == 1    
    im = repmat(im, [1 1 3]);
end

im = im(bnds(1):bnds(2), bnds(3):bnds(4), :);

out{1} = im;
out{2} = bbox;
out{3} = label;
out{4} = masks;
