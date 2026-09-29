function [Datas, parameters] = MLSFCT_FCD_CV(Datas, parameters, methods)
%Chooses Truncation parameter by finding the first index r such that the
%Fisher criterion (FC) of the rth feature exceeds 3 (when data is written
%in Class A eigenbasis. After choosing the truncation parameter, the
%residual components in the multilevel basis are computed. Then the
%features whose Fisher criterion exceeds the pth percentile are conserved.
%p is chosen through 10-Fold cross validation.
close all
if ~parameters.multilevel.chooseTrunc, return, end

MA = getMA(Datas,parameters,methods);
assert(~isempty(MA));
parameters.snapshots.k1 = MA; 
Datas = myMLS(Datas, parameters, methods);

%% Construct Combinations of Balances, Kernels, and Percentiles
%[Balances, Kernels, Percentiles] = meshgrid([0,1], [0,1], parameters.multilevel.concentration);
%BKP = [Balances(:), Kernels(:), Percentiles(:)];
[Kernels, Percentiles] = meshgrid([1,2], parameters.multilevel.concentration);
BKP = [Kernels(:), Percentiles(:)];
Accuracies = nan(size(BKP,1), 1);

%% Cross Validate
c = CreateCVPartition(Datas, parameters, methods);
FC = ComputeFC(Datas, "CovTraining");
%q = quantile(FC, pameters.multilevel.concentration);
%isNoisy = arrayfun(@(x) FC >= x, q, 'UniformOutput', false);
for iBKP = 1:size(BKP,1)
    parameters2 = parameters;
    parameters2.c = c;
    Datas2 = Datas;

    %parameters2.multilevel.splitTraining = BKP(iBKP,1);
    parameters2.svm.kernal = BKP(iBKP,1);
    parameters2.multilevel.concentration = BKP(iBKP, 2);
    q = quantile(FC, BKP(iBKP,2));
    isNoisy = FC >= q;
    for C = ["A", "B"]
    Datas2.(C).Machine = Datas2.(C).Machine(isNoisy,:);
    end

    Accuracies(iBKP) = MyCrossValidate(Datas2, parameters2, methods);
end


%% Assign Regime
[~,iBest] = max(Accuracies);
%parameters.multilevel.splitTraining = BKP(iBest,1);
parameters.svm.kernal = logical(BKP(iBest,1) - 1);
parameters.multilevel.concentration = BKP(iBest, 2);

%% Select Relevant Features
NoiseField = "CovTraining";
FC = ComputeFC(Datas, NoiseField);
q = quantile(FC,parameters.multilevel.concentration);
isNoisy = FC >= q;
for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set) = Datas.(C).(Set)(isNoisy,:);
end, end

%% Trick CompMultiSVM 
parameters.multilevel.Mres = sum(isNoisy);
parameters.multilevel.l = 0;

if ~parameters.parallel.on
figure()
for i = 1:2
plot(Accuracies(BKP(:,1) == i), LineWidth = 3, Marker = 'o'); 
hold on
end
legend("Linear", "RBF");
end

end
%==========================================================================
function FC = ComputeFC(Datas, NoiseField)
for C = ["A", "B"]
    m.(C) = mean(Datas.(C).(NoiseField),2);
    v.(C) = var(Datas.(C).(NoiseField),[],2);
end
FC = ((m.A - m.B).^2) ./ (v.A + v.B);
end
%==========================================================================
function MA = getMA(Datas,parameters,methods)

[U,~,~] = svd(Datas.A.CovTraining, 'econ', 'vector');
for C = ["A", "B"]
Datas2.(C).CovTraining = U'*Datas.(C).CovTraining;
end
%Datas2 = methods.Multi2.EigenbasisA(Datas, parameters, methods);
FC = ComputeFC(Datas2, "CovTraining");

MA = [];


figure(), plot(FC, LineWidth = 3), title('Fisher Criterion');
fcns = {@cummax,@cummin};
for i = 1:length(fcns)
FCm = fcns{i}(FC);
y = diff(FCm,2);
MA = find(abs(y) <= min(abs(y)), 1, 'first')+1;
if ~parameters.parallel.on
figure() 
plot(FCm, LineWidth = 3); hold on
title(func2str(fcns{i}));
scatter(MA, FCm(MA), 40, 'magenta', 'filled');
end
%figure(), plot(cummin(FC), LineWidth = 3), title('Cumulative Minimum');
%figure(), plot(cummax(FC), LineWidth = 3), title('Cumulative Maximum');

end

if isempty(MA)
 fprintf("i = %d, j = %d\n", parameters.data.i, parameters.data.j);
end

end


% thresh = 3.2;
% while isempty(MA)
% thresh = thresh - 0.2;
% MA = find(FC >= thresh, 1, 'first');
% end
% if MA == length(FC), MA = 1;  end
% end
%==========================================================================
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
%==========================================================================
function c = CreateCVPartition(Datas, parameters, methods)

Training = [Datas.A.Machine' ; Datas.B.Machine'];
NTrain = size(Training,1);
%Labels = 1:NTrain; Labels = Labels <= size(Datas.A.Machine,2);
Labels = [1:size(Datas.A.Machine,2), 1:size(Datas.B.Machine,2)]';
c = cvpartition(NTrain, Kfold = 10, GroupingVariables = Labels);
end
%==========================================================================
function accuracy = MyCrossValidate(Datas, parameters, methods)

c = parameters.c;
X = [Datas.A.Machine';Datas.B.Machine'];
Labels = 1:size(X,1); Labels = Labels <= size(Datas.A.Machine,2);
numFolds = parameters.c.NumTestSets;
Kernels = ["Linear", "Radial"];
accuracy = nan(1,numFolds);
for i = 1:numFolds
    Train = X(training(c,i),:);
    TrainLabels = Labels(training(c,i));
    Test = X(test(c,i),:);
    TestLabels = Labels(test(c,i));
    KernelField = "SVM_" + Kernels(parameters.svm.kernal);
    SVM = methods.misc.(KernelField)(Train,TrainLabels);
    Predictions = predict(SVM,Test);
    accuracy(i) = sum(Predictions(:) == TestLabels(:)) / length(TestLabels);
end
accuracy = mean(accuracy);

end
