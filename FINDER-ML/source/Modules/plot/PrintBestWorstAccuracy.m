function PrintBestWorstAccuracy
close all

%% Data Set parameters
p.DSidx = [1:8];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

p.alpha = [0.0001, 0.001, 0.05];
p.Markers = ["*", "**", "***"];

p = GetDataSets(p);

for iacc = 1:length(p.Accs)
    p.Acc = p.Accs(iacc);
    PrintHeadliner(p);

for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS); 
    p.da = p.DA(iDS);
    p.Trunc = p.Truncs(iDS);
    p = GetFiles(p);
    %fprintf(p.fID, "%s|", p.dt);
    PrintLeftMargin(p);
         
for iAlgo = 1:length(p.Algos)
    p.Algo = p.Algos(iAlgo); 
    p = GetPlotData(p);
    p = CreateEffectSizeMaps(p);
    PrintRow(p);          
end
fprintf(p.fID, "\\\\ \n");

end

end

%% Print Significance Codes
fprintf(p.fID, "\n Significance Codes: \n $");
for i = 1:length(p.Markers)
fprintf(p.fID, "^{%s}p < %0.g, \t", p.Markers(i), p.alpha(i));
end
fprintf(p.fID, "$\n");


end
%% ==========================================================================
%% ==========================================================================
function p = GetDataSets(p)
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
p.DS = DataSets;
p.DA = DataAliases;

