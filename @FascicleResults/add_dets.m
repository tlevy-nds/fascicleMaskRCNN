function add_dets(obj, iframe, mask, score, track, keep)
% TODO validate this method
indsx = find(any(mask, 1));
indsy = find(any(mask, 2));

s = regionprops(uint8(mask), 'Centroid');

if length(obj.masks{iframe}) == 1 && nnz(obj.masks{iframe}{1}) == 0
    obj.masks{iframe} = {sparse(mask)};
    obj.labes{iframe} = categorical({'fascicle'}, {'fascicle', 'fa on nerve', 'fa off nerve'});    
    obj.boxes{iframe} = [indsx(1), indsy(1), range(indsx) + 1, range(indsy) + 1];
    if ~isempty(obj.scores)
        obj.scores{iframe} = score;
    end
else
    obj.masks{iframe} = [obj.masks{iframe} {sparse(mask)}];
    obj.labes{iframe} = [obj.labes{iframe}; categorical({'fascicle'}, {'fascicle', 'fa on nerve', 'fa off nerve'})];    
    obj.boxes{iframe} = [obj.boxes{iframe}; indsx(1), indsy(1), range(indsx) + 1, range(indsy) + 1];
    if ~isempty(obj.scores)
        obj.scores{iframe} = [obj.scores{iframe}; score];
    end    
end

% TODO look this up
ind = find(obj.centroidTable.frame == obj.frames(iframe), 1, 'last');
obj.centroidTable = [obj.centroidTable(1:ind); ...
    table(s.Centroid(1), s.Centroid(2), obj.frames(iframe), 'VariableNames', {'x' 'y' 'frame'}); ...
    obj.centroidTable(ind + 1:end)];
obj.tracks = [obj.tracks(1:ind); track; obj.tracks(ind + 1:end)];
obj.keepInds = [obj.keepInds(1:ind); keep; obj.keepInds(ind + 1:end)];
obj.originalInds = [obj.originalInds(1:ind); false; obj.originalInds(ind + 1:end)];
