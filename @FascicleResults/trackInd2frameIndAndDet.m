function [iframes, idets] = trackInd2frameIndAndDet(obj, inds)
% TODO validate this method
ns = cellfun(@(x) len(x), obj.masks);
cns = cumsum(ns);
iframes = arrayfun(@(x) find(x >= [0 cns], 1, 'first'), inds);
idets = cns(iframes) - inds + 1;
