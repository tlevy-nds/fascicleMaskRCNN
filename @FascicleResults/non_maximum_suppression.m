function non_maximum_suppression(obj, jthresh)
% non maximum suppression is already done in Mask RCNN, but I do it again

if ~exist('jthresh', 'var') || isempty(jthresh)
    jthresh = 0.1;
end

for iframe = 1:length(obj.frames)
    frame = obj.frames(iframe);

    if isempty(obj.masks{iframe})
        fprintf(1, 'non_maximum_suppression encountered zero detections at frame %d\n', frame);
        continue
    end

    masks = cellfun(@(mask) full(mask), obj.masks{iframe}, 'UniformOutput', false);
    masks = cat(3, masks{:});

    N = size(masks, 3);

    % form the Jaccard matrix
    J = zeros(N, N, 'double');
    for imask = 1:N
        mask = masks(:, :, imask);
        for imask2 = (imask + 1):N
            mask2 = masks(:, :, imask2);
            J(imask, imask2) = jaccard(mask, mask2);
        end        
    end
    J = J + J' + eye(size(J));

    % filter the masks    
    if N == 1 && isempty(obj.scores{iframe})
        keepInds = 1;        
    else
        keepInds = [];
        for imask = 1:N
            inds = find(J(imask, :) > jthresh);
            [~, mi] = max(obj.scores{iframe}(inds));
            keepInds = [keepInds inds(mi)];
        end        
    end
    maskInds = unique(keepInds);
    if ~isempty(obj.masks{iframe})
        obj.masks{iframe} = obj.masks{iframe}(maskInds);
    end
    if ~isempty(obj.boxes{iframe})
        obj.boxes{iframe} = obj.boxes{iframe}(maskInds, :); 
    end
    if ~isempty(obj.labels{iframe})
        obj.labels{iframe} = obj.labels{iframe}(maskInds);
    end
    if ~isempty(obj.scores{iframe})        
        obj.scores{iframe} = obj.scores{iframe}(maskInds);
    end

    if ~isscalar(obj.frames)
        fprintf(1, 'frame %d\n', frame);
    end
end
