function G = tracks_to_graph(obj, tracks, keepInds, frameThresh, dthresh)
% loop over each track
% compare each endpoint of the current track to the same frame on other
% tracks or to the endpoint of the other track if it is within nframes
% if the distance between masks is less than distThresh then mark as branch
% if in the middle of the other track or connect the tracks if between the
% endpoints

[Ns, N, firstFrameInd, lastFrameInd] = obj.get_track_frames();

if ~exist('keepInds', 'var') || isempty(keepInds)    
    keepInds = tracks > 0;  % true(N, 1);
end

temp = arrayfun(@(frames, reps) repmat(frames, [reps 1]), obj.frames, Ns, 'UniformOutput', false);
myframes = cat(1, temp{:});  % frame numbers for each detection in tracks

% initialize the Graph for each track
G = graph();  % TODO add all nodes, and edges within tracks
trackIds = unique(tracks(keepInds));

% Ground truth can contain -1
trackIds = trackIds(trackIds > 0);

for itrack = 1:length(trackIds)
    trackInds = find(tracks == trackIds(itrack));
    [~, si] = sort(myframes(trackInds));
    curNode = G.numnodes;
    % nodes correspond to the variable tracks
    G = addnode(G, table(trackInds, repmat(trackIds(itrack), [nnz(trackInds) 1]), 'VariableNames', {'trackInds' 'trackId'}));
    G = addedge(G, curNode + si(1:length(si)-1), curNode + si(2:length(si)), 1);
end

% loop over each track
endpointops = {@min @max};
for itrack = 1:length(trackIds)
    trackInds = find(tracks == trackIds(itrack));

    % loop over each endpoint
    for iendpoint = 1:length(endpointops)
        endpointop = endpointops{iendpoint};
        [curFrame, mi] = endpointop(myframes(trackInds));
        curNode = find(G.Nodes.trackInds == trackInds(mi));
    
        % indices into track and keepInds with the current endpoint frame
        iframe = obj.frames == curFrame;
        frameInds = myframes == curFrame;        

        % determine which masks to use
        maskInds = keepInds(frameInds) & tracks(frameInds) == trackIds(itrack);

        % in the event that there are multiple masks then take the union
        temp = cellfun(@(x) full(x), obj.masks{iframe}(maskInds), 'UniformOutput', false);
        masks = cat(3, temp{:});        
        endpointMask = max(masks, [], 3);
        D1 = bwdist(endpointMask);

        % loop over the other tracks
        for itrack2 = setdiff(1:length(trackIds), itrack)
            trackInds2 = find(tracks == trackIds(itrack2));

            % find the closest frame to curFrame
            compareFrames = myframes(trackInds2);
            [frameDist, mi2] = min(abs(compareFrames - curFrame));
            compareNode = find(G.Nodes.trackInds == trackInds2(mi2));

            % If the frames are close
            if frameDist < frameThresh
                closestFrame = compareFrames(mi2);

                % indices into track and keepInds with the current endpoint frame
                iframe2 = obj.frames == closestFrame;
                frameInds2 = myframes == closestFrame;

                % determine which masks to use
                maskInds2 = keepInds(frameInds2) & tracks(frameInds2) == trackIds(itrack2);

                % in the event that there are multiple masks then take the union
                temp = cellfun(@(x) full(x), obj.masks{iframe2}(maskInds2), 'UniformOutput', false);
                masks = cat(3, temp{:});
                compareMask = max(masks, [], 3);
                
                % determine the distances between the compare mask and the endpoint mask
                D2 = bwdist(compareMask);
                inds = (D1 > D2);
                d = min(D1(inds)) + min(D2(~inds));

                % if the masks are close
                if d < dthresh
                    if frameDist > 0
                        % connect: add edge between endpoint and the other track at the same frame
                        w = 2;
                        fprintf(1, 'connection between %d and %d\n', trackIds(itrack), trackIds(itrack2));
                    else
                        % branch: add edge between the endpoints
                        w = 3;
                        fprintf(1, 'branch between %d and %d\n', trackIds(itrack), trackIds(itrack2));
                    end
                    if ~ismember(compareNode, neighbors(G, curNode))
                        G = addedge(G, curNode, compareNode, w);
                    end
                end
            end
        end
    end
    fprintf(1, 'track %d of %d\n', itrack, length(trackIds));
end