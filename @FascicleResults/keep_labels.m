function keep_labels(obj, keepLabels)

for iframe = 1:length(obj.frames)    
    inds = ismember(obj.labels{iframe}, keepLabels);    
    obj.masks{iframe} = obj.masks{iframe}(inds);
    if ~isempty(obj.boxes)
        obj.boxes{iframe} = obj.boxes{iframe}(inds, :);
    end
    obj.labels{iframe} = obj.labels{iframe}(inds);
    if ~isempty(obj.scores)
        obj.scores{iframe} = obj.scores{iframe}(inds);
    end
end
