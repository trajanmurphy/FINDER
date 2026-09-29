function [Datas, parameters] = MLS_FCT_FCD_CV2(Datas, parameters, methods)
%Chooses Truncation parameter among a subset of admissible values which maximizes
% the mean Fisher-Criterion per feature in the MLS basis
% After choosing the truncation parameter, the
%residual components in the multilevel basis are computed. Then the
%features whose Fisher criterion exceeds the pth percentile are conserved.
%p is chosen through 10-Fold cross validation.
close all
if ~parameters.multilevel.chooseTrunc, return, end

MA = getMA(Datas,parameters,methods);
assert(~isempty(MA));
parameters.snapshots.k1 = MA; 
Datas = myMLS(Datas, parameters, methods);



%% Cross Validate
c = CreateCVPartition(Datas, parameters, methods);
FC = ComputeFC(Datas, "CovTraining");
Accuracies = nan(size(parameters.multilevel.concentration));
for i = 1:length(parameters.multilevel.concentration)

    parameters2 = parameters;
    parameters2.c = c;
    Datas2 = Datas;
    p = parameters.multilevel.concentration(i);
    q = quantile(FC, p);
    isNoisy = FC >= q;
    for C = ["A", "B"]
    Datas2.(C).Machine = Datas2.(C).Machine(isNoisy,:);
    end

    Accuracies(i) = MyCrossValidate(Datas2, parameters2, methods);
end


%% Assign Regime
[~,iBest] = max(Accuracies);
parameters.data.accuracy = Accuracies(iBest);
parameters.multilevel.concentration = parameters.multilevel.concentration(iBest);

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
plot(Accuracies, LineWidth = 3, Marker = 'o');
%PrintCVInfo(Datas, parameters, methods);
else 
%PrintCVInfo(Datas, parameters, methods);
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
X.(C) = U' * Datas.(C).CovTraining;
V.(C) = var(X.(C),[],2);
EV.(C) = cumsum(V.(C)) ./ sum(V.(C));
EV.(C) = cumsum(V.(C)) ./ sum(var(Datas.(C).CovTraining,[],2));
end
QB = 0.1:0.1:0.90;

maxMA = min(floor(0.5 * size(Datas.A.CovTraining)));
MA0 = arrayfun(@(q) find(EV.B >= q,1, 'first'), QB, 'UniformOutput', false);
MA0 = [MA0{:}]; MA0 = MA0(:);
MA0 = unique(MA0);  
MA0 = MA0(MA0 <= maxMA);
MA0 = sort(MA0);

meanFC = nan(size(MA0));
for im = 1:length(MA0)
    parameters.snapshots.k1 = MA0(im);
    Datas2 = myMLS(Datas, parameters, methods);
    FC = ComputeFC(Datas2, "CovTraining");
    meanFC(im) = mean(FC);
end

iMA = find(islocalmax(meanFC), 1, 'first');
if isempty(iMA), [~,iMA] = max(meanFC); end
MA = MA0(iMA);


if ~parameters.parallel.on
    fprintf("i = %d, j = %d\n", parameters.data.i, parameters.data.j);
    figure(), FS = 10; MS = 8;

    subplot(2,1,1)
    ABdiff = abs(EV.A - EV.B); [~,im] = max(ABdiff);
    plot(EV.A, LineWidth = 3); hold on; plot(EV.B, LineWidth = 3); 
    legend(["A", "B"], AutoUpdate = "off");
    title('Explained Variance (Class B in Class A Eigenbasis)', FontSize = FS);
    xlabel('Truncation', FontSize = FS*1.3);
    ylabel('Explained Variance', FontSize = FS);
    for C = ["A", "B"]
    plot(MA0, EV.(C)(MA0),MarkerSize = MS, MarkerFaceColor = 'magenta', Marker = "s", LineStyle = "none");
    end
    plot([im,im], [EV.A(im), EV.B(im)], LineWidth = 3);


    subplot(2,1,2)
    plot(MA0, meanFC, LineWidth = 3, Marker = 's', MarkerSize = MS); hold on
    title('Mean Fisher Criterion', FontSize = FS*1.3);
    xlabel('$M_\textbf A$', Interpreter = "latex", FontSize = FS);
    ylabel('Fisher Criterion', FontSize = FS);
    plot(MA,meanFC(iMA),MarkerSize = MS, MarkerFaceColor = 'magenta', Marker = "s", LineStyle = "none");

end


end
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
    KernelField = "SVM_" + Kernels(parameters.svm.kernal + 1);
    SVM = methods.misc.(KernelField)(Train,TrainLabels);
    Predictions = predict(SVM,Test);
    accuracy(i) = sum(Predictions(:) == TestLabels(:)) / length(TestLabels);
end
accuracy = mean(accuracy);

end
%==========================================================================
function PrintCVInfo(Datas, parameters, methods)
MOE = string(func2str(methods.Multi.Filter));
parameters = methods.all.filefunc(parameters, methods);
TxtFolder = extractBefore(parameters.datafolder, parameters.data.label);
TxtFolder = fullfile(TxtFolder, "txt_files");
TxtName = "TruncStruct.mat";
TxtPath = fullfile(TxtFolder, TxtName);
if ~isfolder(TxtFolder), mkdir(TxtFolder); end

X = load(TxtPath);
TruncStruct = X.TruncStruct;
T = TruncStruct.(parameters.data.label);
irow = T.Balance == parameters.multilevel.splitTraining & ...
       T.Kernel == parameters.svm.kernal;

T(irow,:).Accuracy{1} = [T(irow,:).Accuracy{1}; parameters.data.accuracy];
T(irow,:).Truncation{1} = [T(irow,:).Truncation{1}; parameters.snapshots.k1];
T(irow,:).Threshold{1} =  [T(irow,:).Threshold{1}; parameters.multilevel.concentration];
T(irow,:).Dimension{1} = [T(irow,:).Dimension{1} ; parameters.multilevel.Mres];
T(irow,:).Time{1} = [T(irow,:).Time{1}; datetime(datestr(now))];
T(irow,:).Fold{1} = [T(irow,:).Fold{1} ; parameters.data.i, parameters.data.j];

TruncStruct.(parameters.data.label) = T;
save(TxtPath, "TruncStruct");


end
%==========================================================================
% function PrintCVInfo(Datas, parameters, methods)
% 
% MOE = string(func2str(methods.Multi.Filter));
% parameters = methods.all.filefunc(parameters, methods);
% TxtFolder = extractBefore(parameters.datafolder, parameters.data.label);
% TxtFolder = fullfile(TxtFolder, "txt_files");
% if ~isfolder(TxtFolder), mkdir(TxtFolder); end
% TxtName = MOE + ".txt"; 
% TxtPath = fullfile(TxtFolder, TxtName);
% fID = fopen(TxtPath, "a+");
% 
% fprintf(fID, "%s |", parameters.data.label);
% fprintf(fID, " Accuracy: %0.2f |", parameters.data.accuracy);
% fprintf(fID, " Balance: %d |", parameters.multilevel.splitTraining);
% fprintf(fID, " Kernel: %d |", parameters.svm.kernal);
% fprintf(fID, " Truncation: %d |", parameters.snapshots.k1);
% fprintf(fID, " Threshold: %0.2f |", parameters.multilevel.concentration);
% fprintf(fID, " Dimension: %d |", parameters.multilevel.Mres);
% fprintf(fID, " Time: %s |", datestr(now));
% fprintf(fID, " Fold: %d, %d|", parameters.data.i, parameters.data.j);
% fprintf(fID, "\n");
% fclose(fID);
%end
