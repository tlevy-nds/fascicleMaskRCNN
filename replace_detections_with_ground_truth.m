function hr = replace_detections_with_ground_truth(hgt, gndtruthframes, name, frames, masks, labels, scores, boxes, mytable)

gndtruthframes = gndtruthframes(ismember(gndtruthframes, frames));  % The last ground truth frame could be excluded

iframes = find(ismember(frames, gndtruthframes));
igtframes = find(ismember(hgt.frames, gndtruthframes));
assert(length(iframes) == length(igtframes));

% make sure that mytable contains NaNs for frames with no detections
ptrTable = 1;
for iframe = 1:length(frames)
    curFrame = frames(iframe);
    while ptrTable < length(mytable.frame) && mytable.frame(ptrTable) < curFrame
        ptrTable = ptrTable + 1;
    end
    if ptrTable == length(mytable.frame) && mytable.frame(ptrTable) < curFrame || mytable.frame(ptrTable) > curFrame        
        newEntry = table(NaN, NaN, curFrame, 'VariableNames', {'x' 'y' 'frame'});
        mytable = [mytable(1:ptrTable - 1, :); newEntry; mytable(ptrTable:end, :)];
        ptrTable = ptrTable + 1;
    end
end

% replace detection with ground truth frames
for ii = 1:length(iframes)
    iframe = iframes(ii);
    igtframe = igtframes(ii);

    masks{iframe} = hgt.masks{igtframe};
    assert(all(ismember(hgt.labels{igtframe}, {'fascicle'})));
    labels{iframe} = hgt.labels{igtframe};
    if isempty(hgt.scores)
        scores{iframe} = ones(length(hgt.masks{iframe}), 1);
    else
        scores{iframe} = hgt.scores{igtframe};
    end
    boxes{iframe} = hgt.boxes{igtframe};

    inds1 = find(mytable.frame == frames(iframe));
    inds2 = hgt.centroidTable.frame == frames(iframe);
    mytable = [mytable(1:inds1(1) - 1, :); hgt.centroidTable(inds2, :); mytable(inds1(end) + 1:end, :)];
end

% instantiate a FascicleResults object
hr = FascicleResults(name, frames, masks, boxes, labels, scores, mytable);
