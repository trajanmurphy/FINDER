function ComputeWilcoxonRankAll


%% Define Iterators
Accs = ["AUC", "accuracy"];
[DS, DS2] = DefineDatasets;
Algos = ["MLS", "ACA-S", "ACA-L"];
Machines = ["SVM_Linear-PCA", "SVM_Radial-PCA", "SVM_Linear", "SVM_Radial", "LogitBoost", "RUSBoost", "Bag"];


%% Define Arrays
BenchArray = nan(length(DS), length(Machines), length(Accs));
FinderArray = nan(length(DS), length(Algos), length(Accs));
%SuperArray = repmat("", )
WSRTArray = nan(length(Algos), length(Machines), length(Accs));
%SuperArray = repmat("", size(WSRTArray));

%% Fill in Bench and Finder Arrays

for iDS = 1:length(DS)
    
    ds = DS(iDS); fprintf('Processing %s\n', ds);
    F0 = fullfile("..", "results2", "Manual_Hyperparameter_Selection", "Kfold");
    F1 = dir(fullfile(F0, ds, "**", "*.mat"));
    F1(matches({F1.name}, [".", ".."])) = [];
    isBench = contains({F1.name}, "Benchmark");
    BenchFiles = F1(isBench); FinderFiles = F1(~isBench);
    
for iAcc = 1:length(Accs)
        Acc = Accs(iAcc);

    Bench = load(fullfile(BenchFiles.folder, BenchFiles.name));
    BenchArray(iDS, :, iAcc) = Bench.results.(Acc);

for iAlgo = 1:length(Algos)


    Algo = Algos(iAlgo);
    AlgoF = FinderFiles(contains({FinderFiles.name}, Algo));
    Finder = arrayfun(@(x) load(fullfile(x.folder, x.name)), ...
                        AlgoF);
    Best = arrayfun(@(x) max(x.results.(Acc)), Finder);
    [~,iBest] = max(Best);
    Finder = Finder(iBest);
    FinderArray(iDS, iAlgo, iAcc) = max(Finder.results.(Acc));

    % superscript = "";
    % if Finder.parameters.multilevel.splitTraining
    %     superscript = superscript + "*";
    % end
    % if Finder.parameters.svm.kernal 
    %     superscript = superscript + "\\dagger";
    % end
    % SuperArray(iDS, iAlgo, iAcc) = superscript;

end
end
end

%SuperArray = "$^{" + SuperArray + "}$";

%% Compute Wilcoxon Signed Rank Test statistics:

for iAcc = 1:length(Accs)
    
for iAlgo = 1:length(Algos)
    
for iBench = 1:length(Machines)
    FinderAcc = FinderArray(:,iAlgo,iAcc);
    BenchAcc = BenchArray(:,iBench, iAcc);
    WSRTArray(iAlgo, iBench, iAcc) = signrank(BenchAcc, FinderAcc, 'tail', 'left');
end

end
end

%% Print Document
folder = fullfile(F0, "Graphs"); if ~isfolder(folder), mkdir(folder); end
fID = fopen(fullfile(folder, "Wilcoxon_Signed_Rank_Table.tex"), "w+");
PrintHeader(fID);
isSVM = contains(Machines, "SVM"); isSVM = [isSVM ; ~isSVM];

for iAlgo = 1:length(Algos)
    Algo = Algos(iAlgo);

    if mod(iAlgo, 2) == 1
        fprintf(fID, '\\rowcolor{blue!20}\n');
    end
    fprintf(fID, '%s ', Algo);

   
    
    for iAcc = 1:length(Accs)

        for iSVM = 1:size(isSVM,1)

        [pval, imax] = max(WSRTArray(iAlgo, isSVM(iSVM,:), iAcc));
        switch pval < 0.01
            case true, pval = "< 0.01";
            case false, pval = sprintf("%0.2f", pval);   
        end

        fprintf(fID, '& %s ', pval);
        
        end
        

    end
    fprintf(fID, '\\\\ \n');
end

fprintf(fID, '\\hline \n');
fprintf(fID, '\\end{tabular} \n');
fprintf(fID, '\\caption{Wilcoxon signed rank test for each FINDER method}\n');
fprintf(fID, '\\label{Wilcoxon Table}\n');
fprintf(fID, '\\end{table}');



end



%==========================================================================
function [DS, DS2] = DefineDatasets


A = ["AD", "AD", "CN"]; B = ["CN", "LMCI", "LMCI"];
DS(1:2) = ["GCM", "newAD"]; DS2 = DS(1:2);

DS(3:5) = "Plasma_M12_" + A + B;
DS2(3:5) = "ADNI (" + A + " vs. " + B + ")";

DS(6:8) = "SOMAscan7k_KNNimputed_" + A + "_" + B;
DS2(6:8) = replace(DS2(3:5), "ADNI", "CSF");
end
%==========================================================================
%==========================================================================
function PrintHeader(fID)

fprintf(fID, '\\begin{table}[h!]\n');
fprintf(fID, '\\centering \n');
fprintf(fID, '\\begin{tabular}{|c|c c|c c|} \n');
fprintf(fID, '\\hline \\rowcolor{olive!40} \n');
fprintf(fID, '& \\multicolumn{2}{|c|}{AUC} & \\multicolumn{2}{|c|}{Accuracy} \\\\ \n');
fprintf(fID, '\\hline \n\n \\hline \n \\rowcolor{gray!20} \n\n');
fprintf(fID, '& Best SVM & Best Boost/Bag & Best SVM & Best Boost/Bag \\\\ \n');
fprintf(fID, '\\hline \n\n \\hline \n');
end