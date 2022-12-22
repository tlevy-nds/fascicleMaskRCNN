function nmf = netMatFile(obj, fold, stage)

if ~exist('stage', 'var') || isempty(stage)
    stage = 2;
end
nmf = sprintf('mat files\\fold%d\\%s_fold%d_stage%d.mat', fold, obj.dataset, fold, stage);
