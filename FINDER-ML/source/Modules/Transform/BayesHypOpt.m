function [Datas, parameters] = BayesHypOpt(Datas, parameters, methods)

MA = optimizableVariable('MA', [1,parameters.data.numofgene], 'Type', 'Integer');
Mres = optimizableVariable('Mres', [1,parameter.data.numofgene], 'Type', 'Integer');

fun = @(MA, Mres) CVAccuracy(MA, Mres, Datas, parameters, methods);
result = bayesopt(fun,[MA, Mres], ...
    IsObjectiveDeterministic = true, ...
    AcquisitionFunctionName = expected-improvement',...
    NumCoupledConstraints = 1,...
    Verbose = false);

parameters.snapshots.k1 = result.XAtMinEstimatedObjective.MA;
parameters.multilevel.Mres = results.XAtMinEstimatedObjective.Mres;
end


function [objective, constraint] = CVAccuracy(MA, Mres, Datas, parameters, methods)

parameters.snapshots.k1 = MA;
%==========================================================================
%% Create CV partition object
%==========================================================================
Nfolds = 10;
for C = ["A", "B"]
cv.(C) = cvpartition(Datas.(C).Training, 'KFold', NFolds);
end

labels = []; predicted = [];

for i = 1:Nfolds

%==========================================================================
%% Organize Data into CovTraining, Machine, Test
%==========================================================================
for C = ["A", "B"]
    D0.(C).Training = Datas.(C).Training(:, cv.(C).training(i));
    D0.(C).Testing = Datas.(C).Training(:, cv.(C).test(i));
end
iCov = 1:length(D0.A.Training);
switch parameters.multilevel.splitTraining
    case true
        NB = size(D0.B.Training,2);
        iCov = iCov <= NB;
        iMachine = ~iCov;     
    case false
        iMachine = iCov;
end
D0.A.CovTraining = D0.A.Training(:, iCov);
D0.A.Machine = D0.A.Training(:, iMachine);
D0.B.CovTraining = D0.B.Training;
D0.B.Machine = D0.B.Training;

%=========================================================================
%% Project
%==========================================================================
switch parameters.multilevel.svmonly
    case 0 %MLS
        D0 = methods.Multi.CompMultiConstructFilter4(Datas, parameters, methods);
        D0 = methods.Multi2.SepFilter(Datas, parameters, methods);
        parameters.multilevel.eigentag = 'smallest';
    case 2 %ACA
        D0 = methods.Multi2.ConstructResidualSubspace(Datas, parameters, methods);
        parameters.multilevel.iMres = Mres;
        D0 = methods.Multi2.SepFilter(Datas, parameters, methods);
end
   
%==========================================================================
%% Train the SVM
%==========================================================================
D0 = methods.SVMonly.Prep(Datas, parameters, methods);
D0 = methods.SVMonly.fitSVM(Datas, parameters, methods);
array = methods.all.CompPredictAUC2(Datas, parameters, methods);
labels = [labels ; array(:,1)];
predicted = [predicted ; array(:,2)];

end

%==========================================================================
%% Compute Inverse Normal CDF of Accuracy
%==========================================================================

correct = labels == predicted;
accuracy = sum(correct) / length(correct);
objective = norminv(accuracy);

%==========================================================================
%% Label Constraint
%==========================================================================
constraint = MA - Mres - 0.5;


end