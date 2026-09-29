function [Datas, parameters] = MLS_EVT_FCD1(Datas, parameters, methods)
%Does not use Bayesian optimization. Simply utilizes parallelization to
%evaluate 

close all
if ~parameters.multilevel.chooseTrunc, return, end
t0 = tic; t1 = toc(t0);

parameters.snapshots.MAs = getMA(Datas,parameters,methods);
%Threshs = parameters.multilevel.concentation(:);

assert(~isempty(parameters.snapshots.MAs));

[MAs, Threshs] = meshgrid(parameters.snapshots.MAs, parameters.multilevel.concentration);
HypPairs = [MAs(:), Threshs(:)];
Accuracies = nan(length(HypPairs),1);

parfor i=1:length(Accuracies)
Accuracies(i) = AccFun(HypPairs(i,:), Datas, parameters, methods);
end

[~,imax] = max(Accuracies);
BestHyp = HypPairs(imax,:);

[Datas, parameters] = ChooseFeatures(BestHyp, Datas, parameters, methods);

if ~parameters.parallel.on
t2 = toc(t0);
fprintf("Elapsed Time: %0.2f s\n", t2 - t1);
fprintf("Best MA = %d. Best Thresh = %0.2f. Best Accuracy = %0.3f \n\n",...
    parameters.snapshots.k1, parameters.multilevel.Thresh, Accuracies(imax));
end

end
%% ========================================================================
function FC = ComputeFC(Datas, NoiseField)
for C = ["A", "B"]
    m.(C) = mean(Datas.(C).(NoiseField),2);
    v.(C) = var(Datas.(C).(NoiseField),[],2);
end
FC = ((m.A - m.B).^2) ./ (v.A + v.B);
end
%% ========================================================================
function MAs = getMA(Datas,parameters,methods)

[~,S,~] = svd(Datas.A.CovTraining,"econ", "vector");
EV = cumsum(S.^2) / sum(S.^2);
P = 2*parameters.multilevel.concentration;
Q = EV(1)*(1-P) + EV(end)*P;

maxMA = floor(0.1 * parameters.data.numofgene);
MA0 = arrayfun(@(q) find(EV >= q,1, 'first'), Q, 'UniformOutput', false);

MAs = unique([MA0{:}]); %MAs = MA0(MA0 <= maxMA);
%MAs = unique(MAs);  

if ~parameters.parallel.on
    figure(), FS = 10; MS = 8;    
    plot(EV, LineWidth = 3); hold on;  
    title('Class A Explained Variance', FontSize = FS*1.3);
    xlabel('Truncation', FontSize = FS);
    ylabel('Explained Variance', FontSize = FS);
    plot(MAs, EV(MAs),MarkerSize = MS, MarkerFaceColor = 'magenta', Marker = "s", LineStyle = "none");
    %plot(MAs, EV(MAs),MarkerSize = MS, MarkerFaceColor = [0.5,0,1], Marker = "s", LineStyle = "none");
end

end
%% ========================================================================
function Datas = myMLS(Datas, parameters, methods)

[U,~,~] = svds(Datas.A.CovTraining, parameters.snapshots.k1, 'largest');

[~,...
Datas.A.CovTraining,...
Datas.A.Machine,...
Datas.A.Testing,...
Datas.B.CovTraining,...
Datas.B.Machine,...
Datas.B.Testing] = ...
methods.Multi2.BinarySVD(...
U,...
Datas.A.CovTraining,...
Datas.A.Machine,...
Datas.A.Testing,...
Datas.B.CovTraining,...
Datas.B.Machine,...
Datas.B.Testing);

for C = ["A", "B"], for Set = ["CovTraining", "Machine", "Testing"]
Datas.(C).(Set)(1:parameters.snapshots.k1, :) = [];
end, end

end
%% ========================================================================
function Accuracy = AccFun(x, Datas, parameters, methods)

MA = x(1);
Thresh = x(2);

parameters.snapshots.k1 = MA; 
Datas2 = myMLS(Datas, parameters, methods);
FC = ComputeFC(Datas2, "CovTraining");
Quantile = quantile(FC, Thresh);
isNoisy = FC >= Quantile;
for C = ["A", "B"]
Datas3.(C).Machine = Datas2.(C).Machine(isNoisy,:);
end

%% Cross Validate
X = [Datas3.A.Machine';Datas3.B.Machine'];
Labels = 1:size(X,1); Labels = Labels <= size(Datas.A.Machine,2);

Kernels = ["Linear", "Radial"];
KernelField = "SVM_" + Kernels(parameters.svm.kernal + 1);
SVM = methods.misc.(KernelField)(X,Labels);
CVSVM = crossval(SVM);
ER = kfoldLoss(CVSVM);
Accuracy = 1 - ER;

end
%% ========================================================================
function [Datas, parameters] = ChooseFeatures(BestHyp, Datas, parameters, methods)
%% Select Relevant Features
parameters.snapshots.k1 = BestHyp(1);
Thresh = BestHyp(2);
Datas = myMLS(Datas, parameters, methods);
FC = ComputeFC(Datas, "CovTraining");
Quantile = quantile(FC, Thresh);
isNoisy = FC >= Quantile;
for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
Datas.(C).(Set) = Datas.(C).(Set)(isNoisy,:);
end, end

%% Trick CompMultiSVM 
parameters.multilevel.Thresh = Thresh;
parameters.multilevel.Mres = sum(isNoisy);
parameters.multilevel.l = 0;
end
%% ========================================================================
function stop = terminationFunc(results, state)
persistent bestObjective
stop = false;

if strcmp(state, 'iteration')
    if isempty(bestObjective) % True for first iteration
        bestObjective = results.ObjectiveMinimumTrace(end);
    else
        currentObjective = results.ObjectiveMinimumTrace(end);
        improvement = abs(currentObjective - bestObjective);

        % Check if improvement is less than the tolerance
        if improvement < 1e-5
            stop = true;  % Signal to stop optimization
        else
            bestObjective = currentObjective;
        end
    end
end
end