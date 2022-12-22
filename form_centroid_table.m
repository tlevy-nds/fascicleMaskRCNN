function centroidTable = form_centroid_table(masks, labels, frames)

centroidTable = [];
for iframe = 1:length(masks)
    if isempty(labels{iframe}) || isempty(masks{iframe}) || nnz(masks{iframe}{1}) == 0
        temp = [NaN NaN frames(iframe)];
    else
        inds = ismember(labels{iframe}, {'fascicle'});
        masks_ = masks{iframe}(inds);
        s = cellfun(@(x) regionprops(uint8(full(x)), {'Centroid'}), masks_);
        temp = [reshape([s.Centroid], 2, [])' repmat(frames(iframe), [length(masks_) 1])];
    end    
    centroidTable = [centroidTable; table(temp(:, 1), temp(:, 2), temp(:, 3), 'VariableNames', {'x' 'y' 'frame'})];
    if mod(iframe, 100) == 0
        fprintf(1, 'frame %d of %d\n', iframe, length(masks));
    end
end
