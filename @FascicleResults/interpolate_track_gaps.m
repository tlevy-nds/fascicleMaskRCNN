function [tracks, keepInds, originalInds] = interpolate_track_gaps(obj, tracks, keepInds)
% use interpolate_gaps when there is a missing detection within a track
% augment the tracks and keepInds arrays too

assert(size(obj.centroidTable, 1) == length(tracks));
assert(issorted(obj.centroidTable.frame));
trackIds1 = unique(tracks(tracks > 0));
originalInds = true(size(keepInds));

totalNewFrames = 0;
for itrack = 1:length(trackIds1)
    curtrack = trackIds1(itrack);
    trackInds = find(tracks == curtrack);
    myframes = obj.centroidTable.frame(trackInds);
    dframes = diff(myframes);
    % assert(nnz(dframes == 0) == 0);  % should not be multiple detections on the same frame and same track
    gapInds = find(dframes > 1 & [dframes(2:end); 1] ~= 0 & [1; dframes(1:end - 1)] ~= 0);
    for igap = 1:length(gapInds)
        gapInd = gapInds(igap);
        
        imask1 = find(tracks(obj.centroidTable.frame == myframes(gapInd)) == curtrack);
        imask2 = find(tracks(obj.centroidTable.frame == myframes(gapInd + 1)) == curtrack);  

        myInd1 = obj.centroidTable.frame == myframes(gapInd) & tracks == curtrack;
        myInd2 = obj.centroidTable.frame == myframes(gapInd + 1) & tracks == curtrack;
        assert(keepInds(myInd1) == keepInds(myInd2));
        assert(tracks(myInd1) == tracks(myInd2));

        newframes = myframes(gapInd) + 1:myframes(gapInd + 1) - 1;
%         fprintf(1, '%d new frames in track %d\n', length(newframes), curtrack);
%         totalNewFrames = totalNewFrames + length(newframes);
        for iframe = 1:length(newframes)
            newframe = newframes(iframe);
            ctInd = find(obj.centroidTable.frame == newframe, 1, 'last');

            iframe2 = find(obj.frames == newframe);
            if length(obj.masks{iframe2}) == 1 && nnz(obj.masks{iframe2}{1}) == 0
                tracks = [tracks(1:ctInd - 1); curtrack; tracks(ctInd + 1:end)];            
                keepInds = [keepInds(1:ctInd - 1); keepInds(myInd1); keepInds(ctInd + 1:end)];
                originalInds = [originalInds(1:ctInd - 1); false; originalInds(ctInd + 1:end)];
            else
                tracks = [tracks(1:ctInd); curtrack; tracks(ctInd + 1:end)];            
                keepInds = [keepInds(1:ctInd); keepInds(myInd1); keepInds(ctInd + 1:end)];
                originalInds = [originalInds(1:ctInd); false; originalInds(ctInd + 1:end)];
            end            
        end

        % modifies obj.masks, obj.labels, obj.boxes, obj.scores, and obj.centrodTable
        obj.interpolate_gaps([imask1, myframes(gapInd), imask2, myframes(gapInd + 1)]);
    end

    fprintf(1, 'track %d of %d\n', itrack, length(trackIds1));
end
% fprintf(1, '%d total new frames\n', totalNewFrames);