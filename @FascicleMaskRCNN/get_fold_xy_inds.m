function [indsx, indsy] = get_fold_xy_inds(obj, ifold)
switch obj.dataset
    case 'human'        
        switch ifold
            case 1
                [indsx, indsy] = deal(700:1950, 150:800);                
            case 2
                [indsx, indsy] = deal(600:1850, 200:1150);                
            case 3                
                [indsx, indsy] = deal(750:1200, 550:1500);
            case 4
                [indsx, indsy] = deal(850:1400, 1050:1750);                
            case 3.4
                % combined folds 3 and 4
                [indsx, indsy] = deal(750:1400, 550:1750);
            case 5
                [indsx, indsy] = deal(1050:1550, 1350:1750);                
            otherwise
                [indsx, indsy] = deal(1:2000, 1:2000);
                fprintf(1, 'unrecognized fold %d\n', ifold);
        end
    case 'pig'
        fprintf(1, 'folds not yet defined for dataset %s', obj.dataset)
    otherwise
        fprintf(1, 'folds not yet defined for dataset %s', obj.dataset)
end