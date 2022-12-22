function gtMasks = get_gnd_truth(dataset, frame)
% read from mask images instead

[~, cmdout] = system('whoami');
switch strtrim(cmdout)
    case 'desktop-1d6i77c\nds-remote'
        switch dataset
            case 'human'
                gtFolder = '\\TS1400R286.nslijhs.net\share\1000-8500 fa2\annotations_unpacked';
            case 'pig'
                
            otherwise
                fprintf(1, '%s not supported\n', dataset);
        end
    case 'laptop-g0ni05j8\cbem_ndda_l1'
        switch dataset
            case 'human'
                % TODO images 5000 - 6000 are cropped
                gtFolder = 'D:\1000-8500 fa2\annotations_unpacked';
            case 'pig'
                
            otherwise
                fprintf(1, '%s not supported\n', dataset);
        end        
    otherwise
        fprintf(1, '%s not recognized\n', strtrim(cmdout));
end



% [status, cmdout] = system('whoami');
% switch strtrim(cmdout)
%     case 
% end
% sz = [2000 2000];
% 
% switch dataset
%     case 'human'
%         load('gthuman.mat', 'G');
%         inds = find(G.Nodes.frame == frame);
%         gtMasks = zeros([sz length(inds)], 'logical');
%         for imask = 1:length(inds)
%             ind = inds(imask);
%             roi = images.roi.Ellipse('Center', [G.Nodes.X(ind),  G.Nodes.Y(ind)], ...
%                 'SemiAxes', [G.Nodes.diameterX(ind)  G.Nodes.diameterY(ind)], ...
%                 'RotationAngle', G.Nodes.angle(ind));
%             gtMasks(:, :, imask) = roi.createMask(sz(1), sz(2));
%         end
%     case {'pig1' 'pig2'}
%         % load the image, threshold the green, fill the regions, and get
%         % the connected components
% end