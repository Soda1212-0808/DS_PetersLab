%% ============================================================
% WHEEL VELOCITY TRAJECTORY CLUSTERING
%
% Input:
%   velocity: nTrials x nTimepoints
%   Each row = one trial
%   Time aligned to first wheel movement
%   Signed velocity (positive / negative)
%
% Analysis:
%   1. Preprocessing
%   2. PCA
%   3. Optimal K selection
%   4. K-means clustering
%   5. Cluster stability
%   6. Mean trajectories
%   7. Trial heatmap
%   8. PCA visualization
%
% Required: Statistics and Machine Learning Toolbox

%% =========================
% 1. LOAD DATA
% ==========================

% Uncomment and modify if loading from a MAT file:
% load('wheel_velocity.mat', 'velocity');


velocity = double(cat(1,behavior.stim_move_aligned_wheel_vel{:}));

[nTrials, nTime] = size(velocity);

assert(nTrials >= 10, ...
    'At least 10 trials are recommended.');

assert(nTime >= 5, ...
    'Too few time points.');

assert(all(isfinite(velocity(:))), ...
    'Velocity contains NaN or Inf. Clean data first.');

fprintf('Number of trials: %d\n', nTrials);
fprintf('Number of timepoints: %d\n', nTime);
fprintf('Duration: %.3f s\n', nTime/surround_sample_rate);


%% =========================
% 2. PCA
% ==========================

% PCA centers each timepoint across trials.
% Do NOT z-score each trial.
% Preserve velocity amplitude and direction.

[coeff, score, latent, ~, explained, mu] = pca(velocity);

cumExplained = cumsum(explained);

nPC = find(cumExplained >= 95, 1, 'first');

if isempty(nPC)
    nPC = size(score, 2);
end

X = score(:, 1:nPC);

fprintf('Selected PCs: %d\n', nPC);
fprintf('Explained variance: %.2f%%\n', ...
    cumExplained(nPC));

figure('Color','w');
plot(cumExplained, 'ko-', 'LineWidth', 1.5);
hold on;
yline(95, 'r--', '95%');
xline(nPC, 'b--', sprintf('%d PCs', nPC));
xlabel('Number of PCs');
ylabel('Cumulative explained variance (%)');
title('PCA explained variance');
grid on;

%% =========================
% 3. OPTIMAL K SELECTION
% ==========================

Klist = 2:min(10, nTrials-1);

nK = numel(Klist);

silScores = nan(nK,1);
WSS = nan(nK,1);

for ii = 1:nK

    K = Klist(ii);

    [idx_temp, ~, sumd] = kmeans(X, K, ...
        'Distance', 'sqeuclidean', ...
        'Replicates', 30, ...
        'MaxIter', 1000, ...
        'Display', 'off');

    WSS(ii) = sum(sumd);

    % Average silhouette score
    s = silhouette(X, idx_temp, 'sqeuclidean');

    silScores(ii) = mean(s);

    fprintf('K=%d | Silhouette=%.3f | WSS=%.3f\n', ...
        K, silScores(ii), WSS(ii));

end

[~, bestIdx] = max(silScores);
bestK = Klist(bestIdx);

fprintf('\nBest K based on silhouette: %d\n', bestK);

figure('Color','w', 'Position',[100 100 1000 400]);

subplot(1,2,1);
plot(Klist, silScores, 'ko-', ...
    'LineWidth', 1.5);
hold on;
xline(bestK, 'r--');
xlabel('Number of clusters');
ylabel('Mean silhouette score');
title('Optimal K: Silhouette');
grid on;

subplot(1,2,2);
plot(Klist, WSS, 'ko-', ...
    'LineWidth', 1.5);
xlabel('Number of clusters');
ylabel('Within-cluster sum of squares');
title('Elbow method');
grid on;

%% =========================
% 5. FINAL K-MEANS
% ==========================

K = bestK;

[idx, C_pca, sumd] = kmeans(X, K, ...
    'Distance', 'sqeuclidean', ...
    'Replicates', 100, ...
    'MaxIter', 1000, ...
    'Display', 'final');

% Sort clusters by signed displacement
% This makes labels easier to compare across runs.

signedMovement = sum(velocity, 2) / surround_sample_rate;

clusterSignedMovement = zeros(K,1);

for k = 1:K
    clusterSignedMovement(k) = ...
        mean(signedMovement(idx == k));
end

[~, clusterOrder] = sort(clusterSignedMovement);

idx_sorted = zeros(size(idx));

for k = 1:K
    idx_sorted(idx == clusterOrder(k)) = k;
end

idx = idx_sorted;

clusterCounts = accumarray(idx, 1, [K 1]);

disp('Trials per cluster:');
disp(table((1:K)', clusterCounts, ...
    'VariableNames', {'Cluster','NTrials'}));

%% =========================
% 6. CLUSTER STABILITY
% ==========================

% Repeat clustering with different random seeds.
% Compare labels using Adjusted Rand Index (ARI).
%
% ARI = 1: identical partitions
% ARI ~ 0: chance-level agreement
%
% Stability is evaluated for the selected K.

nRepeat = 50;
ARI = zeros(nRepeat,1);

for r = 1:nRepeat

    rng(1000+r);

    idx_repeat = kmeans(X, K, ...
        'Distance', 'sqeuclidean', ...
        'Replicates', 1, ...
        'MaxIter', 1000, ...
        'Display', 'off');

    ARI(r) = adjusted_rand_index(idx, idx_repeat);

end

