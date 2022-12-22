%% Load the model
hfd = FascicleMaskRCNN('human');  % handle to the fascicle detector
imgNames = arrayfun(@(frame) hfd.get_image_name(frame), hfd.allframes, 'UniformOutput', false);  % metrics aren't computed in FascicleMaskRCNN

%% Ground truth
% get all the ground truth masks
gtFile = 'mygt.mat';
if ~isfile(gtFile)
    % This can be run locally
    [gtmasks, gtlabels, gtboxes, gtImageNames] = hfd.load_all_gnd_truth(hfd.allframes);
    save(gtFile, 'gtmasks', 'gtlabels', 'gtboxes', 'gtImageNames', '-v7.3');
    gtCentroidTable = form_centroid_table(gtmasks, gtlabels, hfd.allframes);
    save(gtFile, 'gtCentroidTable', '-append')
elseif ~exist('gtmasks', 'var')
    load(gtFile, 'gtmasks', 'gtlabels', 'gtboxes', 'gtImageNames', 'gtCentroidTable');
end
hgt = FascicleResults('mygt', hfd.allframes, gtmasks, gtboxes, gtlabels, [], gtCentroidTable);        % handle to ground truth
% interpolate_missing_gt;  % use on mygt_old.mat

% analysis of ground truth
gttracksFile = 'gttracks.mat';
if ~isfile(gttracksFile)
    [dmax, min_samples, eps_, fthresh, distanceMetric] = deal(5, 3, 0.6, 2/3, 'jaccard');
    gttracks = hgt.track_cells(dmax, min_samples, eps_, fthresh, distanceMetric);
    save(gttracksFile, 'gttracks', 'dmax', 'min_samples', 'eps_', 'fthresh', 'distanceMetric');
else
    load(gttracksFile, 'gttracks');
end
gtGfile = 'gtG.mat';
if ~isfile(gtGfile)
    [frameThresh, dthresh] = deal(5, 5);
    gtG = hgt.tracks_to_graph(gttracks, [], frameThresh, dthresh);
    save(gtGfile, 'gtG');
else
    load(gtGfile, 'gtG');
end

% for experimenting with automated metro map
gtG.Nodes.frame = hgt.centroidTable.frame(gtG.Nodes.trackInds);
% gtG = rmedge(gtG, 767, 1215);
% gtG = addedge(gtG, [767; 1215], [1216; 1216], [1; 1]);

%% Original results (for comparison)
load('mat files\original\myresults.mat', 'masks', 'labels', 'scores', 'boxes', 'mytable');
horig = FascicleResults('orig', hfd.allframes, masks, boxes, labels, scores, mytable);

%% Detections
% segment each frame
resultsFiles = arrayfun(@(x) sprintf('mat files\\fold%d\\myresults_fold%d.mat', x, x), 1:5, 'UniformOutput', false);
[gndtruthframes, frames, masks, labels, scores, boxes, mytable] = deal([]);
for ifold = 1:5  % 1:length(resultsFiles)
    if isfile(hfd.netMatFile(ifold, 2))  % has that fold been completed?
        [~, gndtruthframes_, frames_] = hfd.get_trainInds(ifold);
        gndtruthframes_ = gndtruthframes_(ismember(gndtruthframes_, frames_));  % stage 2 training contains 1 extra frame
        if ~isfile(resultsFiles{ifold})  % have the test data been evaluated?
            assert(false);
            % Run on the remote computer and transfer the mat file because this requires GPU resources
            [masks, labels, scores, boxes, mytable] = hfd.segment_with_offsets(frames_);
            save(resultsFiles{ifold}, 'masks', 'labels', 'scores', 'boxes', 'mytable', '-v7.3');
        else  % if ~exist('masks', 'var')
            temp = load(resultsFiles{ifold}, 'masks', 'labels', 'scores', 'boxes', 'mytable');
            % assert(length(masks) == length(frames));
        end

        % concatenate folds
        gndtruthframes = [gndtruthframes gndtruthframes_];
        frames = [frames frames_];
        % assert(~any(ismember(frames_, frames)));
        masks = [masks temp.masks];
        labels = [labels temp.labels];
        boxes = [boxes temp.boxes];
        scores = [scores temp.scores];
        mytable = [mytable; temp.mytable];
    end
end

% this won't work unless the endpoints have detections, so might as well insert the ground truth here
if false
    hr = FascicleResults('myresults', frames, masks, boxes, labels, scores, mytable);  % handle to results
    hr.replace_with_gnd_truth(hgt, gndtruthframes);  % replace detections from gndtruthframes with the ground truth
else
    hr = replace_detections_with_ground_truth(hgt, gndtruthframes, sprintf('fold%d', ifold), frames, masks, labels, scores, boxes, mytable);
end

