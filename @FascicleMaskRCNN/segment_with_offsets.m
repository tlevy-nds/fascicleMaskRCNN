function [mymasks, mylabels, myscores, myboxes, mytable] = segment_with_offsets(obj, frames, offsets, jthresh, rthresh)

if ~exist('offsets', 'var') || isempty(offsets)
    offsets = [-7 -7; -7 0; -7 7; 0 -7; 0 0; 0 7; 7 -7; 7 0; 7 7];
end
if ~exist('jthresh', 'var') || isempty(jthresh)
    jthresh = 0.5;
end
if ~exist('rthresh', 'var') || isempty(rthresh)
    rthresh = 5;
end

% table of x, y, frame where x and y are the medians of the individual masks from each offset
% all other regionprops can be determined later using the combined mask
mytable = [];  

mymasks = cell(1, length(frames));
myscores = cell(1, length(frames));
myboxes = cell(1, length(frames));
mylabels = cell(1, length(frames));
for iframe = 1:length(frames)
    frame = frames(iframe);
    
    % run the segmentation for each offset
    masks = cell(1, size(offsets, 1));
    scores = cell(1, size(offsets, 1));
    for ioffset = 1:size(offsets, 1)
        offset = offsets(ioffset, :);
        [masks_, labels, scores_, boxes] = obj.segment_frames(frame, offset);
        hr = FascicleResults('myresults', frame, masks_, boxes, labels, scores_);
        hr.non_maximum_suppression()
        [masks_, scores_] = deal(hr.masks{1}, hr.scores{1});
        if isempty(masks_)
            masks{ioffset} = zeros(2000, 2000, 0);            
        else
            temp = cellfun(@(x) circshift(full(x), [-offset 0]), masks_, 'UniformOutput', false);
            masks{ioffset} = cat(3, temp{:});
        end        
        scores{ioffset} = scores_;
    end
    % temp = cellfun(@(x) sum(x, 3), masks, 'UniformOutput', false);
    % temp2 = sum(cat(3, temp{:}), 3);
    % figure;imagesc(temp2);
    % for ii = 1:9, subplot(3, 3, ii); imagesc(sum(masks{ii}, 3)); xlim([950 1300]); ylim([1250 1650]); end

    % label masks across offsets by Jaccard similarity
    repdets = cellfun(@(x) zeros(size(x, 3), 1), masks, 'UniformOutput', false);  % labels for the masks repeated across the offsets
    repdets2 = cellfun(@(x) zeros(size(x, 3), 1), masks, 'UniformOutput', false); % Jaccard similarity for pairs of labeled masks
    ct = 1;  % initial label
    for ioffset = 1:length(repdets)
        for imask = 1:length(repdets{ioffset})
            if repdets{ioffset}(imask) == 0
                mask1 = masks{ioffset}(:, :, imask);
                foundMatch = false;
                for ioffset2 = setdiff(1:size(offsets, 1), ioffset)
                    similarity1 = zeros(length(repdets{ioffset2}), 1);
                    for imask2 = 1:length(repdets{ioffset2})
                        if repdets{ioffset2}(imask2) == 0
                            mask2 = masks{ioffset2}(:, :, imask2);
                            similarity1(imask2) = jaccard(mask1, mask2);
                        end
                    end
                    [mv, mi] = max(similarity1);
                    if mv > jthresh
                        foundMatch = true;
                        repdets{ioffset}(imask) = ct;
                        repdets{ioffset2}(mi) = ct;
                        repdets2{ioffset}(imask) = mv;
                        repdets2{ioffset2}(mi) = mv;
                    end
                end
                if foundMatch
                    ct = ct + 1;
                end
            end
        end
    end

    % count the number of offsets that each label appears
    nrep = arrayfun(@(ii) sum(cellfun(@(x) nnz(x == ii), repdets)), 1:(ct - 1));

    % filter on the number of times a label is present
    rinds = find(nrep > rthresh);
    for ioffset = 1:length(repdets)
        repdets{ioffset}(~ismember(repdets{ioffset}, rinds)) = 0;
    end
    mymasks{iframe} = cell(1, length(rinds));
    myscores{iframe} = zeros(length(rinds), 1);
    mylabels{iframe} = categorical(repmat({'fascicle'}, [length(rinds) 1]), {'fascicle', 'fa on nerve', 'fa off nerve'});
    myboxes{iframe} = zeros(length(rinds), 4);

    % take the median of the centroids for the remaining lables
    % and form the final masks based on the frequency of pixel occurrence
    centroids = zeros(length(rinds), 2);
    for ir = 1:length(rinds)
        mymask = zeros(2000, 2000, 0);
        myscore = [];
        centroids_ = [];
        mylabel = rinds(ir);
        for ioffset = 1:length(repdets)
            ind = repdets{ioffset} == mylabel;
            if nnz(ind) == 0
                continue
            end
            mymask = cat(3, mymask, masks{ioffset}(:, :, ind));
            myscore = [myscore; scores{ioffset}(ind)];
            s = regionprops(mymask(:, :, end), {'Centroid'});
            centroids_ = [centroids_; s.Centroid];
        end
        mymasks{iframe}{ir} = sparse(sum(mymask, 3) > rthresh);
        myscores{iframe}(ir) = median(myscore);
        indx1 = find(sum(mymasks{iframe}{ir}, 1), 1, 'first');
        indx2 = find(sum(mymasks{iframe}{ir}, 1), 1, 'last');
        indy1 = find(sum(mymasks{iframe}{ir}, 2), 1, 'first');
        indy2 = find(sum(mymasks{iframe}{ir}, 2), 1, 'last');
        myboxes{iframe}(ir, :) = [indx1, indy1, indx2 - indx1 + 1, indy2 - indy1 + 1];  % x, y, width, height
        centroids(ir, :) = median(centroids_, 1);
        % figure;imagesc(sum(mymask, 3));
        % figure;plot(centroids(:, 1), centroids(:, 2), '.');hold on;plot(median(centroids(:, 1)), median(centroids(:, 2)), 'r.');hold off;
        % s = regionprops(sum(mymask, 3) > rthresh, {'Centroid'});
        % hold on;plot(s.Centroid(1), s.Centroid(2), 'go');
    end
    mytable = [mytable; table(centroids(:, 1), centroids(:, 2), repmat(frame, [size(centroids, 1) 1]), 'VariableNames', {'x', 'y', 'frame'})];

    if ~isscalar(frames)
        fprintf(1, 'frame %d\n', frame);
    end
end