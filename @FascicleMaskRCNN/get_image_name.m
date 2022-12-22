function imgName = get_image_name(obj, frame)
switch obj.dataset
    case 'human'
        imgName = sprintf('%s%cHVRLN__rec%08d.tif', obj.imageFolder, filesep(), frame);
    case 'pig'
        imgName = sprintf('%s%cX_RCVN_Seg2__rec%08d.bmp', obj.imageFolder, filesep(), frame);
    case 'human cropped'
        loc = 1;
        imgName_ = sprintf('%s%cHVRLN__rec%08d_%d.tif', obj.imageFolder, filesep(), frame, loc);
        imgName = imgName_;
        while isfile(imgName_)
            loc = loc + 1;
            imgName_ = sprintf('%s%cHVRLN__rec%08d_%d.tif', obj.imageFolder, filesep(), frame, loc);
            if isfile(imgName_)
                if ~iscellstr(imgName)
                    imgName = [{imgName}; {imgName_}];
                else
                    imgName = [imgName; {imgName_}];
                end                
            end
        end
    otherwise
        imgName = '';
        fprintf(1, '%s not supported in load_image\n', obj.dataset);
end
