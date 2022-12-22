function metrics = get_metrics(obj, imageNames)

N = sum(cellfun(@(x) length(x), obj.masks));
[kurt, skewness_, var_, mean_, area, circularity, eccentricity, irregularity, x, y, rmaj, rmin, myangle, myframe, solidity, contrast_, correlation_, energy, homogeneity, wx, wy] = deal(zeros(N, 1));
ct = 1;
for iframe = 1:length(obj.frames)
    frame = obj.frames(iframe);

    imgFileName = imageNames{iframe};
    A = imread(imgFileName);
    
    temp = cellfun(@(x) full(x), obj.masks{iframe}, 'UniformOutput', false);
    masks = cat(3, temp{:});
    
    for imask = 1:size(masks, 3)
        mask = masks(:, :, imask);
        if nnz(mask) == 0
            continue
        end

        % TODO graycomatrix and NaN not working
        % https://www.mathworks.com/matlabcentral/answers/510617-glcm-stats-with-a-mask
        % mask2 = cast(mask, class(A));
        mask2 = double(mask);
        mask2(mask2 == 0) = NaN;
        % randn(size(A))+0*double(A)
        glcms = graycomatrix(double(A) .* mask2, 'Offset', [0 7], 'NumLevels', 16, 'GrayLimits', []);  % 7 seems like a good choice based on the plots
        stats = graycoprops(glcms, 'all');

%         glcms = graycomatrix(double(A) .* mask2, 'Offset', [zeros(100, 1) (1:100)'], 'NumLevels', 16, 'GrayLimits', []);
%         glcms2 = graycomatrix(double(A) .* mask2, 'Offset', [(1:100)' zeros(100, 1)], 'NumLevels', 16, 'GrayLimits', []);
%         stats = graycoprops(glcms, 'all');
%         stats2 = graycoprops(glcms2, 'all');
%         figure;subplot(4, 1, 1);plot(stats.Contrast');title('Contrast');subplot(4, 1, 2);plot(stats.Correlation');title('Correlation');subplot(4, 1, 3);plot(stats.Energy');title('Energy');subplot(4, 1, 4);plot(stats.Homogeneity');title('Homogeneity');
%         figure(3);subplot(4, 1, 1);hold on;plot(stats2.Contrast');title('Contrast');subplot(4, 1, 2);hold on;plot(stats2.Correlation');title('Correlation');subplot(4, 1, 3);hold on;plot(stats2.Energy');title('Energy');subplot(4, 1, 4);hold on;plot(stats2.Homogeneity');title('Homogeneity');

        maskedImage = double(A) .* double(mask);
        pix = nonzeros(maskedImage);
        s = regionprops(uint8(mask), A, {'Centroid', 'Circularity', 'Eccentricity', 'Area', 'Orientation', 'MajorAxisLength', 'MinorAxisLength', 'Solidity', 'WeightedCentroid'});
        
        if length(s) > 1
            % This should never happen because I cast the mask to uint8 so
            % it is treated as a labeled image rather than a boolean image
            fprintf(1, 'should never happen\n');
            [~, mi] = max([s.Area]);
            s = s(mi);
        end

        B = bwboundaries(mask, 8);
        [~, mi] = max(cellfun(@(x) size(x, 1), B));
        rk2 = sum((B{mi} - s.Centroid).^2, 2);
        rk = sqrt(rk2);
        
        kurt(ct) = kurtosis(pix) - 3;
        skewness_(ct) = skewness(pix);
        var_(ct) = var(pix);
        mean_(ct) = mean(pix);
        area(ct) = s.Area;
        circularity(ct) = s.Circularity;
        eccentricity(ct) = s.Eccentricity;
        x(ct) = s.Centroid(1);
        y(ct) = s.Centroid(2);
        wx(ct) = s.WeightedCentroid(1);
        wy(ct) = s.WeightedCentroid(2);
        irregularity(ct) = sqrt(sum(rk2 - sum(rk).^2 / length(rk))) / sum(rk);
        myangle(ct) = s.Orientation;
        rmaj(ct) = s.MajorAxisLength;
        rmin(ct) = s.MinorAxisLength;
        solidity(ct) = s.Solidity;
        contrast_(ct) = stats.Contrast;
        correlation_(ct) = stats.Correlation;
        energy(ct) = stats.Energy;
        homogeneity(ct) = stats.Homogeneity;

        % how can irregularity be negative?
        myframe(ct) = frame;


        % figure;imagesc(double(A) .* double(mask)); colormap('gray');

        ct = ct + 1;
    end

    if mod(iframe, 10) == 0
        fprintf(1, 'frame %d\n', frame);
    end    
end
metrics = table(kurt, skewness_, var_, mean_, area, circularity, eccentricity, irregularity, ...
    x, y, rmaj, rmin, myangle, myframe, solidity, contrast_, correlation_, energy, homogeneity, wx, wy, ...
    'VariableNames', {'kurt', 'skewness', 'var', 'mean', 'area', 'circularity', 'eccentricity', 'irregularity', ...
    'x', 'y', 'rmaj', 'rmin', 'myangle', 'myframe', 'solidity', 'contrast', 'correlation', 'energy', 'homogeneity', 'wx', 'wy'});
