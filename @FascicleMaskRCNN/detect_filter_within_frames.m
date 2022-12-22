function detect_filter_within_frames(obj, frames, dataset, modelIter)
[obj.allmasksSparse, obj.alllabels, obj.allscores, obj.allboxes] = deal(cell(length(frames), 1));
for iframe = 1:length(frames)
    frame = frames(iframe);

    % apply segmentation
    scoreThresh = 0.1;
    [masks, labels, scores, boxes, imTest] = obj.display_result([], dataset, modelIter, frame, scoreThresh);
    inds = labels == 'fascicle';
    masks = masks(:, :, inds);
    scores = scores(inds);
    boxes = boxes(inds, :);
    labels = labels(inds);

    N = size(masks, 3);

    % form the Jaccard matrix
    J = zeros(N, N, 'double');
    for imask = 1:N
        mask = masks(:, :, imask);
        for imask2 = imask+1:N
            mask2 = masks(:, :, imask2);
            J(imask, imask2) = jaccard(mask, mask2);
        end
        fprintf(1, 'frame %d, %d of %d\n', frame, imask, N);
    end
    J = J + J' + eye(size(J));

    % filter the masks
    jthresh = 0.1;
    keepInds = [];
    for imask = 1:N
        inds = find(J(imask, :) > jthresh);
        [mv, mi] = max(scores(inds));
        keepInds = [keepInds inds(mi)];
    end
    maskInds = unique(keepInds);
        
    obj.allmasksSparse{iframe} = cell(1, length(maskInds));
    for jj = 1:length(maskInds)
        obj.allmasksSparse{iframe}{jj} = sparse(masks(:, :, jj));
    end
    obj.alllabels{iframe} = labels(maskInds);
    obj.allscores{iframe} = scores(maskInds);
    obj.allboxes{iframe} = boxes(maskInds, :);
    fprintf(1, '%d of %d\n', iframe, length(frames))

    % allmasks = [allmasks; {masks(:, :, maskInds)}];
    figure(4);imagesc(sum(masks(:, :, maskInds), 3));
end