function hr = interpolate_ellipse_detections(obj, gndtruthframes)

jthresh1 = 0.5;
jthresh2 = 0.25;

[masks, boxes, labels, scores] = deal(cell(1, length(obj.frames)));
mytable = [];

% hold the first ground truth frame
initframes = obj.frames(1):gndtruthframes(1) - 1;
if ~isempty(initframes)
    assert(nnz(obj.masks{initframes(end)}{1}) > 0);
    s1 = cellfun(@(x) regionprops(full(x), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'}), obj.masks{initframes(end)});
    for iframe = 1:length(initframes)
        masks{iframe} = obj.masks{initframes(end)};
        boxes{iframe} = obj.boxes{initframes(end)};
        labels{iframe} = obj.labels{initframes(end)};
        scores{iframe} = obj.scores{initframes(end)};

        myrow = [reshape([s1.Centroid], 2, [])' repmat(obj.frames(iframe), [length(masks{iframe}) 1])];
        mytable = [mytable; table(myrow(:, 1), myrow(:, 2), myrow(:, 3), 'VariableNames', {'x' 'y' 'frame'})];
    end
end

% hold the last ground truth frame
lastframes = gndtruthframes(end) + 1:obj.frames(end);
if ~isempty(lastframes)
    assert(nnz(obj.masks{length(obj.frames) - length(lastframes) + 1}{1}) > 0);
    s1 = cellfun(@(x) regionprops(full(x), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'}), obj.masks{length(obj.frames) - length(lastframes) + 1});
    for iframe = length(obj.frames) - length(lastframes) + 1:length(obj.frames)
        masks{iframe} = obj.masks{length(obj.frames) - length(lastframes) + 1};
        boxes{iframe} = obj.boxes{length(obj.frames) - length(lastframes) + 1};
        labels{iframe} = obj.labels{length(obj.frames) - length(lastframes) + 1};
        scores{iframe} = obj.scores{length(obj.frames) - length(lastframes) + 1};

        myrow = [reshape([s1.Centroid], 2, [])' repmat(obj.frames(iframe), [length(masks{iframe}) 1])];
        mytable = [mytable; table(myrow(:, 1), myrow(:, 2), myrow(:, 3), 'VariableNames', {'x' 'y' 'frame'})];
    end
end

for iframe = 1:length(gndtruthframes) - 1
    % get the frames to interpolate (or extrapolate) between each pair of ground truth frames
%     if iframe == 1
%         assert(length(gndtruthframes) > 1);
%         frames = obj.frames(1):gndtruthframes(iframe + 1);
%     elseif iframe == length(gndtruthframes) - 1
%         frames = gndtruthframes(iframe):gndtruthframes(iframe + 1);
%     else
%         frames = gndtruthframes(iframe):obj.frames(end);
%     end
    
    % get the masks for the pair of ground truth frames
    iframe1 = find(obj.frames == gndtruthframes(iframe));       % endpoint of interpolation
    iframe2 = find(obj.frames == gndtruthframes(iframe + 1));
    % iframe1_ = find(obj.frames == frames(1));                   % endpoint of extrapolation
    % iframe2_ = find(obj.frames == frames(end));
    masks1 = obj.masks{iframe1};
    masks2 = obj.masks{iframe2};

    % get the ellipse parameters for each mask
    if length(masks1) == 1 && nnz(masks1{1}) == 0 || length(masks2) == 1 && nnz(masks2{1}) == 0
        for iframe_ = iframe1:iframe2
            masks{iframe_} = {sparse(zeros(2000, 2000, 'logical'))};
            boxes{iframe_} = zeros(1, 4);
            labels{iframe_} = categorical(repmat({'fascicle'}, [1 1]),{'fascicle' 'fa on nerve', 'fa off nerve'});
            scores{iframe_} = zeros(1, 1);
        end
        mytable = [mytable; table(NaN(length(iframe1:iframe2), 1), ...
            NaN(length(iframe1:iframe2), 1), ...
            reshape(obj.frames(iframe1:iframe2), [], 1), ...
            'VariableNames', {'x' 'y' 'frame'})];
        continue
    end    
    s1 = cellfun(@(x) regionprops(full(x), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'}), masks1);
    s2 = cellfun(@(x) regionprops(full(x), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'}), masks2);

    % get the mapping between masks
    J = zeros(length(masks1), length(masks2));
    for imask1 = 1:length(masks1)
        for imask2 = 1:length(masks2)
            J(imask1, imask2) = jaccard(full(masks1{imask1}), full(masks2{imask2}));
        end
    end
    % > 0.5 is a track
    % > 0.25 and sum > 0.5 is a branch or merge
    adj = J > jthresh2 & (sum(J, 2) > jthresh1 | sum(J, 1) > jthresh1);  % adjacency matrix
    
    % interpolate
    for iframe_ = iframe1:iframe2
        if ismember(obj.frames(iframe_), gndtruthframes)
            masks{iframe_} = obj.masks{iframe_};
            labels{iframe_} = obj.labels{iframe_};
            boxes{iframe_} = obj.boxes{iframe_};
            scores{iframe_} = obj.scores{iframe_};

            assert(nnz(obj.masks{iframe_}{1}) > 0);
            s1 = cellfun(@(x) regionprops(full(x), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'}), obj.masks{iframe_});
            myrow = [reshape([s1.Centroid], 2, [])' repmat(obj.frames(iframe_), [length(masks{iframe_}) 1])];    
            mytable = [mytable; table(myrow(:, 1), myrow(:, 2), myrow(:, 3), 'VariableNames', {'x' 'y' 'frame'})];
            continue
        end
        ct = 1;
        masks_ = cell(1, nnz(adj));
        boxes_ = zeros(nnz(adj), 4);
        scores_ = zeros(nnz(adj), 1);
        myrow_ = zeros(nnz(adj), 3);
        for ii = 1:size(adj, 1)
            for jj = 1:size(adj, 2)
                if adj(ii, jj)
                    ellParams = interp1([iframe1; iframe2], [struct2array(s1(ii)); struct2array(s2(jj))], iframe_, 'linear', 'extrap');
                    roi = images.roi.Ellipse('Center', ellParams(1:2), ...
                        'SemiAxes', ellParams(3:4) / 2, ...
                        'RotationAngle', ellParams(5));
                    masks_{ct} = sparse(roi.createMask(2000, 2000));
                    x = find(any(masks_{ct}, 1));
                    y = find(any(masks_{ct}, 2));                    
                    boxes_(ct, :) = [x(1), y(1), range(x) + 1, range(y) + 1];
                    scores_(ct) = interp1([iframe1; iframe2], [obj.scores{iframe1}(ii); obj.scores{iframe2}(jj)], iframe_, 'linear', 'extrap');
                    myrow_(ct, :) = [ellParams(1:2) obj.frames(iframe_)];
                    ct = ct + 1;
                end
            end
        end
        masks{iframe_} = masks_;
        boxes{iframe_} = boxes_;
        labels{iframe_} = categorical(repmat({'fascicle'}, [nnz(adj) 1]),{'fascicle' 'fa on nerve', 'fa off nerve'});
        scores{iframe_} = scores_;
        % TODO boxes{iframe_}, labels{iframe_}, scores{iframe_}
        mytable = [mytable; table(myrow_(:, 1), myrow_(:, 3), myrow_(:, 3), 'VariableNames', {'x' 'y' 'frame'})];
    end
    fprintf(1, 'interpolating segment %d of %d\n', iframe, length(gndtruthframes) - 1);
end

hr = FascicleResults('ellipse interpolation', obj.frames, masks, boxes, labels, scores, mytable);  % handle to results
