function modelPrefix = get_model_prefix(obj)
switch obj.dataset
    case 'human'
        modelPrefix = 'trainedMaskRCNN-';
    case 'pig'
        modelPrefix = 'naveenpigData2-';
    case 'human cropped'
        modelPrefix = 'human_cropped_stage2-';
    otherwise        
        fprintf(1, 'unspecified model predix for dataset %s\n', obj.dataset);
end