% warning off; metrics = hr.get_metrics(imgNames); warning on; save(sprintf('metrics_table_fold%d.mat', ifold), 'metrics');
% I'd rather not do the area filter and just write that we are extracting metrics

% dbscan tracker
% tracksFile = sprintf('mat files\\fold%d\\tracks_fold%d.mat', ifold, ifold);
tracksFile = 'mat files\combined\tracks_combined.mat';
if ~isfile(tracksFile)
    [dmax, min_samples, eps_, fthresh, distanceMetric] = deal(5, 3, 0.6, 2/3, 'jaccard');
    tracks = hr.track_cells(dmax, min_samples, eps_, fthresh, distanceMetric);
    save(tracksFile, 'tracks', 'dmax', 'min_samples', 'eps_', 'fthresh', 'distanceMetric');
else
    load(tracksFile, 'tracks');
end
keepInds = hr.filter_by_track(tracks, 30, gndtruthframes, true);  % any clusters that contain a ground truth mask pass the threshold
% [tracks2, keepInds2, originalInds] = hr.interpolate_track_gaps(tracks, keepInds);  % TODO not working yet
[tracks2, keepInds2, originalInds] = deal(tracks, keepInds, []);

assert(all(keepInds2(ismember(hr.centroidTable.frame, gndtruthframes) & true)));  % tracks ~= -1

% graphFile = sprintf('mat files\\fold%d\\G_fold%d.mat', ifold, ifold);
graphFile = 'mat files\combined\G_combined.mat';
if ~isfile(graphFile)
    [frameThresh, dthresh] = deal(5, 5);
    G = hr.tracks_to_graph(tracks2, keepInds2, frameThresh, dthresh);
    % assert(nnz(keepInds2) - nnz(tracks2(keepInds2) == -1) == G.numnodes);  % TDOO Why is this not true?
    save(graphFile, 'G');
else
    load(graphFile, 'G');
end

%% Validation
% prFile = sprintf('mat files\\fold%d\\pr_fold%d.mat', ifold, ifold);
prFile = 'mat files\combined\pr_combined.mat';
if ~isfile(prFile)
    % TODO does originalInds reproduce the original result?
    % keepInds2 & originalInds
    [nTP, nFN, nFP, precision, recall, precisionAll, recallAll, AP] = hr.validate_with_gt(hgt, 0.5, keepInds2, true);
    save(prFile, 'nTP', 'nFN', 'nFP', 'precision', 'recall', 'AP');
else
    load(prFile, 'nTP', 'nFN', 'nFP', 'precision', 'recall', 'AP');
end
% [Ns, N, firstFrameInd, lastFrameInd] = hgt.get_track_frames();
% figure;plot(nTP ./ Ns(1:1500), '.');


%% Compare to linearly interpolated ground truth model
% fit ellipse to each mask and interpolate the parameters and form new
% masks that serve as the detections for comparison
% Use jaccard to find matches. If none > 0.5 but sum > 0.5 and individuals
% > 0.25 then branch or merge
if ~isfile('ellipseInterp.mat')
    hr2 = hgt.interpolate_ellipse_detections(gndtruthframes);
    [frames, masks, centroidTable, boxes, labels, scores] = deal(hr2.frames, hr2.masks, hr2.centroidTable, hr2.boxes, hr2.labels, hr2.scores);
    [Ns, N, firstFrameInd, lastFrameInd] = hr2.get_track_frames();
    % TODO something is not consistent, centroidTable is not length(N),
    % should labels be empty or set to 0? see if centroidTable is
    % consistent with other data.
    save('ellipseInterp.mat', 'frames', 'masks', 'centroidTable', 'boxes', 'labels', 'scores', '-v7.3');
else
    load('ellipseInterp.mat', 'frames', 'masks', 'centroidTable', 'boxes', 'labels', 'scores');
end

% dbscan tracker
[dmax, min_samples, eps_, fthresh, distanceMetric] = deal(5, 3, 0.6, 2/3, 'jaccard');
tracks2 = hr2.track_cells(dmax, min_samples, eps_, fthresh, distanceMetric);
save('tracks2.mat', 'tracks2', 'dmax', 'min_samples', 'eps_', 'fthresh', 'distanceMetric');
keepInds2 = hr2.filter_by_track(tracks2, 30, gndtruthframes, true);  % any clusters that contain a ground truth mask pass the threshold
keepInds2(ismember(hr2.centroidTable.frame, gndtruthframes)) = true;

[frameThresh, dthresh] = deal(5, 5);
G2 = hr2.tracks_to_graph(tracks2, keepInds2, frameThresh, dthresh);
save('G2.mat', 'G2');

