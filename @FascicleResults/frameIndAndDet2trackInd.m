function inds = frameIndAndDet2trackInd(obj, iframes, idets)
% TODO validate this method
ns = cellfun(@(x) len(x), obj.masks);
cns = [0 cumsum(ns)];
assert(all(idets < ns(iframes)));
inds = cns(iframes) + idets;
