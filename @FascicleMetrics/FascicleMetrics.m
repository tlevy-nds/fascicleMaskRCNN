classdef FascicleMetrics < handle
    properties
        metrics
    end

    methods
        function obj = FascicleMetrics(metrics)
            
        end

        metric_filter(obj, metrics)
        G = track_metrics(obj, metrics)        
        [branches, merges] = detect_branches(obj, G)
    end
end
