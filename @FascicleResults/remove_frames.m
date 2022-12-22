function remove_frames(obj, iframes)
% TODO validate this method
% will need to rerun tracks_to_graph to regenerate G after modifying tracks and keepInds
% if this code crashes the object could get corrupted.
assert(issorted(obj.centroidTable.frame));
for ii = 1:length(iframes)
    iframe = iframes(ii);

    itrack = find(obj.centroidTable.frame == obj.frames(iframe));

    % remove last detection on the frame
    obj.masks{iframe} = {sparse(zeros(2000, 2000, 'logical'))};
    obj.labels{iframe} = categorical(repmat({'fascicle'}, [0 1]), {'fascicle', 'fa on nerve', 'fa off nerve'});
    obj.boxes{iframe} = zeros(0, 4);
    if ~isempty(obj.scores)
        obj.scores{iframe} = [];
    end

    obj.centroidTable = [obj.centroidTable(1:itrack(1) - 1); ...
        table(NaN, NaN, obj.frames(iframe), 'VariableNames', {'x' 'y' 'frame'}); ...
        obj.centroidTable(itrack(end) + 1:end)];
    % TODO look this up
    obj.tracks
    obj.keepInds
    obj.originalInds    
end
