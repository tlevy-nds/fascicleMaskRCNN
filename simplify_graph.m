function [G2, edgeCData, edgeCData2] = simplify_graph(G)
% collapse each singleton chain in the graph
numNeighbors = arrayfun(@(inode) length(neighbors(G, inode)), 1:size(G.Nodes, 1));
nodesToRemove = find(numNeighbors == 2);  % this list gets reduced in the while loop below
nodesToRemove2 = nodesToRemove;  % store this list to remove at the end

[src, tgt] = findedge(G);
edgeCData = zeros(G.numedges, 1);
curChain = 1;

% loop while there exists singleton chains
nodeLists = [];
while ~isempty(nodesToRemove)
    % choose the first node that is part of a singleton chain
    curNode = nodesToRemove(1);

    % get the node's neighbors
    neighborNodes = neighbors(G, curNode);
    curNode2 = neighborNodes(1);
    curNode3 = neighborNodes(2);

    % form a list for the current singleton chain
    nodeList = curNode;

    % traverse the chain in one direction
    prevNode = curNode;
    neighborNodes = neighbors(G, curNode2);
    while length(neighborNodes) == 2
        nodeList = [nodeList curNode2];                
        curNode2_ = setdiff(neighborNodes, prevNode);
        prevNode = curNode2;
        curNode2 = curNode2_;
        neighborNodes = neighbors(G, curNode2);
    end
    % store the endpoint
    pt1 = curNode2;

    % traverse the chain in the other direction
    prevNode = curNode;
    neighborNodes = neighbors(G, curNode3);
    while length(neighborNodes) == 2
        nodeList = [nodeList curNode3];                
        curNode3_ = setdiff(neighborNodes, prevNode);
        prevNode = curNode3;
        curNode3 = curNode3_;
        neighborNodes = neighbors(G, curNode3);
    end
    % store the endpoint
    pt2 = curNode3;

    % remove the list of nodes for this chain from the master list
    nodesToRemove = setdiff(nodesToRemove, nodeList);

    edgeInds = ismember(src, nodeList) & ismember(tgt, nodeList);
    edgeCData(edgeInds) = curChain;    

    nodeLists = [nodeLists {nodeList}];
    % add an edge connecting the two ends of the chain

    % This requires 2 edges
    %        /.--.--.\
    % .--.--.         .--.--.
    %        \.--.--./
    % don't exclude if the edge already exists

    % if ~findedge(G, pt1, pt2)
        G = addedge(G, pt1, pt2, curChain + 0.5);
    % end

    curChain = curChain + 1;
end

% remove the nodes
G2 = rmnode(G, nodesToRemove2);
edgeCData2 = zeros(G2.numedges, 1);
myInds = mod(G2.Edges.Weight, 1) == 0.5;
edgeCData2(myInds) = floor(G2.Edges.Weight(myInds));

% separate color for branch edges
edgeCData(G.Edges.Weight == 3) = curChain;
edgeCData2(G2.Edges.Weight == 3) = curChain;

% plot the graph
% figure;plot(G2, 'Layout', 'layered', 'EdgeCData', edgeCData2);
% figure;plot(G2, 'Layout', 'force');
