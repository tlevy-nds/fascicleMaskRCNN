function [Ns, N, firstFrameInd, lastFrameInd] = get_track_frames(obj)

Ns = cellfun(@(x) nnz(ismember(x, {'fascicle'})), reshape(obj.labels, 1, []));
Ns = max(Ns, 1);  % because of insert_empty_masks
N = sum(Ns);
lastFrameInd = cumsum(Ns);
firstFrameInd = [1 lastFrameInd(1:end - 1) + 1];
