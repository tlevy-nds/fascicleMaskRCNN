function Jval = jaccard_with_gt(obj, hgt, frame, keepInds)

assert(isequal(obj.frames, hgt.frames))
iframe = find(obj.frames == frame);

frame = obj.frames(iframe);
gtInd = hgt.frames == frame;

fascicleInds = ismember(obj.labels{iframe}, {'fascicle'});
fmasks = obj.masks{iframe}(fascicleInds);

[Ns, N, firstFrameInd, lastFrameInd] = obj.get_track_frames();

keepInds2 = keepInds(firstFrameInd(iframe):lastFrameInd(iframe));  % keepInds for the current frame

masks = cellfun(@(mask) full(mask), obj.masks{iframe}(keepInds2), 'UniformOutput', false);
masks = cat(3, masks{:});
if nnz(keepInds2) == 0
    masks = zeros(2000, 2000, 0, 'logical');
end

fascicleInds = ismember(hgt.labels{gtInd}, {'fascicle'});
gtmasks = cellfun(@(mask) full(mask), hgt.masks{gtInd}(fascicleInds), 'UniformOutput', false);
gtmasks = cat(3, gtmasks{:});
if nnz(fascicleInds) == 0
    gtmasks = zeros(2000, 2000, 0, 'logical');
end

Jval = zeros(size(masks, 3), size(gtmasks, 3));
for imask1 = 1:size(masks, 3)
    for ignd = 1:size(gtmasks, 3)
        Jval(imask1, ignd) = jaccard(masks(:, :, imask1), gtmasks(:, :, ignd));
    end
end
