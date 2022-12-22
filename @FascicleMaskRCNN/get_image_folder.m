function [imageFolder] = get_image_folder(obj)

[~, cmdout] = system('whoami');
switch strtrim(cmdout)
    case 'desktop-1d6i77c\nds-remote'
        switch obj.dataset
            case 'human'
                imageFolder = '\\TS1400R286.nslijhs.net\share\HVRLN_TL';
            case 'pig'
                imageFolder = '\\TS1400R286.nslijhs.net\share\Pig x rcvn annotations\Raw file\X_RCVN_Seg2_Rec';
            otherwise
                fprintf(1, '%s not supported\n', obj.dataset);
        end
    case 'laptop-g0ni05j8\cbem_ndda_l1'
        switch obj.dataset
            case 'human'
                imageFolder = 'D:\Images 1000-8500';
            case 'pig'
                imageFolder = 'D:\X_RCVN_Seg2_Rec';
            otherwise
                fprintf(1, '%s not supported\n', obj.dataset);
        end        
    otherwise
        switch obj.dataset
            case 'human'
                imageFolder = '/run/user/1002/gvfs/afp-volume:host=TS1400R286.local,user=shubham,volume=share/HVRLN_TL';
            case 'pig'
                imageFolder = '/run/user/1002/gvfs/afp-volume:host=TS1400R286.local,user=shubham,volume=share/Pig x rcvn annotations/Raw file/X_RCVN_Seg2_Rec';
            case 'human cropped'
                imageFolder = '/run/user/1002/gvfs/afp-volume:host=TS1400R286.local,user=shubham,volume=share/HVRLN_TL_cropped';
            otherwise
                fprintf(1, '%s not supported\n', obj.dataset);
        end
        % fprintf(1, '%s not recognized\n', strtrim(cmdout));
end