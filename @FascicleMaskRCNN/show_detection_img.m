function show_detection_img(obj, frame, masks, colchan)
% Would this be better as a method of FascicleResults and have imageName as an input argument?

if ~exist('colchan', 'var') || isempty(colchan)
    colchan = 2;
end

if iscell(masks)
    temp = cellfun(@(x) full(x), masks, 'UniformOutput', false);
    masks = cat(3, temp{:});
end

imgName = obj.get_image_name(frame);
A = imread(imgName);
if isa(A, 'uint16')
    A = uint8(255 * double(A) / (2^16 - 1));
end
if size(A, 3) == 1
    A = repmat(A, [1 1 3]);
end
temp = A(:, :, colchan);
temp(max(masks, [], 3)) = 128;
A(:, :, colchan) = temp;
figure;imagesc(A);
