function crop_images(obj, locations, newImageFolder, newGndTruthFolder)

if ~exist('locations', 'var') || isempty(locations)
    if isequal(obj.cropSize, [750 750])
        locations = cell(1, length(obj.allframes));
        for iframe = 1:length(obj.allframes)
            frame = obj.allframes(iframe);
            if frame >= 1000 && frame <= 1500
                locations{iframe} = [563 78 obj.cropSize];
            elseif frame <= 1600
                locations{iframe} = [566 114 obj.cropSize];
            elseif frame <= 1800
                locations{iframe} = [566 137 obj.cropSize];
            elseif frame <= 2100
                locations{iframe} = [552 146 obj.cropSize];
            elseif frame <= 3000
                locations{iframe} = [509 150 obj.cropSize];
            elseif frame <= 3200
                locations{iframe} = [486 213 obj.cropSize];
            elseif frame <= 3400
                locations{iframe} = [490 268 obj.cropSize];
            elseif frame <= 3500
                locations{iframe} = [481 306 obj.cropSize];
            elseif frame <= 3700
                locations{iframe} = [479 353 obj.cropSize];
            elseif frame <= 3800
                locations{iframe} = [479 395 obj.cropSize];
            elseif frame <= 4000
                locations{iframe} = [481 433 obj.cropSize];
            elseif frame <= 4100
                locations{iframe} = [500 480 obj.cropSize];
            elseif frame <= 4200
                locations{iframe} = [516 533 obj.cropSize];
            elseif frame <= 4300
                locations{iframe} = [529 564 obj.cropSize];
            elseif frame <= 4400
                locations{iframe} = [531 610 obj.cropSize];
            elseif frame <= 4500
                locations{iframe} = [561 650 obj.cropSize];
            elseif frame <= 4700
                locations{iframe} = [579 707 obj.cropSize];
            elseif frame <= 5100
                locations{iframe} = [589 764 obj.cropSize];
            elseif frame <= 5400
                locations{iframe} = [598 847 obj.cropSize];
            elseif frame <= 5600
                locations{iframe} = [630 931 obj.cropSize];
            elseif frame <= 5800
                locations{iframe} = [677 999 obj.cropSize];
            elseif frame <= 6000
                locations{iframe} = [730 1082 obj.cropSize];
            elseif frame <= 6500
                locations{iframe} = [817 1135 obj.cropSize];
            elseif frame <= 7800
                locations{iframe} = [896 1223 obj.cropSize];
            elseif frame <= 8500
                locations{iframe} = [969 1225 obj.cropSize];
            end
            
            if frame > 2100 && frame <= 2600
                locations{iframe} = [locations{iframe}; 1195 155 obj.cropSize];
            elseif frame <= 2800
                locations{iframe} = [locations{iframe}; 978 42 obj.cropSize];
            elseif frame <= 3000
                locations{iframe} = [locations{iframe}; 776 32 obj.cropSize];
            end
        end
    else
        return
    end
end

if ~isfolder(newImageFolder)
    mkdir(newImageFolder);
end
if ~isfolder([newGndTruthFolder filesep() 'matFiles'])
    mkdir([newGndTruthFolder filesep() 'matFiles']);
end

for iframe = 1:length(obj.allframes)
    frame = obj.allframes(iframe);
    imgName = obj.get_image_name(frame);
    A = imread(imgName);
    for iloc = 1:size(locations{iframe}, 1)
        xinds = locations{iframe}(1) + (0:locations{iframe}(3) - 1);
        yinds = locations{iframe}(2) + (0:locations{iframe}(4) - 1);

        % write the new image
        newFile = sprintf('%s%cHVRLN__rec%08d_%d.tif', newImageFolder, filesep(), frame, iloc);
        imwrite(A(yinds, xinds, :), newFile);

        % write the new ground truth
        [masks_, label_, bbox_, imageName] = obj.load_gnd_truth(frame, {'fascicle', 'fa on nerve', 'fa off nerve'});
        % TODO
        zinds = any(masks_(yinds, xinds, :), [1 2]);
        if nnz(zinds) > 0
            masks = masks(yinds, xinds, zinds);
            label = label_(zinds);
            bbox = bbox_(zinds, :);
            newgtFile = sprintf('%s%cmatFiles%clabel_%012d_%d.mat', newGndTruthFolder, filesep(), filesep(), frame, iloc);
            save(newgtFile, 'bbox', 'imageName', 'label', 'masks');
        end
    end
end
    
