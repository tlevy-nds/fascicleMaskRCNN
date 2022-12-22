function load_net(obj, fold)
switch obj.dataset
    case 'human'        
        if isfile(obj.netMatFile(fold))
            load(obj.netMatFile(fold), 'net');
        else
            fprintf(1, '%s not found\n', obj.netMatFile(fold));
        end
        obj.epoch = 18;
    case 'pig'
        fprintf(1, 'net mat file not specified for %s\n', obj.dataset);
    otherwise
        fprintf(1, 'net mat file not specified for %s\n', obj.dataset);
end
obj.net = net;
