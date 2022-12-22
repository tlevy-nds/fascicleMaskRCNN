function interpolate_gaps(obj, endpts)
% define missing segments
% [imask1 frane1 imask2 frame2]
if ~exist('endpts', 'var') || isempty(endpts)
    % TODO be careful not to run this twice
    endpts = [1 4983 3 5000; ...
        2 4983 1 5000; ...
        3 4983 2 5000; ...
        4 4983 4 5000; ...
        5 4982 5 5000; ...
        1 5961 1 6000; ...
        2 5961 2 6000; ...
        3 5961 4 6000; ...
        4 5961 3 6000; ...
        1 2973 3 3000];
end

assert(issorted(obj.centroidTable.frame));

% loop over each missing segment
for iendpt = 1:size(endpts, 1)
    % get the endpoint masks
    [imask1, frame1, imask2, frame2] = deal(endpts(iendpt, 1), endpts(iendpt, 2), endpts(iendpt, 3), endpts(iendpt, 4));
    iframe1 = find(ismember(obj.frames, frame1));
    iframe2 = find(ismember(obj.frames, frame2));
    mask1 = full(obj.masks{iframe1}{imask1});
    mask2 = full(obj.masks{iframe2}{imask2});

    % get the ellipse parameters
    s1 = regionprops(uint8(mask1), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'});
    s2 = regionprops(uint8(mask2), {'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation'});

    % interpolate the new ellipses
    newframes = frame1+1:frame2-1;
    si = interp1([frame1; frame2], [struct2array(s1); struct2array(s2)], newframes', 'linear');
    if ~isempty(obj.scores)
        newscores = interp1([frame1; frame2], [obj.scores{iframe1}(imask1); obj.scores{iframe2}(imask2)], newframes', 'linear');
    end

    for iframe_ = 1:length(newframes)
        frame = newframes(iframe_);
        iframe = find(obj.frames == frame);

        % create the new masks
        roi = images.roi.Ellipse('Center', si(iframe_, 1:2), 'SemiAxes', si(iframe_, 3:4) / 2, 'RotationAngle', si(iframe_, 5));
        newmask = roi.createMask(2000, 2000);
        indsx = find(any(newmask, 1));
        indsy = find(any(newmask, 2));
        
        % insert the new masks
        if length(obj.masks{iframe}) == 1 && nnz(obj.masks{iframe}{1}) == 0
            % replace the empty mask
            obj.masks{iframe}{1} = sparse(newmask);            
        else
            % add mask to the end of the list
            obj.masks{iframe} = [obj.masks{iframe} {sparse(newmask)}];            
        end
        obj.boxes{iframe} = [obj.boxes{iframe}; indsx(1), indsy(1), range(indsx) + 1, range(indsy) + 1];
        obj.labels{iframe} = [obj.labels{iframe}; categorical({'fascicle'}, {'fascicle', 'fa on nerve', 'fa off nerve'})];
        
        ctinds = find(obj.centroidTable.frame == frame);
        assert(~isempty(ctinds));        
        if length(ctinds) == 1 && isnan(obj.centroidTable.x(ctinds))
            obj.centroidTable.x(ctinds) = si(iframe_, 1);
            obj.centroidTable.y(ctinds) = si(iframe_, 2);
            assert(obj.centroidTable.frame(ctinds) == frame);
        else
            obj.centroidTable = [obj.centroidTable(1:ctinds(end), :); ...
                table(si(iframe_, 1), si(iframe_, 2), frame, 'VariableNames', {'x' 'y' 'frame'}) ; ...
                obj.centroidTable(ctinds(end) + 1:end, :)];
        end

        if ~isempty(obj.scores)            
            obj.scores{iframe} = [obj.scores{iframe}; newscores(iframe_)];
        end
    end
end