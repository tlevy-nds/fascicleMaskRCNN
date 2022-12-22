function [gtmasks, gtlabels, gtboxes, gtImageNames] = load_all_gnd_truth(obj, frames)

[gtmasks, gtlabels, gtboxes, gtImageNames] = deal(cell(length(frames), 1));

for iframe = 1:length(frames)
    frame = frames(iframe);
    [masks_, gtlabels{iframe}, gtboxes{iframe}, gtImageNames{iframe}] = obj.load_gnd_truth(frame);  % only keep 'fascicle' label
    gtmasks{iframe} = arrayfun(@(imask) sparse(masks_(:, :, imask)), 1:size(masks_, 3), 'UniformOutput', false);

    if mod(iframe, 10) == 0
        fprintf(1, 'loading ground truth frame %d\n', frame);
    end
end