fields = ["DS", "DA", "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

% padsize = max(strlength(p.DA));
% p.DT = pad(p.DA, padsize, "right");

p.Algos = ["MLS", "ACA-L"];
p.Finder = ["MLS", "ACA-S", "ACA-L"];
p.isFinder = @(A) ismember(A, p.Finder);
p.Accs = ["accuracy", "recall", "specificity", "precision"];

dagger = "$\dagger$";
p.Balances = ["", dagger]; 
p.Kernels = ["Lin", "RBF"];
p.Bfun = @(x) p.Balances(x.parameters.multilevel.splitTraining + 1);
p.Kfun = @(x) p.Kernels(x.parameters.svm.kernal + 1);
p.minmax = @(x) [min(x); max(x)];
p.isSVM = @(x) contains(x.parameters.misc.MachineList, "SVM");

p.Sources = ["Genetic", "Plasma", "CSF"];
p.Genetic.DS = p.DS(1:2);
p.Plasma.DS = p.DS(3:5);
p.CSF.DS = p.DS(6:8);
p.GetSource = @(DS) p.Sources(arrayfun(@(x) ismember(DS, p.(x).DS), p.Sources));

p.TableFolder = fullfile("..", p.Results, p.MOE, p.CrossVal, "Tables");
if ~isfolder(p.TableFolder), mkdir(p.TableFolder); end
p.TablePath = fullfile(p.TableFolder, "BestWorstAccuracy.tex");
p.fID = fopen(p.TablePath, "w+");
edit(p.TablePath);
end
%% ========================================================================
%% ========================================================================
function p = GetFiles(p)

%% Obtain Paths to results
folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X = dir(folderpath); 
X = fullfile({X.folder}, {X.name});   
XBench = X(contains(X,'Benchmark') &...
           contains(X,p.Normalized));
XBal = X(...
         contains(X,p.Nesting) & ...
         contains(X,p.Normalized) & ...
         contains(X,"Eigen-" + p.Trunc));
p.paths = vertcat(XBench, XBal{:});
assert(~isempty(p.paths), 'No paths found')

%% Initialize Arrays:
Y = load(p.paths{1});
Nalgos = length(p.Algos);
Nres = length(Y.parameters.multilevel.Mres);
Naccs = length(p.Accs);

[A,B] = meshgrid(Y.parameters.data.NAvals, Y.parameters.data.NBvals);

p.Pairs = [A(:), B(:)]; Npairs = size(p.Pairs,1);
p.LineGraphArray = nan(Nalgos,Nres,Naccs);
p.WilcoxonRArray0 = nan(Nalgos,Npairs,2);
p.KendallWArray0 = nan(Nalgos,Npairs,Nres);

end
%% ==========================================================================
%% ==========================================================================
function p = GetPlotData(p)

 %% Get Better performing Kernel
iAcc = p.Accs == p.Acc;
iAlgo = p.Algos == p.Algo;

if p.isFinder(p.Algo), idx = contains(p.paths, p.Algo);
else, idx = contains(p.paths, "Benchmark"); 
end

Paths = p.paths(idx);
X = cellfun(@load, Paths, "UniformOutput", false);

if ~ismember(p.Algo, p.Finder)
    X = X{1};
    switch p.Algo
    case "SVMs", isMachine = p.isSVM(X); 
    case "Boost/Bag", isMachine = ~p.isSVM(X);
    end
    Machines = X.parameters.misc.MachineList(isMachine);
    [~,iX] = min(X.results.errorRate(isMachine));
    BestMachine = Machines(iX);
    iX = find(X.parameters.misc.MachineList == BestMachine);
    p.ResultsArray = X.results.array(:,:,iX,:,:);
else
    [~,iX] = min(cellfun(@(x) min(x.results.errorRate), X));
    [~,p.BestMresIdx] = min(X{iX}.results.errorRate);
    p.ResultsArray = X{iX}.results.array;    
end

if ismember(p.Algo, p.Finder)
    X = X{iX};
    [p.(p.Acc)(1), p.iMres(1)] = max(X.results.(p.Acc));
    [p.(p.Acc)(2), p.iMres(2)] = min(X.results.(p.Acc));
    p.Mres = X.parameters.multilevel.Mres(p.iMres);
end 

p = FillEffectSizeArrays(p);

end
%% ========================================================================
%% ========================================================================
function p = FillEffectSizeArrays(p)

iAlgo = find(p.Algos == p.Algo);
Npairs = size(p.Pairs,1);
Nres = size(p.ResultsArray,3);
EFArray = nan(Npairs, Nres);
Accs = replace(p.Accs, "errorRate", "accuracy");

for ipair = 1:Npairs
pair = p.Pairs(ipair,:);

for iMres = 1:Nres
results.array = p.ResultsArray(pair(1), pair(2),iMres,:,:);
results = ComputeResultsAccuracy(results);
%accValues = arrayfun( @(A) results.(A), Accs);
EFArray(ipair,iMres) = results.(p.Acc); %accValues;
end
end

if p.isFinder(p.Algo)
p.KendallWArray0(iAlgo,:,:) = EFArray;
p.WilcoxonRArray0(iAlgo,:,:) = EFArray(:,p.iMres);
end

end
%% ========================================================================
%% ========================================================================
function p = CreateEffectSizeMaps(p)

Accs = replace(p.Accs, "errorRate", "accuracy");
iAlgo = p.Algos == p.Algo;
iAcc = p.Accs == p.Acc;

%% WR = Wilcoxon's R. KW = Kendall's W. EF = Effect Size. PV = p value
p.WREF = nan(length(p.Algos), length(Accs));
p.KWEF = nan(length(p.Algos), length(Accs));
p.WRPV = p.WREF;
p.KWPV = p.KWEF; 



    x = squeeze(p.WilcoxonRArray0(iAlgo,:,1));
    y = squeeze(p.WilcoxonRArray0(iAlgo,:,2));
    [p.WRPV(iAlgo, iAcc),~,stats] = signrank(x,y,tail = "both", method = "approximate");
    p.WREF(iAlgo, iAcc) = stats.zval / sqrt(length(x));



KendallMatrix = squeeze(p.KendallWArray0(iAlgo,:,:));
KendallMatrix = KendallMatrix';
[p.KWPV(iAlgo,iAcc), p.KWEF(iAlgo,iAcc)] = WeightedKendall(KendallMatrix);



for field = ["WR", "KW"]
    PVfield = field + "PV";
    EFfield = field + "EF";

    PV = discretize(p.(PVfield)(iAlgo, iAcc), [0, p.alpha], "categorical", [p.Markers]);
    PV = string(PV); 
    PV(ismissing(PV)) = "";

    p.(field)(iAlgo,iAcc) = compose("$%0.2f^{%s}$", p.(EFfield)(iAlgo,iAcc), PV);
end

end
%% ========================================================================
function PrintHeadliner(p)
Acc = upper(extractBefore(p.Acc,2)) + extractAfter(p.Acc,1);
fprintf(p.fID, "\\hline\n\\hline \n\n \\rowcolor{gray!40}" + ...
    "  \\multicolumn{8}{|c|}{ \\textbf{%s}} \\\\ \n"...
    ,Acc);
end
%% ========================================================================
function PrintLeftMargin(p)
Source = p.GetSource(p.ds);


if p.(Source).DS(1) == p.ds
    fprintf(p.fID, "\\hline \n \\hline \n");

    fprintf(p.fID, "\\multirow{%d}{4em}{\\textbf{%s}}", ...
        length(p.(Source).DS), ...
        Source);
end

DA = erase(p.da, ["CSF", "ADNI", "(", ")"]);
fprintf(p.fID, " & %s ", DA);


end
%% ========================================================================
function PrintRow(p)
iAlgo = p.Algos == p.Algo;
iAcc = p.Accs == p.Acc;
x1 = [p.(p.Acc)(:), p.Mres(:)];
%fprintf(p.fID, "& %0.3f ($\\Mres = %d$) ", x1(1,:), x1(2,:));
difference = p.(p.Acc)(1) - p.(p.Acc)(2);
fprintf(p.fID, " & %0.2f", difference);
for field = ["WR", "KW"]
fprintf(p.fID, "& %s ", p.(field)(iAlgo,iAcc));
end
%fprintf(p.fID, "\\\\ \n");

end


