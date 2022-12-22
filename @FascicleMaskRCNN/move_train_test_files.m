function move_train_test_files(obj, trainInds)

D1 = dir(sprintf('%s%c%s%clabel_*.mat', obj.gndTruthFolder, filesep(), 'holdout', filesep()));
D2 = dir(sprintf('%s%c%s%clabel_*.mat', obj.gndTruthFolder, filesep(), 'matFiles', filesep()));
f1 = cellfun(@(x) sscanf(x, 'label_%012d'), {D1.name});
f2 = cellfun(@(x) sscanf(x, 'label_%012d'), {D2.name});

fs = sort([f1 f2]);

testInds = setdiff(fs, trainInds);

for ii = 1:length(fs)
    curFrame = fs(ii);
    moveflag = false;
    filename1 = sprintf('%s%c%s%clabel_%012d.mat', obj.gndTruthFolder, filesep(), 'matFiles', filesep(), curFrame);
    filename2 = sprintf('%s%c%s%clabel_%012d.mat', obj.gndTruthFolder, filesep(), 'holdout', filesep(), curFrame);
    if ismember(curFrame, trainInds)        
        if isfile(filename1)            
            % file is in the correct folder
            assert(~isfile(filename2));
        elseif isfile(filename2)
            % file needs to be moved
            assert(~isfile(filename1));
            moveflag = true;
            src = filename2;
            dest = filename1;
        end
    elseif ismember(curFrame, testInds)
        if isfile(filename1)
            % file needs to be moved
            assert(~isfile(filename2));
            moveflag = true;
            src = filename1;
            dest = filename2;
        elseif isfile(filename2)
            % file is in the correct folder
            assert(~isfile(filename1));
        end
    else
        fprintf(1, 'frame %d is not a member of train or test\n', curFrame);
    end
    if moveflag
        movefile(src, dest);
    end
    if mod(ii, 100) == 0
        fprintf(1, 'frame %d of %d\n', ii, length(fs));
    end    
end

