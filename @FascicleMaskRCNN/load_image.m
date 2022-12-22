function img = load_image(obj, frame)
switch obj.dataset
    case 'human'
        imgName = sprintf('%s%cHVRLN__rec%08d.tif', obj.imageFolder, filesep(), frame);
    case 'pig'
        imgName = sprintf('%s%cX_RCVN_Seg2__rec%08d.bmp', obj.imageFolder, filesep(), frame);
    otherwise
        fprintf(1, '%s not supported in load_image\n', obj.dataset);
end
img = imread(imgName);
