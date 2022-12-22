function [cropSize] = get_crop_size(obj)

switch obj.dataset
    case 'human'
        cropSize = [2000 2000];
        obj.locations = repmat({[1 1 2000 2000]}, [1 length(obj.allframes)]);
    case 'pig'
        cropSize = [2000 2000];
        obj.locations = repmat({[1 1 2000 2000]}, [1 length(obj.allframes)]);
    case 'human cropped'
        cropSize = [750 750];
        load('locations.mat', 'locations');
        obj.locations = locations;
    otherwise
        fprintf(1, '%s not supported\n', obj.dataset);
end