fprintf('\nClustering stability:\n');
fprintf('Mean ARI: %.3f\n', mean(ARI));
fprintf('Median ARI: %.3f\n', median(ARI));
fprintf('SD ARI: %.3f\n', std(ARI));

figure('Color','w');
histogram(ARI, 15);
xlabel('Adjusted Rand Index');
ylabel('Number of repetitions');
title(sprintf('K-means initialization stability, mean ARI=%.3f', ...
    mean(ARI)));
xlim([-0.1 1.05]);

%% =========================
% 7. CLUSTER MEAN TRAJECTORIES
% ==========================

colors = lines(K);

figure('Color','w', ...
    'Position',[100 100 1000 250*K]);

for k = 1:K

    subplot(K,1,k);
    hold on;

    Vk = velocity(idx == k, :);
    nk = size(Vk,1);

    meanV = mean(Vk,1);
    semV = std(Vk,0,1) / sqrt(nk);

    % Plot individual trials
    nShow = min(nk, 100);
    showIdx = randperm(nk, nShow);

    plot(surround_time_points, Vk(showIdx,:)', ...
        'Color',[0.8 0.8 0.8], ...
        'LineWidth',0.5);

    % SEM shading
    fill([surround_time_points fliplr(surround_time_points)], ...
        [meanV+semV fliplr(meanV-semV)], ...
        colors(k,:), ...
        'FaceAlpha',0.2, ...
        'EdgeColor','none');

    % Mean trajectory
    plot(surround_time_points, meanV, ...
        'Color',colors(k,:), ...
        'LineWidth',2.5);

    yline(0,'k--');

    title(sprintf('Cluster %d (n=%d)',k,nk));
    ylabel('Velocity');
    xlim([surround_time_points(1) surround_time_points(end)]);

    if k == K
        xlabel('Time from movement onset (s)');
    end

end

sgtitle('Wheel velocity trajectories by cluster');

%% =========================
% 8. CLUSTER-SORTED HEATMAP
% ==========================

% Sort by cluster, then signed displacement
sortMatrix = [idx, signedMovement];

[~, order] = sortrows(sortMatrix, [1 2]);

Vsorted = velocity(order,:);
idxHeat = idx(order);

% Symmetric velocity scale
maxV = prctile(abs(velocity(:)), 99);

if maxV <= 0
    maxV = 1;
end

% Custom blue-white-red colormap
nColor = 128;

blueWhite = [linspace(0,1,nColor)', ...
             linspace(0,1,nColor)', ...
             ones(nColor,1)];

whiteRed = [ones(nColor,1), ...
            linspace(1,0,nColor)', ...
            linspace(1,0,nColor)'];

cmap = [blueWhite; whiteRed];

figure('Color','w', ...
    'Position',[100 100 1000 700]);

imagesc(surround_time_points, 1:nTrials, Vsorted);
set(gca,'YDir','reverse');

colormap(cmap);
clim([-maxV maxV]);

cb = colorbar;
cb.Label.String = 'Signed wheel velocity';

hold on;

boundaries = cumsum(clusterCounts);

for k = 1:K-1
    yline(boundaries(k)+0.5, ...
        'k-', 'LineWidth', 1.5);
end

xlabel('Time from movement onset (s)');
ylabel('Trials sorted by cluster');
title('Cluster-sorted velocity heatmap');

%% =========================
% 9. PCA SCATTER
% ==========================

if size(score,2) >= 2

    figure('Color','w');
    hold on;

    for k = 1:K

        scatter(score(idx==k,1), ...
                score(idx==k,2), ...
                25, colors(k,:), 'filled', ...
                'MarkerFaceAlpha',0.65);

    end

    xlabel(sprintf('PC1 (%.1f%%)', explained(1)));
    ylabel(sprintf('PC2 (%.1f%%)', explained(2)));
    title('K-means clusters in PCA space');

    legend(compose('Cluster %d',1:K), ...
        'Location','best');

    grid on;

end

%% =========================
% 10. SAVE RESULTS
% ==========================

results = struct();

results.labels = idx;
results.K = K;
results.clusterCounts = clusterCounts;
results.velocitySmooth = velocity;
results.time = surround_time_points;
results.PCAcoeff = coeff;
results.PCAscore = score;
results.PCAmean = mu;
results.nPC = nPC;
results.explained = explained;
results.silhouette = silScores;
results.Klist = Klist;
results.WSS = WSS;
results.stabilityARI = ARI;

save('wheel_kmeans_results.mat','results');

fprintf('\nAnalysis completed.\n');


%% ============================================================
% LOCAL FUNCTION: ADJUSTED RAND INDEX
%% ============================================================

function ari = adjusted_rand_index(labels1, labels2)

    labels1 = labels1(:);
    labels2 = labels2(:);

    [~,~,a] = unique(labels1);
    [~,~,b] = unique(labels2);

    contingency = accumarray([a b], 1);

    nij = contingency(:);
    ai = sum(contingency,2);
    bj = sum(contingency,1);

    comb2 = @(x) x .* (x-1) / 2;

    sumNij = sum(comb2(nij));
    sumAi = sum(comb2(ai));
    sumBj = sum(comb2(bj));

    n = numel(labels1);
    totalPairs = comb2(n);

    expected = sumAi * sumBj / totalPairs;
    maxIndex = (sumAi + sumBj) / 2;

    denominator = maxIndex - expected;

    if abs(denominator) < 1e-12
        ari = double(sumNij == maxIndex);
    else
        ari = (sumNij - expected) / denominator;
    end

end
