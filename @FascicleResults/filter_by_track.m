function keepInds = filter_by_track(obj, tracks, minTrackLength, gndtruthframes, plotflag)

if ~exist('minTrackLength', 'var') || isempty(minTrackLength)
    minTrackLength = 30;
end
if ~exist('plotflag', 'var') || isempty(plotflag)
    plotflag = false;
end

% get the tracks that contain ground truth
[~, ~, firstFrameInd, lastFrameInd] = obj.get_track_frames();
gndTruthFrameInds = zeros(max(tracks), 1, 'logical');
for iframe = 1:length(gndtruthframes)
    iframe2 = obj.frames == gndtruthframes(iframe);
    inds = firstFrameInd(iframe2):lastFrameInd(iframe2);
    possibleTracks = tracks(inds);    
    gndTruthFrameInds(possibleTracks(possibleTracks ~= -1)) = true;    
end

inds = find(histcounts(tracks, .5:1:max(tracks) + .5) > minTrackLength | reshape(gndTruthFrameInds, 1, []));
inds = [-1 inds];
keepInds = ismember(tracks, inds(2:end)) | ismember(obj.centroidTable.frame, gndtruthframes);

% keep all gndTruthFrameInds that are not part of tracks too
if plotflag
    markerSizes = 12 + zeros(size(obj.centroidTable, 1), 1);
    markerSizes(~keepInds) = 4;
    tracks2 = tracks;
    tracks2(~ismember(tracks2, inds(2:end))) = -1;
    figure(); hs = scatter3(obj.centroidTable.x, obj.centroidTable.y, obj.centroidTable.frame, markerSizes, tracks2, 'filled');
    cm = zeros(max(tracks2) + 2, 3);
    cm(3:max(tracks2)+2, :) = jet(max(tracks2));
    colormap(cm);    

    figure(); scatter3(obj.centroidTable.x(keepInds), obj.centroidTable.y(keepInds), obj.centroidTable.frame(keepInds), 12, tracks(keepInds), 'filled');
end
