function ifold = get_fold(obj, frame)
switch obj.dataset
    case 'human'        
        if frame >= 1000 && frame < 2500
            ifold = 1;
        elseif frame >= 2500 && frame < 4000
            ifold = 2;
        elseif frame >= 4000 && frame < 5500
            ifold = 3;
        elseif frame >= 5500 && frame < 7000
            ifold = 4;
        elseif frame >= 7000 && frame <= 8500
            ifold = 5;
        else
            fprintf(1, 'frame %d is outside of the valid range of frames', frame);
            ifold = 0;
        end
    case 'pig'
        fprintf(1, 'folds not yet defined for dataset %s', obj.dataset)
    otherwise
        fprintf(1, 'folds not yet defined for dataset %s', obj.dataset)
end