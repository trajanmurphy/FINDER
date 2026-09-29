function RankHyperparameterSelectionMethods

p.CrossVal = "Kfold";
p.Results = "results";
p.HoldOut = "Leave_5_out";
p.Accs = ["accuracy", "recall", "specificity", "precision", "run_time", "AUC", "F1Score"];%p.Accs = ["run_time"];

editRunTime = @(X4,X5) -seconds(X5) * X4.parameters.parallel.numofproc / ...
    (max(X4.parameters.data.NAvals) * max(X4.parameters.data.NBvals));

methods = DefineMethods;
DS = methods.data.all_files([1:6,8,10]); 
DS = DS(1:8);

D = methods.all.ValuesTable(...
    'Balance', {"Balanced","Unbalanced"},...
    'Kernel', {"Linear","Radial"},...
    'DataSet', DS);
HSM = "MLS_EVT_FCD" + string([1,3,5,6,7,10]);
Scores = zeros(size(HSM));

%Ranks = nan(length(HSM), height(D), length(p.Accs));
Ranks = nan(length(HSM), length(DS), length(p.Accs));


for Acc = p.Accs

iAcc = p.Accs == Acc;
for iD = 1:length(DS)

for iHSM = 1:length(HSM)

X0 = fullfile("..", p.Results,HSM(iHSM),p.CrossVal, DS{iD}, p.HoldOut, "**","*.mat");
X1 = dir(X0);
X2 = fullfile({X1.folder}, {X1.name});
X3 = cellfun(@load,X2, "UniformOutput", false);
[~,im] = min( cellfun(@(X) min(X.results.errorRate), X3));
X4 = X3{im};
X5 = X4.results.(Acc);

if Acc == "run_time"
X5 = editRunTime(X4,X5);
end

Ranks(iHSM, iD, iAcc) = X5;
end
end

end

R0 = tiedrank(Ranks);
Scores = mean(R0,[2,3]) / size(Ranks,1);
[Scores,iRank] = sort(Scores, "descend");
HSM = HSM(iRank);


for iHSM = 1:length(HSM)
fprintf('%s: %0.2f\n', HSM(iHSM), Scores(iHSM));
end



