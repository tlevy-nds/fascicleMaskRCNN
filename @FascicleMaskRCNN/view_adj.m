function view_adj(obj, dataset, frames, gndTruthFrames)
switch dataset
    case 'human'
        
    case {'pig1' 'pig2'}            
        imageFolder = '\\TS1400R286.nslijhs.net\share\Pig x rcvn annotations\Raw file\X_RCVN_Seg2_Rec';
        gndTruthFolder = 'C:\Users\nds-remote\Desktop\For Todd\Try 3';
end

if ~exist('frames', 'var') || isempty(frames)    
    frames = 72:76;
end
if ~exist('gndTruthFrames', 'var') || isempty(gndTruthFrames)    
    gndTruthFrames = 72;
end

if length(frames) > 5
    fprintf(1, 'truncating frames\n');
    frames = frames(1:5);
end

figure(); 
clear('axs');

for iframe = 1:length(frames)
    frame = frames(iframe);

    % use ground truth if available, otherwise use segmentation result
    if ismember(frame, gndTruthFrames)
        A = imread(sprintf('%s%cX_RCVN_Seg2__rec%08d.tif', gndTruthFolder, filesep(), frame));
        outlinesMask = A(:, :, 2) > 200 & A(:, :, 1) < 50 & A(:, :, 3) < 50;
        mymasks = imfill(outlinesMask, 4, 'holes');
    else        
        temp = cellfun(@(x) full(x), obj.allmasksSparse{iframe + frameOffset + 1}, 'UniformOutput', false);
        mymasks = cat(3, temp{:});
    end

    % display the adjacent fascicles
    imTest = imread(sprintf('%s%cX_RCVN_Seg2__rec%08d.bmp', imageFolder, filesep(), frame));
    imTest = repmat(imTest, [1 1 3]);
    imTest(:, :, 2) = imTest(:, :, 2) + 128 * uint8(max(mymasks, [], 3));
    
    axs(iframe) = subplot(2, length(frames), iframe);
    imagesc(axs(iframe), imTest);
    title(axs(iframe), sprintf('Frame %d', frame));

    axs(iframe + 5) = subplot(2, length(frames), iframe + 5);
    imagesc(axs(iframe + 5), sum(mymasks, 3));
    colormap('gray');
end
linkaxes(axs);