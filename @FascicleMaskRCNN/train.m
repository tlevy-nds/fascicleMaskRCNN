function train(obj, trainFromScratch, falseAlarmLabels, saveEpochs, varargin)
% I need to add the path to the example for this to work, and there need to be GPU resources
% addpath('C:\Users\nds-remote\Documents\MATLAB\Examples\R2021b\deeplearning_shared\InstanceSegmentationUsingMaskRCNNDeepLearningExample')

if ~exist('trainFromScratch', 'var') || isempty(trainFromScratch)
    trainFromScratch = false;
end
if ~exist('falseAlarmLabels', 'var') || isempty(falseAlarmLabels)
    falseAlarmLabels = true;
end

unpackAnnotationDir = fullfile(obj.gndTruthFolder, 'matFiles');

%%
if falseAlarmLabels
    trainClassNames = {'fascicle', 'fa on nerve', 'fa off nerve'};
else
    trainClassNames = {'fascicle'};
end
numClasses = length(trainClassNames);

%% Train the network
switch obj.dataset
    case 'demo'        
        ds = fileDatastore(unpackAnnotationDir, 'ReadFcn', @(x) helper.cocoAnnotationMATReader(x, imageFolder));
        imageSizeTrain = [800 800 3];
    case {'pig', 'human'}
        bnds = [2000 2000];
        ds = fileDatastore(unpackAnnotationDir, 'ReadFcn', @(x) cocoAnnotationMATReader_v2(x, obj.imageFolder, bnds));
        imageSizeTrain = [bnds(2) - bnds(1) + 1, bnds(4) - bnds(3) + 1, 3];
end

% dsTrain = transform(ds,@(x) helper.preprocessData(x, imageSizeTrain));
dsTrain = transform(ds, @(x) preprocessData_v2(x, [], obj.imgMean));

data = preview(dsTrain);

% if  loadNet && ~exist('net', 'var')
%     basepath = 'C:\Users\nds-remote\Documents\objectDetection';
%     load('naveenpig-2022-02-04-17-48-20-Epoch-100.mat', 'net');
%     % load(sprintf('%s%ctrainedMaskRCNN-2022-01-22-05-15-34-Epoch-18.mat', basepath, filesep()), 'net');

if isempty(obj.net) || trainFromScratch
    obj.net = maskrcnn("resnet50-coco",trainClassNames,"InputSize",imageSizeTrain);
    obj.epoch = 0;
end

params = createMaskRCNNConfig(imageSizeTrain, numClasses, [trainClassNames {'background'}]);
params.ClassAgnosticMasks = false;
params.AnchorBoxes = obj.net.AnchorBoxes;
params.FreezeBackbone = true;

initialLearnRate = 0.000012;  % mini-batch loss was consistently NaN so try lowering this
momentum = 0.9;
decay = 0.01;
velocity = [];
maxEpochs = 10;
miniBatchSize = 1;  % Out of memory on device. To view more detail about available memory on the GPU

for ii = 1:2:length(varargin)
    switch lower(varargin{ii})
        case 'initiallearningrate'
            initialLearnRate = varargin{ii+1};
        case 'momentum'
            momentum = varargin{ii+1};
        case 'decay'
            decay = varargin{ii+1};
        case 'velocity'
            velocity = varargin{ii+1};
        case 'maxepochs'
            maxEpochs = varargin{ii+1};
        case 'minibatchsize'
            miniBatchSize = varargin{ii+1};
        otherwise
            fprintf(1, 'parameter %s not supported in train\n', varargin{ii});
    end
end

if ~exist('saveEpochs', 'var') || isempty(saveEpochs)
    saveEpochs = obj.epoch + [0:10:maxEpochs - 1, maxEpochs];
end

miniBatchFcn = @(img,boxes,labels,masks) deal(cat(4, img{:}), boxes, labels, masks);

mbqTrain = minibatchqueue(dsTrain, 4, ...
    "MiniBatchFormat", ["SSCB", "", "", ""], ...
    "MiniBatchSize", miniBatchSize, ...
    "OutputCast", ["single", "", "", ""], ...
    "OutputAsDlArray", [true, false, false, false], ...
    "MiniBatchFcn", miniBatchFcn, ...
    "OutputEnvironment", ["auto", "cpu", "cpu", "cpu"]);  % "OutputEnvironment",["auto","cpu","cpu","cpu"]);

%% Training
doTraining = true;
if doTraining

    iteration = 1;
    start = tic;

    % Create subplots for the learning rate and mini-batch loss
    fig = figure;
    [lossPlotter, learningratePlotter] = helper.configureTrainingProgressPlotter(fig);

    % Initialize verbose output
    helper.initializeVerboseOutput([]);

    % Custom training loop
    epoch0 = obj.epoch;
    try
        for epoch = epoch0 + (1:maxEpochs)
            reset(mbqTrain)
            shuffle(mbqTrain)

            while hasdata(mbqTrain)
                % Get next batch from minibatchqueue
                [X,gtBox,gtClass,gtMask] = next(mbqTrain);

                gtClass{1} = addcats(gtClass{1}, setdiff(trainClassNames, categories(gtClass{1})));

                if isempty(gtBox) || iscell(gtBox) && isempty(gtBox{1})
                    continue
                end

                % Evaluate the model gradients and loss using dlfeval
                [gradients, loss, state, learnables] = dlfeval(@networkGradients, X, gtBox, gtClass, gtMask, obj.net, params);
                %dlnet.State = state;

                % Compute the learning rate for the current iteration
                learnRate = initialLearnRate / (1 + decay * (epoch - 1));

                if(~isempty(gradients) && ~isempty(loss))
                    [obj.net.AllLearnables, velocity] = sgdmupdate(learnables, gradients, velocity, learnRate, momentum);
                else
                    continue;
                end

                % Plot loss/accuracy metric every 10 iterations
                if(mod(iteration, 1) == 0)
                    helper.displayVerboseOutputEveryEpoch(start, learnRate, epoch, iteration, loss);
                    D = duration(0, 0, toc(start), 'Format', 'hh:mm:ss');
                    addpoints(learningratePlotter, iteration, learnRate)
                    addpoints(lossPlotter, iteration, double(gather(extractdata(loss))))
                    subplot(2, 1, 2)
                    title(strcat("Epoch: ", num2str(epoch), ", Elapsed: " + string(D)))
                    drawnow
                end

                iteration = iteration + 1;
            end

            % Save the trained network
            modelDateTime = string(datetime('now', 'Format', "yyyy-MM-dd-HH-mm-ss"));
            % save(strcat("trainedMaskRCNN-",modelDateTime,"-Epoch-",num2str(epoch),".mat"),'net');            

            if ismember(epoch, saveEpochs)
                net = obj.net;
                save(strcat(obj.modelPrefix, modelDateTime, "-Epoch-", num2str(epoch), ".mat"), 'net');
            end

            obj.epoch = epoch;
        end
    catch ex
        if epoch > epoch0
            modelDateTime = string(datetime('now', 'Format', "yyyy-MM-dd-HH-mm-ss"));
            saveFile = strcat(obj.modelPrefix, modelDateTime, "-Epoch-", num2str(epoch), ".mat");
            fprintf(1, 'saving %s after error\n', saveFile);
            net = obj.net;
            save(saveFile, 'net');
        end 
        rethrow(ex);
    end

end