function ax = show_detection_img(obj, ax, frame, imageName, colchan, keepInds, clearflag)

if ~exist('clearflag', 'var') || isempty(clearflag)
    clearflag = true;
end

if isnumeric(ax) && mod(ax, 1) == 0 && ismember(nargin, [4 5])
    % shift input arguments when ax not specified
    if nargin == 5
        [frame, imageName, colchan, keepInds] = deal(ax, frame, imageName, colchan);
    elseif nargin == 4
        [frame, imageName, colchan] = deal(ax, frame, imageName);
    end
    clearvars('ax');
end

if ~exist('colchan', 'var') || isempty(colchan)
    colchan = 2;  % R (1), G (2), or B (3) color channel
end

% map the frame to an index into obj.frames
iframe = find(obj.frames == frame);

% Just in case there are any masks that have other labels
fascicleInds = ismember(obj.labels{iframe}, {'fascicle'});
if isempty(fascicleInds)
    fmasks = {sparse(zeros(2000, 2000, 'logical'))};
else
    fmasks = obj.masks{iframe}(fascicleInds);    
end

% This code is copied in several functions
[Ns, N, firstFrameInd, lastFrameInd] = obj.get_track_frames();

if ~exist('keepInds', 'var') || isempty(keepInds)    
    keepInds = true(N, 1);
end

% indices that are not filtered out for the current frame
if ~isempty(obj.centroidTable)
    assert(length(unique(obj.centroidTable.frame(firstFrameInd(iframe):lastFrameInd(iframe)))) == 1);
end
keepInds2 = keepInds(firstFrameInd(iframe):lastFrameInd(iframe));

% format the masks as 3D arrays
temp = cellfun(@(x) full(x), fmasks(keepInds2), 'UniformOutput', false);
masks = cat(3, temp{:});

% do the same for the filtered out masks
temp = cellfun(@(x) full(x), fmasks(~keepInds2), 'UniformOutput', false);
masks2 = cat(3, temp{:});

% filtered out and kept for numbering
temp = cellfun(@(x) full(x), fmasks, 'UniformOutput', false);
masks3 = cat(3, temp{:});

% load and format the image
if ~clearflag && exist('ax', 'var') && isvalid(ax)
    him = findobj(ax, 'Type', 'Image');
    A = him.CData;
else
    A = imread(imageName);
    if isa(A, 'uint16')
        A = uint8(255 * double(A) / (2^16 - 1));
    end
    if size(A, 3) == 1
        A = repmat(A, [1 1 3]);
    end
end

% modify the color channel on the image
% col = zeros(length(keepInds2), 3);
% cm = parula(2);
% col(keepInds2, :) = repmat(cm(1, :), [nnz(keepInds2) 1]);
% col(~keepInds2, :) = repmat(cm(2, :), [nnz(~keepInds2) 1]);
% A2 = insertObjectMask(A, masks3, 'Color', col, 'Opacity', 0.6, 'LineColor', 'yellow');
% figure;ax = gca();imagesc(A2);title(ax, sprintf('frame %d', frame));

temp = A(:, :, colchan);
inds = max(masks, [], 3);
inds2 = max(masks2, [], 3);
mysum = sum(masks, 3) - 1;
temp(inds) = 128 + min(128, 32 * mysum(inds));  % overlapping masks
temp(inds2) = 32;                               % filtered out masks
A(:, :, colchan) = temp;

if ~exist('ax', 'var') || isempty(ax) || ~isvalid(ax)
    figure(); ax = gca();
    imagesc(ax, A);
else
    him = findobj(ax, 'Type', 'Image');
    him.CData = A;
end
title(ax, sprintf('frame %d', frame));

% label each mask for interpretation of jaccard_with_gt
delete(findobj(ax, 'Type', 'Text'));
for imask = 1:size(masks3, 3)
    s = regionprops(uint8(masks3(:, :, imask)), {'Centroid'});
    if ~isempty(s)
        text(ax, s.Centroid(1), s.Centroid(2), num2str(imask), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
end
