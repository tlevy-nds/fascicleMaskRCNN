function remove_dets(obj, iframes, idets)
% TODO validate this method
% will need to rerun tracks_to_graph to regenerate G after modifying tracks and keepInds
% if this code crashes the object could get corrupted.
assert(length(iframes) == length(idets));
for ii = 1:length(iframes)
    iframe = iframes(ii);
    idet = idets(ii);

    assert(idet <= length(obj.masks{iframe}));

    itrack = obj.frameIndAndDet2trackInd(iframe, idet);
    inds = find(obj.centroidTable.frame == obj.frames(iframe));
    assert(itrack == inds(idet));

    if length(obj.masks{iframe}) == 1
        % remove last detection on the frame
        obj.masks{iframe} = {sparse(zeros(2000, 2000, 'logical'))};
        obj.labels{iframe} = categorical(repmat({'fascicle'}, [0 1]), {'fascicle', 'fa on nerve', 'fa off nerve'});
        obj.boxes{iframe} = zeros(0, 4);
        if ~isempty(obj.scores)
            obj.scores{iframe} = [];
        end

        obj.centroidTable.x(itrack) = NaN;
        obj.centroidTable.y(itrack) = NaN;
        % TODO look this up
        obj.tracks
        obj.keepInds
        obj.originalInds
    else
        % remove one of multiple detections on the frame
        obj.masks{iframe}(idet) = [];
        obj.labels{iframe}(idet) = [];
        obj.boxes{iframe}(idet, :) = [];
        if ~isempty(obj.scores)
            obj.scores{iframe}(idet) = [];
        end

        % TODO look this up
        obj.centroidTable(itrack, :) = [];
        obj.tracks(itrack) = [];
        obj.keepInds(itrack) = [];
        obj.originalInds(itrack) = [];
    end    
end
