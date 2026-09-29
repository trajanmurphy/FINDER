function [Datas, parameters] = MLS_EVT_FCD4(Datas, parameters, methods)
%Same as MLS_EVT_FCD2 but a) uses Bayesian Optimization along with parallel
%processing to more effectively search the hyperparameter space b)
%searches over MA percentiles and FC percentiles of 0.1:0.1:0.9, c) bases
%MA off the proportion of Class B explained variance in the Class A
%Eigenbasis.

close all
if ~parameters.multilevel.chooseTrunc, return, end
t0 = tic; t1 = toc(t0);

parameters.multilevel.concentration = 0.1:0.1:0.9;
parameters.snapshots.MAs = getMA(Datas,parameters,methods);
assert(~isempty(parameters.snapshots.MAs));
Datas.c = CreateCVPartition(Datas, parameters, methods);
nMA = length(parameters.snapshots.MAs);

iMAs = optimizableVariable('iMA', [1, nMA], 'Type', 'integer');
iThreshs = optimizableVariable('iThresh', [1, length(parameters.multilevel.concentration)], 'Type', 'integer');

iMA = nMA; iThresh = 1;
InitialX = table(iMA, iThresh);


fun = @(x) BayesFun(x, Datas, parameters, methods);

result = bayesopt(fun,[iMAs, iThreshs] ...
    ,IsObjectiveDeterministic = true ...
    ,AcquisitionFunctionName = 'expected-improvement'...
    ...,NumCoupledConstraints = 0,...
    ,Verbose = 0 ...
    ,UseParallel = true...
    ,InitialX = InitialX...
    ,OutputFcn = @terminationFunc...
    );

iMA = result.XAtMinObjective.iMA;
iThresh = result.XAtMinObjective.iThresh;

[Datas, parameters] = ChooseFeatures(iMA, iThresh, Datas, parameters, methods);
Datas = rmfield(Datas, "c");

if ~parameters.parallel.on
t2 = toc(t0);
fprintf("\nMLS_EVT_FCD5 Elapsed Time: %0.2f s\n", t2 - t1);
fprintf("Best MA = %d. Best Thresh = %0.2f \n\n", parameters.snapshots.k1, parameters.multilevel.Thresh);
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

Datas = methods.Multi2.EigenbasisA(Datas, parameters, methods);
VB = var(Datas.B.CovTraining,[],2);
EV = cumsum(VB) ./ sum(VB);
P = parameters.multilevel.concentration;
Q = EV(1)*(1-P) + EV(end)*P;

maxMA = floor(0.1 * parameters.data.numofgene);
MA0 = arrayfun(@(q) find(EV >= q,1, 'first'), Q, 'UniformOutput', false);

MAs = unique([MA0{:}]);   

if ~parameters.parallel.on
    figure(), FS = 10; MS = 8;    
    plot(EV, LineWidth = 3); hold on;  
    title('Class A Explained Variance', FontSize = FS*1.3);
    xlabel('Truncation', FontSize = FS);
    ylabel('Explained Variance', FontSize = FS);
    plot(MAs, EV(MAs),MarkerSize = MS, MarkerFaceColor = 'magenta', Marker = "s", LineStyle = "none");
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
function c = CreateCVPartition(Datas, parameters, methods)
Training = [Datas.A.Machine' ; Datas.B.Machine'];
NTrain = size(Training,1);
Labels = [1:size(Datas.A.Machine,2), 1:size(Datas.B.Machine,2)]';
c = cvpartition(NTrain, Kfold = 10, GroupingVariables = Labels);
end
%% ========================================================================
function Accuracy = BayesFun(x, Datas, parameters, methods)

MA = parameters.snapshots.MAs(x.iMA);
Thresh = parameters.multilevel.concentration(x.iThresh);


parameters.snapshots.k1 = MA; 
Datas2 = myMLS(Datas, parameters, methods);
FC = ComputeFC(Datas2, "CovTraining");
Quantile = quantile(FC, Thresh);
isNoisy = FC >= Quantile;
for C = ["A", "B"]
Datas3.(C).Machine = Datas2.(C).Machine(isNoisy,:);
end

%% Cross Validate
c = Datas.c;
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
function [Datas, parameters] = ChooseFeatures(iMA, iThresh, Datas, parameters, methods)
%% Select Relevant Features
parameters.snapshots.k1 = parameters.snapshots.MAs(iMA);
Thresh = parameters.multilevel.concentration(iThresh);
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
        if improvement < 1e-3
            stop = true;  % Signal to stop optimization
        else
            bestObjective = currentObjective;
        end
    end
end
end