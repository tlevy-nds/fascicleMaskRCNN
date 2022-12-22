function [nTP, nFN, nFP, precision, recall, precisionAll, recallAll, AP] = validate_with_gt(obj, gt, jthresh, keepInds, plotflag)
% https://jonathan-hui.medium.com/map-mean-average-precision-for-object-detection-45c121a31173#:~:text=AP%20(Average%20precision)%20is%20a,value%20over%200%20to%201.
% averagePrecision = evaluateDetectionPrecision(detectionResults,groundTruthData)
% ssm = evaluateSemanticSegmentation(dsResults,dsTruth)
% Maybe I should use datastores rather than loading all of the masks?
% I'm not sure Matlab has the appropriate evaluate instace segmentation function.

[Ns, N, firstFrameInd, lastFrameInd] = obj.get_track_frames();

if ~exist('jthresh', 'var') || isempty(jthresh)
    jthresh = 0.5;
end
if ~exist('keepInds', 'var') || isempty(keepInds)    
    keepInds = true(N, 1);
end
if ~exist('plotflag', 'var') || isempty(plotflag)
    plotflag = false;
end

[nTP, nFN, nFP, precision, recall] = deal(zeros(1, length(obj.frames)));
for iframe = 1:length(obj.frames)
    frame = obj.frames(iframe);
    gtInd = gt.frames == frame;

    keepInds2 = keepInds(firstFrameInd(iframe):lastFrameInd(iframe));

    masks = cellfun(@(mask) full(mask), obj.masks{iframe}(keepInds2), 'UniformOutput', false);
    masks = cat(3, masks{:});
    if nnz(keepInds2) == 0
        masks = zeros(2000, 2000, 0, 'logical');
    end
    
    fascicleInds = ismember(gt.labels{gtInd}, {'fascicle'});
    gtmasks = cellfun(@(mask) full(mask), gt.masks{gtInd}(fascicleInds), 'UniformOutput', false);
    gtmasks = cat(3, gtmasks{:});
    if nnz(fascicleInds) == 0
        gtmasks = zeros(2000, 2000, 0, 'logical');
    end

    Jval = zeros(size(masks, 3), size(gtmasks, 3));
    for imask1 = 1:size(masks, 3)
        for ignd = 1:size(gtmasks, 3)            
            Jval(imask1, ignd) = jaccard(masks(:, :, imask1), gtmasks(:, :, ignd));
        end
    end

    maxval1 = max(Jval, [], 1);
    [maxval2, mi] = max(Jval, [], 2);
    mi2 = mi(maxval2 >= jthresh);
    nTP(iframe) = length(unique(mi2));
    nFN(iframe) = length(setdiff(1:size(Jval, 2), mi));
    nFP(iframe) = length(mi(maxval2 < jthresh));
    precision(iframe) = nTP(iframe) ./ (nTP(iframe) + nFP(iframe));
    recall(iframe) = nTP(iframe) ./ (nFN(iframe) + nTP(iframe));

    fprintf('%d of %d\n', iframe, length(obj.frames));
end
precisionAll = sum(nTP) ./ (sum(nTP) + sum(nFP));
recallAll = sum(nTP) ./ (sum(nFN) + sum(nTP));

pr = sortrows([precision' recall'], 2);
pr = pr(all(~isnan(pr), 2), :);
for ir = size(pr, 1) - 1:-1:1
    pr(ir, 1) = max(pr(ir + 1, 1), pr(ir, 1));
end
inds = find(diff(pr(:, 1)) ~= 0);
up = unique(pr(:, 1), 'stable');
dr = diff([0; (pr(inds, 2) + pr(inds + 1, 2)) / 2; 1]);
AP = sum(dr .* up);

if plotflag
    % TODO this includes the ground truth
    pr = sortrows([precision' recall'], 2);
    pr = pr(all(~isnan(pr), 2), :);
    [B, ia, ic] = unique(pr, 'rows');
%     size(ic)
%     size(ia)
%     size(B)
%     unique(ic)
%     histcounts(ic, 0.5:1:length(ia) + 0.5)
    figure(); ax = gca(); scatter(B(:, 2), B(:, 1), 12, histcounts(ic, 0.5:1:length(ia) + 0.5)', 'filled');colorbar();
    xlabel(ax, 'recall');
    xlabel('recall');ylabel('precision');
    grid on;
    xlim(ax, [0 1]);
    ylim(ax, [0 1]);

%     figure(); ax = gca();
%     plot(ax, recall, precision, '.');
%     xlabel(ax, 'recall');
%     ylabel(ax, 'precision');
    hold(ax, 'on');
    plot(ax, recallAll, precisionAll, '.', 'MarkerSize', 18);
    hold(ax, 'off');

    legend(ax, {'Individial Frames' 'Aggregate'});
%     xlim(ax, [0 1]);
%     ylim(ax, [0 1]);
end
