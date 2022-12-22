function [masks, label, bbox, imageName] = load_gnd_truth(obj, frame, keepLabels)

if ~exist('keepLabels', 'var') || isempty(keepLabels)
    keepLabels = {'fascicle'};
end

foundFile = false;
subdirs = {'matFiles', 'holdout'};
for isubdir = 1:length(subdirs)
    subdir = subdirs{isubdir};
    switch obj.dataset
        case 'human'
            matName = sprintf('%s%c%s%clabel_%012d.mat', obj.gndTruthFolder, filesep(), subdir, filesep(), frame);
        case 'pig'
            fprintf(1, '%s not supported in load_image\n', obj.dataset);
        otherwise
            fprintf(1, '%s not supported in load_image\n', obj.dataset);
    end
    if isfile(matName)
        foundFile = true;
        break
    end
end

if foundFile
    load(matName, 'bbox', 'imageName', 'masks', 'label');
    inds = ismember(label, keepLabels);
    masks = masks(:, :, inds);
    bbox = bbox(inds, :);
    label = label(inds);
else
    fprintf(1, 'matfile not found in %s\n', obj.gndTruthFolder);
    [bbox, imageName, masks, label] = deal([]);
end
