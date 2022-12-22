function allframes = get_allframes(obj)

allframes = [];
switch obj.dataset
    case {'human' 'human cropped'}
        allframes = 1000:8500;
    case 'pig'
        allframes = 55:9657;    
    otherwise
        fprintf(1, 'allframes not specified for dataset %s\n', obj.dataset)
end
