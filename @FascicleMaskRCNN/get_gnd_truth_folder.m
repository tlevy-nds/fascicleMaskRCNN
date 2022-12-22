function gtFolder = get_gnd_truth_folder(obj)

[~, cmdout] = system('whoami');
switch strtrim(cmdout)
    case 'desktop-1d6i77c\nds-remote'
        switch obj.dataset
            case 'human'
                gtFolder = '\\TS1400R286.nslijhs.net\share\1000-8500 fa2\annotations_unpacked';
            case 'pig'
                fprintf(1, '%s not supported\n', obj.dataset);
            otherwise
                fprintf(1, '%s not supported\n', obj.dataset);
        end
    case 'laptop-g0ni05j8\cbem_ndda_l1'
        switch obj.dataset
            case 'human'
                % TODO images 5000 - 6000 are cropped
                gtFolder = 'D:\1000-8500 fa2\annotations_unpacked';
            case 'pig'
                gtFolder = 'D:\naveens pig vagus outlines\annotations_unpacked\matFiles';
            otherwise
                fprintf(1, '%s not supported\n', obj.dataset);
        end        
    otherwise
        switch obj.dataset
            case 'human'
                % TODO images 5000 - 6000 are cropped
                gtFolder = '/run/user/1002/gvfs/afp-volume:host=TS1400R286.local,user=shubham,volume=share/1000-8500 fa2/annotations_unpacked';
            case 'pig'
                fprintf(1, '%s not supported\n', obj.dataset);
            case 'human cropped'
                gtFolder = '/run/user/1002/gvfs/afp-volume:host=TS1400R286.local,user=shubham,volume=share/1000-8500 fa2/cropped/annotations_unpacked';
            otherwise
                fprintf(1, '%s not supported\n', obj.dataset);
        end
        % fprintf(1, '%s not recognized\n', strtrim(cmdout));
end