%% Figures
for frame = 1000:1000:8500
frame = 7001;
iframe = find(hfd.allframes == frame);
ax1 = hgt.show_detection_img(frame, imgNames{iframe}, 2);
ax2 = hr.show_detection_img(frame, imgNames{iframe}, 1, keepInds);  % changed to bright red and number all
linkaxes([ax1 ax2], 'xy');
% Jval = hr.jaccard_with_gt(hgt, frame, true(size(keepInds)));                    % need to use all instead of keepInds now
% max(Jval, [], 2)
end

% [Ns, N, firstFrameInd, lastFrameInd] = hr.get_track_frames();

% TODO this takes about 60 seconds and isn't very interpretable. Maybe I
% should draw it myself using gtG and gttracks.fig (since I didn't store
% centroids anywhere else: now in gtCentroidTable.mat)

[G2, edgeCData, edgeCData2] = simplify_graph(G);
% TODO the indices are not lining up???
figure(); plot(G, 'XData', hr.centroidTable.x(G.Nodes.trackInds), ...
    'YData', hr.centroidTable.y(G.Nodes.trackInds), ...
    'ZData', hr.centroidTable.frame(G.Nodes.trackInds), ...
    'EdgeCData', edgeCData, 'Marker', 'none');
colormap('colorcube');
figure(); plot(G2, 'Layout', 'layered', 'EdgeCData', edgeCData2, 'Marker', 's');
colormap('colorcube');
% [x, y, myframes] = plot_graph(G, hr.centroidTable);

[gtG2, gtEdgeCData, gtEdgeCData2] = simplify_graph(gtG);
figure(); plot(gtG, 'XData', hgt.centroidTable.x(gtG.Nodes.trackInds), ...
    'YData', hgt.centroidTable.y(gtG.Nodes.trackInds), ...
    'ZData', hgt.centroidTable.frame(gtG.Nodes.trackInds), ...
    'EdgeCData', gtEdgeCData, 'Marker', 'none'); colormap('jet');
figure(); plot(gtG2, 'Layout', 'layered', 'EdgeCData', gtEdgeCData2, 'Marker', 's'); colormap('jet');
% [gtx, gty, gtmyframes] = plot_graph(gtG, gtCentroidTable);


%% Volume rendering
useKeepInds = true;
ifold = 3.4;
[indsx, indsy] = hfd.get_fold_xy_inds(ifold);
if ismember(ifold, [])
    stride = 100;
else
    stride = 1;
end    
mystack = zeros(length(indsy), length(indsx), length(1:stride:length(hr.masks)));
[Ns, N, firstFrameInd, lastFrameInd] = hr.get_track_frames();
myinds = 1:stride:length(hr.masks);
for ii_ = 1:length(myinds)
    ii = myinds(ii_);
    if useKeepInds
        ki = keepInds(firstFrameInd(ii):lastFrameInd(ii));
    else
        ki = true(size(keepInds(firstFrameInd(ii):lastFrameInd(ii))));
    end
    if nnz(ki) == 0
        continue
    end
    temp = cellfun(@(x) full(x), hr.masks{ii}(ki), 'UniformOutput', false);
    temp2 = max(cat(3, temp{:}), [], 3);
    mystack(:, :, ii_) = temp2(indsy, indsx);
    if mod(ii_, 100) == 0
        fprintf(1, '%d of %d\n', ii, length(hr.masks));
    end
end
if stride == 1
    figure;volshow(mystack, 'Renderer', 'VolumeRendering');
else
    figure;imagesc(sum(mystack, 3));
end

%% using ground truth
useKeepInds = false;
ifold = 3.4;
[indsx, indsy] = hfd.get_fold_xy_inds(ifold);
if ismember(ifold, [])
    stride = 100;
else
    stride = 1;
end    
mystack = zeros(length(indsy), length(indsx), length(1:stride:length(hgt2.masks)));
[Ns, N, firstFrameInd, lastFrameInd] = hgt2.get_track_frames();
myinds = 1:stride:length(hgt2.masks);
for ii_ = 1:length(myinds)
    ii = myinds(ii_);
    if useKeepInds
        ki = keepInds(firstFrameInd(ii):lastFrameInd(ii));
    else
        ki = true(length(firstFrameInd(ii):lastFrameInd(ii)), 1);
    end
    if nnz(ki) == 0
        continue
    end
    temp = cellfun(@(x) full(x), hgt2.masks{ii}(ki), 'UniformOutput', false);
    temp2 = max(cat(3, temp{:}), [], 3);
    mystack(:, :, ii_) = temp2(indsy, indsx);
    if mod(ii_, 100) == 0
        fprintf(1, '%d of %d\n', ii, length(hgt2.masks));
    end
end
if stride == 1
    figure;volshow(mystack, 'Renderer', 'VolumeRendering');
else
    figure;imagesc(sum(mystack, 3));
end
