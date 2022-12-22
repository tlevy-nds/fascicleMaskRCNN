function insert_empty_masks(obj)

emptyFrames = [];
for iframe = 1:length(obj.frames)
    frame = obj.frames(iframe);
    if isempty(obj.masks{iframe})
        obj.masks{iframe} = {sparse(zeros(2000, 2000, 'logical'))};
        emptyFrames = [emptyFrames frame];
    end    
end

if isempty(obj.centroidTable)
    return
end

missingFrames = setdiff(obj.frames, unique(obj.centroidTable.frame));
if isempty(missingFrames)
    return
end
% assert((isempty(emptyFrames) && isempty(missingFrames)) || isequal(emptyFrames, missingFrames));

assert(obj.centroidTable.frame(1) == obj.frames(1));
assert(obj.centroidTable.frame(end) == obj.frames(end));
inds = find(obj.centroidTable.frame(2:end) - obj.centroidTable.frame(1:end - 1) > 1);
mytable2 = [];
for ii = 1:length(inds)    
    if ii == 1
        inds1 = 1:inds(ii);
    else
        inds1 = inds(ii - 1) + 1:inds(ii);
    end
    mytable2 = [mytable2; obj.centroidTable(inds1, :)];

    missingFrames = (obj.centroidTable.frame(inds(ii)) + 1:obj.centroidTable.frame(inds(ii) + 1) - 1)';
    assert(~isempty(missingFrames));
    mytable2 = [mytable2; table(NaN(length(missingFrames), 1), NaN(length(missingFrames), 1), missingFrames, ...
        'VariableNames', {'x' 'y' 'frame'})];
end
if ~isempty(inds)
    inds1 = inds(ii) + 1:size(obj.centroidTable, 1);
    mytable2 = [mytable2; obj.centroidTable(inds1, :)];
    assert(isempty(setdiff(obj.frames, unique(mytable2.frame))));
    obj.centroidTable = mytable2;
end
