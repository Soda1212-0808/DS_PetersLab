function [radius, center, diameterPx, fitRmse, diameterZ] = pupil_size(X, Y)
%FITCIRCLESTOFRAMES Fit circles to each frame from point sets X and Y.
%
% Inputs:
%   X, Y       - matrices of size [numPoints x numFrames]
%
% Outputs:
%   radius     - [numFrames x 1] fitted radius for each frame
%   center     - [numFrames x 2] fitted center [xc yc] for each frame
%   diameterPx - [numFrames x 1] fitted diameter in pixels
%   fitRmse    - [numFrames x 1] RMSE of radial residuals
%   diameterZ  - z-scored diameterPx across frames
thresh=20;


Xmedian=nanmedian(X,"all");
Ymedian=nanmedian(Y,"all");

idx_above_thres=sqrt((X-Xmedian).^2+(Y-Ymedian).^2)>thresh;

X(idx_above_thres)=nan;
Y(idx_above_thres)=nan;


% Basic checks
if ~isequal(size(X), size(Y))
    error('X and Y must have the same size.');
end

numFrames = size(X, 2);

% Preallocate
radius = nan(numFrames, 1);
center = nan(numFrames, 2);
diameterPx = nan(numFrames, 1);
fitRmse = nan(numFrames, 1);

for f = 1:numFrames
    xpts = X(:, f);
    ypts = Y(:, f);

    valid = ~isnan(xpts) & ~isnan(ypts);
    if nnz(valid) < 3
        continue;
    end

    xg = xpts(valid);
    yg = ypts(valid);

    % Algebraic least-squares fit
    A = [xg, yg, ones(length(xg), 1)];
    bvec = -(xg.^2 + yg.^2);

    p = A \ bvec;
    a = p(1);
    bpar = p(2);
    c = p(3);

    xc = -a / 2;
    yc = -bpar / 2;
    radTerm = (a^2 + bpar^2) / 4 - c;

    if radTerm <= 0
        continue;
    end

    R = sqrt(radTerm);

    % Store
    radius(f) = R;
    center(f, :) = [xc, yc];
    diameterPx(f) = 2 * R;

    % RMSE
    dists = hypot(xg - xc, yg - yc);
    residuals = dists - R;
    fitRmse(f) = sqrt(mean(residuals.^2));
end

% Z-score
mu = nanmean(diameterPx);
sig = nanstd(diameterPx);
if sig == 0 || isnan(sig)
    diameterZ = nan(size(diameterPx));
else
    diameterZ = (diameterPx - mu) ./ sig;
end
end