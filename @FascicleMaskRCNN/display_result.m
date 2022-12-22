function [masks, labels, scores, boxes, imTest] = display_result(obj, ax, dataset, iter, frame, scoreThresh)
if ~exist('dataset', 'var') || isempty(dataset)
    dataset = 'pig';
end
if ~exist('iter', 'var') || isempty(iter)
    iter = 100;
end
if ~exist('frame', 'var') || isempty(frame)
    frame = 55;
end
if ~exist('scoreThresh', 'var') || isempty(scoreThresh)
    scoreThresh = 0.1;
end

% determine if the network is already loaded
inds = ismember(obj.datasets, dataset) & ismember(obj.iters, iter);

if nnz(inds) == 0
    % need to load the network

    % get the mat file name from the dataset and frame
    switch dataset
        case 'pig1'
            % trained on first set of labeled frames
            D = dir(fullfile(obj.basepath, sprintf('naveenpig-*Epoch-%d.mat', iter)));
        case 'pig2'
            % trained on first two sets of labeled frames
            D = dir(fullfile(obj.basepath, sprintf('naveenpigData2-*Epoch-%d.mat', iter)));
        case 'human'
            D = dir(fullfile(obj.basepath, sprintf('trainedMaskRCNN*Epoch-%d.mat', iter)));
    end

    % load the network
    assert(length(D) == 1);
    fprintf(1, 'loading %s ...', fullfile(D.folder, D.name));
    load(fullfile(D.folder, D.name), 'net');
    fprintf(1, 'done\n');

    % append to the lists
    obj.nets = [obj.nets; net];
    obj.datasets = [obj.datasets; {dataset}];
    obj.iters = [obj.iters; iter];

    % store the index into obj.nets
    ind = length(obj.nets);
else
    % get the index into obj.nets
    assert(nnz(inds) == 1);
    ind = find(inds);
end

% load the test image based on frame
switch dataset
    case {'pig' 'pig1' 'pig2'}
        imageFolder = '\\TS1400R286.nslijhs.net\share\Pig x rcvn annotations\Raw file\X_RCVN_Seg2_Rec';
        imTest = imread(sprintf('%s%cX_RCVN_Seg2__rec%08d.bmp', imageFolder, filesep(), frame));
    case 'human'
        imageFolder = 'D:\Images 6000 -8500';
        % imageFolder = '\\TS1400R286.nslijhs.net\share\HVRLN_TL';
        imTest = imread(sprintf('%s%cHVRLN__rec%08d.tif', imageFolder, filesep(), frame));
end

if isa(imTest, 'uint16')
    imTest = uint8(255 * double(imTest) / 55000);
end
if size(imTest, 3) == 1
    imTest = repmat(imTest, [1 1 3]);
end

% segment the image
[masks, labels, scores, boxes] = segmentObjects(obj.nets(ind), imTest, 'Threshold', scoreThresh, 'MaxSize', [200 200], 'ExecutionEnvironment', 'auto');

% display the image
plotflag = false;
if plotflag
    figure(); ax = gca();
    imagesc(ax, sum(masks, 3)); colormap(ax, 'gray');
    %             inds = scores > scoreThresh;
    %             overlayedImage = insertObjectMask(imTest, masks(:, :, inds));
    %             imshow(overlayedImage);
    %             showShape("rectangle", gather(boxes(inds, :)), ...
    %                 "Label", labels(inds), "LineColor", 'r');
    title(ax, sprintf('frame %d, %d iterations, thresh %1.2f, %s', frame, iter, scoreThresh, dataset));
end
