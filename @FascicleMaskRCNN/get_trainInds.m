function [trainInds, trainInds2, testInds] = get_trainInds(obj, ifold)
switch obj.dataset
    case {'human' 'human cropped'}
        switch ifold
            case 1
                trainInds = setdiff(obj.allframes, 1000:2499);  % stage 1 training
                trainInds2 = 1000:100:2500;                 % stage 2 transfer learning
                testInds = 1000:2499;                       % testing
            case 2
                trainInds = setdiff(obj.allframes, 2500:3999);
                trainInds2 = 2500:100:4000;
                testInds = 2500:3999;
            case 3
                trainInds = setdiff(obj.allframes, 4000:5499);
                trainInds2 = 4000:100:5500;
                testInds = 4000:5499;
            case 4
                trainInds = setdiff(obj.allframes, 5500:6999);
                trainInds2 = 5500:100:7000;
                testInds = 5500:6999;
            case 5
                trainInds = setdiff(obj.allframes, 7000:8500);
                trainInds2 = 7000:100:8500;
                testInds = 7000:8500;
            otherwise
                trainInds = [];
                fprintf(1, 'unrecognized fold %d\n', ifold);
        end
    case 'pig'
        fprintf(1, 'folds not yet defined for dataset %s', obj.dataset)
    otherwise
        fprintf(1, 'folds not yet defined for dataset %s', obj.dataset)
end