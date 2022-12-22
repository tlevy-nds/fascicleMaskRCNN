function [x, y, frame] = plot_graph(G, CentroidTable)
% T = dfsearch(gtG, 1, 'allevents', 'Restart', true);
[x, y, frame] = deal({[] [] []});  % within track w = 1, connection between track endpoints w = 2, branch w = 3
% visited = zeros(size(gtCentroidTable, 1), 1, 'logical');
prevCtInds = [];
for iedge = 1:G.numedges
    ctInds = G.Nodes.trackInds(G.Edges.EndNodes(iedge, :));
    myInds = setdiff(ctInds, prevCtInds);
    prevCtInds = ctInds;

    w = G.Edges.Weight(iedge);
    if ~isempty(x{w}) && length(myInds) == 2 || w ~= 1
        x{w} = [x{w}; NaN];
        y{w} = [y{w}; NaN];
        frame{w} = [frame{w}; NaN];
    end
    if w ~= 1
        myInds = ctInds;
        prevCtInds = [];
    end
    x{w} = [x{w}; CentroidTable.x(myInds)];
    y{w} = [y{w}; CentroidTable.y(myInds)];
    frame{w} = [frame{w}; CentroidTable.frame(myInds)];
    % visited(myInds) = true;
    if mod(iedge, 1000) == 0
        fprintf(1, 'edge %d of %d\n', iedge, G.numedges);
    end
end

figure();
plot3(x{1}, y{1}, frame{1}, 'b-');
hold on;
plot3(x{2}, y{2}, frame{2}, 'g-'); 
plot3(x{3}, y{3}, frame{3}, 'r-');
hold off;
