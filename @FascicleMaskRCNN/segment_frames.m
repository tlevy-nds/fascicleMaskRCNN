function [masks, labels, scores, boxes] = segment_frames(obj, frames, offset)

if ~exist('offset', 'var') || isempty(offset)
    % because RoiAlign has a [14 14] grid issue, try multiple offsets of the image
    offset = [0 0];
end

if isequal(obj.cropSize, [2000 2000])
    scoreThresh = 0.01;
elseif isequal(obj.cropSize, [750 750])
    scoreThresh = 0.1;
end

[masks, labels, scores, boxes] = deal(cell(length(frames), 1));
for iframe = 1:length(frames)
    frame = frames(iframe);
    imgName = obj.get_image_name(frame);
    ind = find(obj.allframes == frame);
    assert(~isempty(obj.locations) && ~isempty(obj.locations{ind}));
    
    if ~iscellstr(imgName)
        imgName = {imgName};
    end

    masks_lg2 = [];
    for iimg = 1:length(imgName)
        imTest = imread(imgName{iimg});
        imProc = obj.preprocess_image(imTest);

        imProc = circshift(imProc, [offset 0]);

        [masks_, labels_, scores_, boxes_] = segmentObjects(obj.net, imProc, ...
            'Threshold', scoreThresh, ...
            'MaxSize', [200 200], ...
            'ExecutionEnvironment', 'auto');
        inds = ismember(labels_, {'fascicle'});

        % Only keep fascicles
        masks_ = masks_(:, :, inds);
        labels{iframe} = [labels{iframe}; labels_(inds)];
        scores{iframe} = [scores{iframe}; scores_(inds)];
        
        bbox = obj.locations{ind}(iimg, :);

        boxes{iframe} = [boxes{iframe}; boxes_(inds, :) + [obj.locations{ind}(iimg, 1:2) - 1, 0, 0]];

        masks_lg = zeros(2000, 2000, size(masks_, 3), 'logical');
        masks_lg(bbox(2) + (0:bbox(4) - 1), bbox(1) + (0:bbox(3) - 1), :) = masks_;
        masks_lg2 = cat(3, masks_lg2, masks_lg);
    end    

    masks{iframe} = arrayfun(@(imask) sparse(masks_lg2(:, :, imask)), 1:size(masks_lg2, 3), 'UniformOutput', false);
    if ~isscalar(frames)
        fprintf(1, 'segmenting frame %d\n', frame);
    end
end
