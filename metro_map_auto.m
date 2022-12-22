function metro_map_auto(G)
assert(ismember('frame', G.Nodes.Properties.VariableNames));

% get all unique frames
uframes = unique(G.Nodes.frame, 'sorted');

% merge nodes that have edges within the same frame because of the branch finding algorithm
[sout, tout] = findedge(G);
mergeInds = find(G.Nodes.frame(sout) == G.Nodes.frame(tout));
for im = 1:length(mergeInds)
    ind = mergeInds(im);
    newTargets = setdiff(neighbors(G, tout(ind)), sout(ind));
    G = addedge(G, repmat(sout(ind), [length(newTargets), 1]), newTargets, ones(length(newTargets), 1));    
end
G = rmnode(G, tout(mergeInds));

% initialize an array of x-values for the plot
x = zeros(size(G.Nodes, 1), 1);

% start at the first frame
frame = uframes(1);
% get the nodes at the current frame
curnodes = find(G.Nodes.frame == frame);
% store the currently used x-locations
curpaths = 1:length(curnodes);
x(curnodes) = curpaths;

while frame < uframes(end)
    % step forward one frame from each node
    nbrs = arrayfun(@(curnode) neighbors(G, curnode), curnodes, 'UniformOutput', false);
    nextNbrs = cellfun(@(inode) inode(G.Nodes.frame(inode) > frame), nbrs, 'UniformOutput', false);

    % TODO
    % also area could determine straight path
    if any(cellfun(@(x) length(x), nextNbrs)>1)
        disp('');
    end

    % loop over the neighboring nodes
    for inbr = 1:length(nextNbrs)        
        % the path could branch
        usedx = false;
        for ii = 1:length(nextNbrs{inbr})
            if x(nextNbrs{inbr}(ii)) == 0
                if ~usedx && inbr <= length(curnodes)
                    x(nextNbrs{inbr}(ii)) = x(curnodes(inbr));
                    usedx = true;
                else
                    curpaths = [curpaths, curpaths(end) + 1];
                    x(nextNbrs{inbr}(ii)) = curpaths(end);
                end
            end
        end        
    end

    frameNodes = find(G.Nodes.frame == frame + 1);
    curnodes = unique([cell2mat(nextNbrs); setdiff(frameNodes, cell2mat(nextNbrs))]);  % TODO might need to transpose within cells    

    frame = frame + 1;

    if mod(frame, 100) == 0
        fprintf(1, 'frame = %d\n', frame);
    end
end

figure(); plot(G, 'XData', x, 'YData', G.Nodes.frame);