function [Datas, parameters] = MLS_EVT_FCD2(Datas, parameters, methods)
%Chooses Truncation parameter by finding the first index r such that the
%explained Class B variance is 95% (CV with 0.6:0.05:1);
%After choosing the truncation parameter, the
%residual components in the multilevel basis are computed. Then the
%features whose Fisher criterion exceeds the pth percentile are conserved.
%p is chosen through 10-Fold cross validation.
close all
if ~parameters.multilevel.chooseTrunc, return, end

MAs = getMA(Datas,parameters,methods);
assert(~isempty(MAs));
BestAccuracy = 0;
BestMA = min(floor(0.2*size(Datas.A.CovTraining))); 
BestMres = true(parameters.data.numofgene,1);
c = CreateCVPartition(Datas, parameters, methods);

%% Cross Validate
for MA = MAs
    parameters2 = parameters;
    parameters2.snapshots.k1 = MA; 
    parameters2.c = c;

    Datas2 = myMLS(Datas, parameters2, methods);
    FC = ComputeFC(Datas2, "CovTraining");
    Quantiles = quantile(FC, parameters2.multilevel.concentration);
for q = Quantiles
    isNoisy = FC >= q;
    for C = ["A", "B"]
    Datas3.(C).Machine = Datas2.(C).Machine(isNoisy,:);
    end
    Accuracy = MyCrossValidate(Datas3, parameters2, methods);

    if Accuracy > BestAccuracy
        BestMA = MA;
        BestMres = isNoisy;
        BestAccuracy = Accuracy;
        BestThresh = parameters2.multilevel.concentration(Quantiles == q);

        if ~parameters.parallel.on
        fprintf("CV Accuracy: %0.2f, MA = %d, Mres = %d\n",...
            Accuracy, BestMA, sum(BestMres));
        end
    end

end
end


%% Select Relevant Features
parameters.snapshots.k1 = BestMA;
Datas = myMLS(Datas, parameters, methods);
for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
Datas.(C).(Set) = Datas.(C).(Set)(BestMres,:);
end, end

%% Trick CompMultiSVM 
parameters.multilevel.Mres = sum(isNoisy);
parameters.multilevel.l = 0;
parameters.multilevel.Thresh = BestThresh;

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
function MAs = getMA(Datas,parameters,methods)

Datas = methods.Multi2.EigenbasisA(Datas, parameters, methods);
VB = var(Datas.B.CovTraining,[],2);
EV = cumsum(VB) ./ sum(VB);
P = 2*parameters.multilevel.concentration;
Q1 = []; %1 - P; 
Q2 = EV(1)*(1-P) + P;
Q = [Q1(:),Q2(:)];


maxMA = floor(0.1 * parameters.data.numofgene);
MA0 = arrayfun(@(q) find(EV >= q,1, 'first'), Q, 'UniformOutput', false);

MA0 = unique([MA0{:}]); %MAs = MA0(MA0 <= maxMA);
MAs = MA0;
%MAs = unique(MAs);  

if ~parameters.parallel.on
    figure(), FS = 10; MS = 8;
    
    plot(EV, LineWidth = 3); hold on;  
    title('Class A Explained Variance', FontSize = FS*1.3);
    xlabel('Truncation', FontSize = FS);
    ylabel('Explained Variance', FontSize = FS);
    plot(MA0, EV(MA0),MarkerSize = MS, MarkerFaceColor = 'magenta', Marker = "s", LineStyle = "none");
    plot(MAs, EV(MAs),MarkerSize = MS, MarkerFaceColor = [0.5,0,1], Marker = "s", LineStyle = "none");

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
KernelField = "SVM_" + Kernels(parameters.svm.kernal + 1);
SVM = methods.misc.(KernelField)(X,Labels);
CVSVM = crossval(SVM);
ER = kfoldLoss(CVSVM);
accuracy = 1 - ER;

end
%==========================================================================

