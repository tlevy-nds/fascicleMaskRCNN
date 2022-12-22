function tracks = track_cells(obj, dmax, min_samples, eps_, fthresh, distanceMetric)
% https://github.com/ymzayek/yeastcells-detection-maskrcnn/blob/main/yeastcells/tracking.py
% detections - load('allmasksSparse_human_1000_8500_v2.mat', 'allmasksSparse')
% frames - 1000:8500
% dmax - 5
% min_samples - 3
% eps_ - 0.6

expand = @(x) [x{:}];

if ~exist('fthresh', 'var') || isempty(fthresh)
    fthresh = 2/3;  % for mapping cluster IDs to previous cluser IDs
end
if ~exist('distanceMetric', 'var') || isempty(distanceMetric)
    distanceMetric = 'jaccard';  % {'jaccard', 'euclidean'}
end

plotflag = true;
% if plotflag || isequal(distanceMetric, 'euclidean')
%     temp = load('C:\Users\CBEM_NDDA_L1\Documents\fascicle\objectDetection\myfeatures_1000_8500.mat');
% end

switch distanceMetric
    case 'jaccard'
        assert(eps_ > 0 && eps_ < 1);
    case 'euclidean'
        assert(eps_ > 1);
end

% try
    x = [];
    for iframe = 1 + dmax:length(obj.frames) - dmax    
        % get the masks for the current range of frames
        inds = iframe - dmax:iframe + dmax;
%         masks2 = obj.masks(inds);
%         addNaN = false;
%         for imask = 1:length(masks2)
%             if isempty(masks2{imask})
%                 masks2{imask} = {sparse(zeros(2000, 2000, 'logical'))};
%             end
%         end
        frameNumbers = obj.frames(expand(arrayfun(@(x) repmat(x, [1 length(obj.masks{x})]), inds, 'UniformOutput', false)));
%         frameNumbers = obj.frames(expand(arrayfun(@(x) repmat(x, [1 length(masks2{x})]), 1:length(inds), 'UniformOutput', false)));
        myMasks = [obj.masks{inds}];
%         myMasks = [masks2{:}];

        % efficiently compute the Jaccard distances
        distances = zeros(length(myMasks), length(myMasks));
        if iframe > 1 + dmax && isequal(distanceMetric, 'jaccard')              
            distances(1:size(distancesOld, 1), 1:size(distancesOld, 2)) = 1 - distancesOld;
        end

        if plotflag || isequal(distanceMetric, 'euclidean')
            if iframe == 1 + dmax
                myMasks2 = myMasks;
                if ~isempty(obj.centroidTable)
                    sinds = ismember(obj.centroidTable.frame, obj.frames(inds));
                end
            else
                myMasks2 = myMasks(frameNumbers == frameNumbers(end));
                if ~isempty(obj.centroidTable)
                    sinds = ismember(obj.centroidTable.frame, frameNumbers(end));
                end
            end
            
            if isempty(obj.centroidTable)
                x_ = zeros(length(myMasks2), 2);
                for imask = 1:length(myMasks2)
                    s = regionprops(uint8(full(myMasks2{imask})), {'Centroid'});  % TODO uint8 in case the mask isn't contiguous, but will the output be a cell?
                    if isempty(s)
                        x_(imask, :) = [NaN NaN];
                    else
                        x_(imask, :) = s.Centroid;
                    end
                end
                x = [x; x_];
            else
%                 if addNaN
%                     x = [x; NaN NaN];
%                 else                
                    x = [x; obj.centroidTable.x(sinds) obj.centroidTable.y(sinds)];
