function imgMean = get_imgMean(obj)
switch obj.dataset
    case 'pig'
        imgMean = 16;
    case 'human'
        imgMean = 81;
    case 'human cropped'
        imgMean = 81;  % I kept this the same even though it probably increased
    otherwise
        fprintf(1, '%s not supported in get_imgMean\n', obj.dataset);
end