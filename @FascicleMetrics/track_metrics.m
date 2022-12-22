function track_metrics(obj)
gtf = load('myfeatures_gt_1000_8500.mat');
load('myfeatures_1000_8500.mat');
kurt(isnan(kurt)) = 0;
irregularity = real(irregularity);

useIrreg = true;
if useIrreg    
    positionSelector = [0 0 1 0 0 0; 0 0 0 0 1 0];
    velocitySelector = [0 0 0 1 0 0; 0 0 0 0 0 1];
else
    positionSelector = [1 0 0 0; 0 0 1 0];
    velocitySelector = [0 1 0 0; 0 0 0 1];
end

% mNoise = diag([9 25 25]);
% mNoise = diag([25 25]);
useMHT = false;
if useMHT
    tracker = trackerTOMHT('FilterInitializationFcn', @initcvkf, ...
        'ConfirmationThreshold', 20, ...
        'AssignmentThreshold', 60 * [0.3 0.7 1 Inf], ...  % 30 * [0.3 0.7 1 Inf]
        'FalseAlarmRate', 1e-6, ...
        'DetectionProbability', 0.9, ...
        'DeletionThreshold', -20, ...  % -7
        'MaxNumHypotheses', 10, ...
        'MaxNumTracks', 50);
else
    % This tracker is faster and I can easily control when the track is deleted
    % but I notice that the coasting is at the estimate of the velocity and
    % that is not close to 0
    tracker = trackerGNN('FilterInitializationFcn', @initcvkf, ...
        'ConfirmationThreshold', [47 50], ...
        'AssignmentThreshold', 30 * [1 Inf], ...       
        'DeletionThreshold', [50 50], ...
        'Assignment', 'Munkres', ...
        'MaxNumTracks', 50);
    % tgm = trackGOSPAMetric("Distance","posabserr");  % for measuring performance against the truth
end

trackIds = [];
branchIds = [];
% branchIds = [];
tracks = [];
gospa = zeros(length(frames), 1);
clear truth;
for iframe = 1:length(frames) - 1
    frame = frames(iframe);

    inds = find(myframe == frame);
    indst = find(gtf.myframe == frame);
    if useIrreg
        detections = arrayfun(@(ind) objectDetection(frame, ...
            [real(irregularity(ind)), x(ind), y(ind)], ... % 
            'MeasurementNoise', 3*diag([3 repmat(8, [1 2])])), inds, 'UniformOutput', false);  % TODO could normalize mNoise by the sqrt(area)

        % TODO PlatformID might need to be labeled for each fascicle
        % truth = arrayfun(@(ind) struct('PlatformID', 1, 'ClassID', 0, 'Position', [gtf.irregularity(ind) gtf.x(ind) gtf.y(ind)]), inds);
    else
        detections = arrayfun(@(ind) objectDetection(frame, ...
            [x(ind), y(ind)], ...
            'MeasurementNoise', diag(repmat(area(ind) / 250, [1 2]))), inds, 'UniformOutput', false);  % TODO could normalize mNoise by the sqrt(area)
    end

    t0 = clock();
    [confirmedTracks, tentativeTracks, allTracks, analysisInformation] = tracker(detections, frame);
    for ict = 1:length(allTracks)
        mystate = allTracks(ict).State;
%         if useMHT
%             ind = find(branchIds == confirmedTracks(ict).BranchID);
%         else
%             ind = find(trackIds == confirmedTracks(ict).TrackID);
%         end
%         if isempty(ind) || size(tracks{ind}, 1) < 10
%             % mystate(2:2:end) = zeros(length(mystate)/2, 1);
%         else
%             pts = diff(movmean(tracks{ind}(:, [4 1 2]), 10), 1, 1);        
%             mystate(2:2:end) = reshape(median(pts(max(1, size(pts, 1) - 50):end, :), 1), [], 1);  % zero the velocity
%         end
        mystate(2:2:end) = 0;
        if useMHT
            setTrackFilterProperties(tracker, allTracks(ict).BranchID, 'State', mystate);
        else
            setTrackFilterProperties(tracker, allTracks(ict).TrackID, 'State', mystate);
        end
    end
    tf = clock();

    if exist('truth', 'var')
        % gospa(iframe) = tgm(confirmedTracks, truth);
    end

    if etime(tf, t0) > 5
        fprintf(1, '%2.1f seconds\n', etime(tf, t0));
        disp('');
    end

    if isempty(confirmedTracks)
        continue
    end

    curPos = getTrackPositions(confirmedTracks, positionSelector);
    irreg = arrayfun(@(x) confirmedTracks(x).State(1), 1:length(confirmedTracks));   

    for itrack = 1:length(confirmedTracks)
        if useMHT
            trackId = confirmedTracks(itrack).TrackID;
            branchId = confirmedTracks(itrack).BranchID;
            if ~ismember(branchId, branchIds)
                branchIds = [branchIds branchId];
                trackIds = [trackIds trackId];
                tracks = [tracks {[curPos(itrack, :) frame irreg(itrack)]}];
            else
                ind = find(branchIds == branchId);
                tracks{ind} = [tracks{ind}; [curPos(itrack, :) frame irreg(itrack)]];
            end
        else
            trackId = confirmedTracks(itrack).TrackID;
            if ~ismember(trackId, trackIds)
                trackIds = [trackIds trackId];
                tracks = [tracks {[curPos(itrack, :) frame irreg(itrack)]}];
            else
                ind = find(trackIds == trackId);
                tracks{ind} = [tracks{ind}; [curPos(itrack, :) frame irreg(itrack)]];
            end
        end
    end

    if mod(iframe, 10) == 0
        fprintf(1, 'frame = %d, numtracks = %d\n', frame, length(confirmedTracks));
    end
    
end
inds = find(cellfun(@(x) length(x) > 0, tracks));
figure();hold on;for ii = 1:length(inds), plot3(tracks{inds(ii)}(:, 1), tracks{inds(ii)}(:, 2), tracks{inds(ii)}(:, 3), '-', 'LineWidth', 2); end; hold off;
grid on; axis equal;