%                 end
            end
        end

        switch distanceMetric
            case 'jaccard'
                for imask1 = 1:length(myMasks) - 1
                    if iframe == 1 + dmax
                        startcol = imask1 + 1;
                    else
                        startcol = find(frameNumbers == frameNumbers(end), 1, 'first');
                    end

                    for imask2 = startcol:length(myMasks)
                        distances(imask1, imask2) = jaccard(full(myMasks{imask1}), full(myMasks{imask2}));
                    end                    
                end                
                distances = 1 - max(max(distances, distances'), eye(length(myMasks)));
            case 'euclidean'                
                % frameInds = ismember(temp.myframe, frameNumbers);
                distances = pdist2(x, x, 'chebychev');
        end
        oldInds = frameNumbers > frameNumbers(1);
        if isequal(distanceMetric, 'jaccard')   
            distancesOld = distances(oldInds, oldInds);
        end

        % cluster
        idx = dbscan(distances, eps_, min_samples, 'Distance', 'precomputed');

        % only allow a single detection per frame per cluster
        %     trackIds1 = unique(idx(idx > 0));
        %     for itrack = 1:length(trackIds1)
        %         % If I had the scores saved with allmasksSparse, I could choose the
        %         % mask with the highest score for each frame within a cluster. Since
        %         % I don't have the scores, choose the first index per frame.
        %         inds = find(idx == trackIds1(itrack));
        %         [~, ia] = unique(frameNumbers(inds));
        %         % idx(setdiff(inds, inds(ia))) = -1;
        %     end

        if iframe == 1 + dmax
            trackIds = unique(idx(idx > 0));
            tracks = idx;
            newTrackId = max(trackIds) + 1;
            trackFrames = frameNumbers;
        else
            % associate next track segment
            % I could associate points on the next iteration if they overlapped
            % with the original points in the track that overlaps the most
            % above a threshold. If the threshold is not crossed, then start a
            % new track.

            idx2 = zeros(size(idx)) - 1;
            for itrack = 1:length(trackIds)  % TODO should I loop over trackIds1 instead?
                if trackFrames(end) == frameNumbers(end)
                    assert(isempty(obj.masks{inds(end)}) || nnz(obj.masks{inds(end)}) == 0);
                    break
                end
                trackInds = ismember(trackFrames, frameNumbers);

                % create an array that is the same size as
                % tracks(trackInds) and copy idx
%                 temp = zeros(nnz(trackInds), 1);
%                 temp(1:nnz(oldInds)) = idx(oldInds);
                % TODO I broke this somehow??? tracks and idx are not interchangeable
                assert(length(idx) >= nnz(trackInds));
                inds = find(tracks(trackInds) == trackIds(itrack));  % & temp ~= -1;
                inds = inds(idx(inds) ~= -1);  % this may have fixed my problem
                [m, f] = mode(idx(inds));
                if isempty(inds)
                    % pass
                elseif f / length(inds) > fthresh
                    idx2(idx == m) = trackIds(itrack);
                end               
            end

            potentialNewTracks = idx(idx2 == -1 & idx ~= -1);
            upnt = unique(potentialNewTracks);
            for inewtrack = 1:length(upnt)
                idx2(idx == upnt(inewtrack)) = newTrackId;
                trackIds = [trackIds; newTrackId];
                newTrackId = newTrackId + 1;
            end

            % -----
            newIdx = idx2(frameNumbers == frameNumbers(end));
            for ii = 1:length(newIdx)
                if newIdx(ii) == -1
                    continue
                end
                ind = find(tracks == newIdx(ii), 1, 'last');
                d = sqrt(sum((x(ind, :) - x(length(tracks) + ii, :)).^2));
                if d > 150
                    fprintf(1, 'd = %3.1f > 150 at %d\n', d, length(tracks) + ii);
                end
            end
            % -----

            tracks = [tracks; idx2(frameNumbers == frameNumbers(end))];
            trackFrames = [trackFrames frameNumbers(frameNumbers == frameNumbers(end))];
            assert(trackFrames(end) == frameNumbers(end));
        end

        idxOld = idx(oldInds);

        if plotflag
            % NOTE: This plot is not exactly the same the plot formed by filter_by_track
            % inds2 = ismember(temp.myframe, obj.frames(1:iframe + dmax));
            if iframe == 1 + dmax
                % figure; hsc = scatter3(temp.x(inds2), temp.y(inds2), temp.myframe(inds2), 12, tracks, 'filled');
                figure; hsc = scatter3(x(:, 1), x(:, 2), trackFrames, 12, tracks, 'filled');
                colormap('jet');
            elseif mod(iframe, 100) == 0 || iframe == length(obj.frames) - dmax
                % set(hsc, 'XData', temp.x(inds2), 'YData', temp.y(inds2), 'ZData', temp.myframe(inds2), 'CData', tracks);
                set(hsc, 'XData', x(:, 1), 'YData', x(:, 2), 'ZData', trackFrames, 'CData', tracks);
                drawnow();
            end
        end

        fprintf(1, 'frame %d\n', obj.frames(iframe));
    end
% catch ex
%     rethrow(ex);
% end

trackIds1 = unique(tracks(tracks > 0));
for itrack = 1:length(trackIds1)
    % If I had the scores saved with allmasksSparse, I could choose the
    % mask with the highest score for each frame within a cluster. Since
    % I don't have the scores, choose the first index per frame.
    inds = find(tracks == trackIds1(itrack));
    [~, ia] = unique(trackFrames(inds));
    tracks(setdiff(inds, inds(ia))) = -1;
end

if plotflag
    cm = zeros(max(tracks) + 2, 3);
    inds = find(histcounts(tracks, .5:1:max(tracks)+.5) > 30);
    inds = [-1 inds];
    cm(inds + 2, :) = jet(length(inds));
    colormap(cm);
end

% if distances is None:
%     distances = get_distances(detections, masks, dmax=dmax, device=device)
% clusters = DBSCAN(eps=eps, min_samples=min_samples, metric='precomputed')
% with warnings.catch_warnings():
%     warnings.filterwarnings("ignore", category=EfficiencyWarning)
%     clusters.fit(distances)
% 
% detections.loc[:, 'cell'] = clusters.labels_
% # rearrange to convenient column order.
% return detections[['frame', 'cell', 'mask', 'x', 'y'] +
%                   list(set(detections.columns) -
%                        {'frame', 'cell', 'mask', 'x', 'y'})].copy()