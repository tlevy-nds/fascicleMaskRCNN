classdef FascicleResults < handle
    properties
        name    % label for the results that is used in saveing files

        frames
        masks
        centroidTable
        boxes
        labels
        scores

        tracks
        keepInds
        originalInds
    end

    methods
        function obj = FascicleResults(name, frames, masks, boxes, labels, scores, centroidTable)
            obj.name = name;
            obj.frames = frames;
            obj.masks = masks;
            obj.boxes = boxes;
            obj.labels = labels;
            if exist('scores', 'var')
                obj.scores = scores;
            else
                % Ground truth doesn't have a score
                obj.scores = arrayfun(@(x) ones(length(labels{x}), 1), 1:length(frames), 'UniformOutput', false);
            end
            if exist('centroidTable', 'var')
                obj.centroidTable = centroidTable;
            end

            obj.insert_empty_masks();
        end

        keep_labels(obj, keepLabels)
        insert_empty_masks(obj)
        hr = interpolate_ellipse_detections(obj, gndtruthframes)
        replace_with_gnd_truth(obj, hgt, gndtruthframes)
        keepInds = filter_by_track(obj, tracks, minTrackLength, gndtruthframes, plotflag)
        G = tracks_to_graph(obj, tracks, keepInds, frameThresh, dthresh)        
        non_maximum_suppression(obj)
        metrics = get_metrics(obj, imageNames)
        tracks = track_cells(obj, dmax, min_samples, eps_, fthresh, distanceMetric)  % This belongs here because it uses the masks
        [locationError] = loc_err(obj, masks, gt)
        render_volume(obj, frames)
        % TODO what other visualization methods should I have?
        [nTP, nFN, nFP, precision, recall, precisionAll, recallAll, AP] = validate_with_gt(obj, gt, jthresh, keepInds, plotflag)  % Hold out labeled frames

        ax = show_detection_img(obj, ax, frame, imageName, colchan, keepInds, clearflag)
        Jval = jaccard_with_gt(obj, gt, frame, keepInds)

        [Ns, N, firstFrameInd, lastFrameInd] = get_track_frames(obj)
        
        interpolate_gaps(obj, endpts)
        [tracks2, keepInds2, originalInds] = interpolate_track_gaps(obj, tracks, keepInds)

        [iframe, idet] = trackInd2frameIndAndDet(obj, ind)
        ind = frameIndAndDet2trackInd(obj, iframe, idet)
        remove_frames(obj, iframes)
        remove_dets(obj, iframe, idet)
        add_dets(obj, iframe, mask, score, track, keep)
    end

    methods (Static)
        write_annotations_unpacked(outputdir, frames, masks, labels, scores, boxes)
    end
end
