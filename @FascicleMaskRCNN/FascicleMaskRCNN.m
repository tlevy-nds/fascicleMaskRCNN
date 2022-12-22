classdef FascicleMaskRCNN < handle
    % This class is responsible for training and evaluating the MaskRCNN network
    properties
        net       % the mask RCNN network
        epoch     % number of epochs the net has been trained on
        dataset   % {'human', 'pig'}        

        imageFolder     % folder containing the relevant images
        gndTruthFolder  % folder containing the ground truth mat files
        allframes

        cropSize
        locations
    end

    properties (Access=private)
        imgMean
        modelPrefix
    end

    methods
        function obj = FascicleMaskRCNN(dataset)
            obj.dataset = dataset;
            obj.imageFolder = obj.get_image_folder();
            obj.gndTruthFolder = obj.get_gnd_truth_folder();
            obj.imgMean = obj.get_imgMean();
            obj.modelPrefix = obj.get_model_prefix();
            obj.allframes = obj.get_allframes();
            obj.cropSize = obj.get_crop_size();            
        end

        % [masks, labels, scores, boxes, imTest] = display_result(obj, ax, dataset, iter, frame, scoreThresh)
        % detect_filter_within_frames(obj, frames, dataset, modelIter)
        % view_adj(obj, dataset, frames, gndTruthFrames)

        net = train(obj)
        tf = load_net(obj, fold)
        [masks, labels, scores, boxes] = segment_frames(obj, frames, offset)
        [mymasks, mylabels, myscores, myboxes, mytable] = segment_with_offsets(obj, frames, offsets)
        [gtmasks, gtlabels, gtboxes, gtImageNames] = load_all_gnd_truth(obj, frames)

        [gtMasks, gtlabels, gtbbox, gtimageName] = load_gnd_truth(obj, frame, keepLabels)
        show_gnd_truth_img(obj, frame)
        show_detection_img(obj, frame, masks, colchan)
        imgName = get_image_name(obj, frame)

        move_train_test_files(obj, trainInds)
        [trainInds, trainInds2, testInds] = get_trainInds(obj, ifold)
        [xinds, yinds] = get_fold_xy_inds(obj, ifold)
        ifold = get_fold(obj, frame)
        nmf = netMatFile(obj, fold, stage)

        crop_images(obj, locations)  % TODO create a new set of images and ground truth that can have mutliple crops per image
    end

    methods (Access=private)
        imageFolder = get_image_folder(obj)
        gndTruthFolder = get_gnd_truth_folder(obj)
        imgMean = get_imgMean(obj)
        modelPrefix = get_model_prefix(obj)
        allframes = get_allframes(obj)
        cropSize = get_crop_size(obj)
    end

    methods (Static, Access=private)
        imgProc = preprocess_image(img)        
    end
end