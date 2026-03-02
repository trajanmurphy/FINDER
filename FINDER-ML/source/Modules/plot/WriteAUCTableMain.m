function WriteAUCTableMain
close all

rF = 'results2';
nesting = 'Inner-Nesting';

DataSets = ["GCM", "newAD", ...
            arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]),...
            arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["AD_CN", "AD_LMCI", "CN_LMCI", "EMCI_LMCI", "AD_EMCI"]) ];

DataAliases = ["GCM", "newAD", ...
                arrayfun(@(x) sprintf("ADNI (%s)", x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"]),...
               arrayfun(@(x) sprintf("CSF (%s)",x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI", "EMCI vs. LMCI",  "AD vs. EMCI"])...
               ];


DSidx = 1:8;
DataSets = DataSets(DSidx);
DataAliases = DataAliases(DSidx);



DA2 = [repmat("", size(DataAliases)) ; DataAliases ];




Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];
Algos = ["MLS", "ACA-L", "ACA-S", "Benchmark"];

T = CreateEmptyTable(DataAliases);



for iDS = 1:length(DataSets)
    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    fprintf('Processing %s \n', DA);
    X1 = GetFiles(DS, nesting);
 
 for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);
 for iAcc = 1:length(Accs), Acc = Accs(iAcc);   

     X2 = X1(contains({X1.name}, Algo));
     X3 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X2);

     if Algo == "Benchmark"
         T.(Acc)(Algo, :).(DA){1} = X3.results.(Acc)';
     else
         X4 = arrayfun(@(x) max(x.results.(Acc)), X3);
         T.(Acc)(Algo, :).(DA){1} = X4;
     end

end

end
end

T = GetBestClassifier(T);
fileID = GetFileID(rF);
PrintTable(fileID, T);
end



%==========================================================================
function T1 = CreateEmptyTable(DataAliases)
T0 = cell(5,length(DataAliases));
T0 = cell2table(T0);
T0.Properties.RowNames = ["MLS", "ACA-S", "ACA-L", "Benchmark", "Max"];
T0.Properties.VariableNames = DataAliases;
T1 = struct('AUC', T0, 'accuracy', T0);
end
%==========================================================================

function fileID = GetFileID(rF)
TablePath = fullfile('..',rF,'Manual_Hyperparameter_Selection', 'Kfold', 'Tables', 'Performance_Table.tex');
fileID = fopen(TablePath, "w+");
end

%==========================================================================

function X = GetFiles(DS, nesting)
    %nesting = 'Unnested';
    resultFolder = 'Manual_Hyperparameter_Selection';
    CrossVal = 'Kfold';
    folderpath = fullfile('..', 'results2', resultFolder, CrossVal, DS);
    X = dir(folderpath); X(matches({X.name}, [".", ".."])) = [];
    Leave_K_out = {X.name};
    K = cellfun(@(x) extractBetween(x, 'Leave_', '_out'), Leave_K_out);
    Ks = cellfun(@str2num, K); %Ks = Ks(Ks > 1);
    [K, iK] = min(Ks); %min(cellfun(@str2num, K));
    Leave_K_out = sprintf('Leave_%d_out', K);%Leave_K_out{iK};
    folderpath = fullfile(folderpath, Leave_K_out, '**');
    X = dir(folderpath); 
    X(matches({X.name}, [".", ".."])) = []; 
    X(~contains({X.name}, '.mat')) = [];
    XB = X(contains({X.name}, 'Benchmark'));
    XB(contains({XB.name}, 'PCA')) = [];
    XN = X(contains({X.name}, nesting));
    X = [XB; XN];
end

%==========================================================================

function nesting = GetNesting(X)

X(contains({X.name}, 'Benchmark')) = [];
%svmonly = arrayfun(@(x) x.parameters.multilevel.svmonly, X);
load(fullfile(X(1).folder, X(1).name));


switch parameters.multilevel.nested
    case 0, nesting = 'Unnested';
    case 1, nesting = 'Inner-Nesting';
    case 2, nesting = 'Outer-Nesting';
end
end

%==========================================================================
function PrintHeader(fileID, T)
% Headers = ["MLS-Lin", "MLS-RBF",...
%             "ACA-L-Lin", "ACA-L-RBF", "ACA-S-Lin", "ACA-S-RBF",...
%             "SVM-Lin", "SVM-RBF", "Logit Boost", "RUS Boost", "BAG ging"];
columnstr = repmat("",[1 width(T)+2]);
columnstr([3 7]) = "|";
columnstr(columnstr == "") = "C{3.5em}";
columnstr = strjoin(columnstr);
%columnstr(columnstr == "") = T.Properties.VariableNames;

%Print Table "preamble"
fprintf(fileID, ['\\begin{table} [h] \n'...
    '\\centering \n'...
    '\\begin{tabular}{|C{4.9em}| %s |} \n'...
    %'\\hline \n'...
    %'\\rowcolor{olive!40} \n'...
    '\\hline \n'], columnstr); 

%Print macro grouping of datasets
fprintf(fileID, [ ...
    '\\rowcolor{olive!40} \n'...
    'Method'...
    ' & \\multicolumn{2}{|c|}{Genetic}' ...
    ' & \\multicolumn{3}{|c|}{Proteomic (ADNI)}' ...
    ' & \\multicolumn{3}{|c|}{CSF}' ...
    '\\\\ \n \\hline \n']);

%print actual datasets
Machines = string(T.Properties.VariableNames);
pattern = ("ADNI "| "CSF "| "("| ")");
Machines = arrayfun(@(x) replace(x,pattern, ''), Machines);

fprintf(fileID,  '\\rowcolor{gray!20} \n  ');
fprintf(fileID, '& %s ', Machines);
fprintf(fileID, ' \\\\ \n \\hline');
end
%==========================================================================

function PrintRow(fileID, T)

MLA = ["L-PCA", "R-PCA", "SVM-L", "SVM-R", "Log", "RUS", "BAG"];
fprintf(fileID, '%s ', T.Properties.RowNames{1});
%Data = table2array(T); [maxData, im] = max(Data);

% maxData = varfun(@(x) max(x{1}), T);
% maxData = table2array(maxmaxData);
% [maxData, im] = max(Data);


for id = string(T.Properties.VariableNames)
    Data = T(1,:).(id){1};
    [Data2, im] = max(Data);
    maxData = T("Max",:).(id){1};
    
    if Data2 == maxData
        fprintf(fileID, ' & \\textbf{%0.3f}', Data2);
    else
        fprintf(fileID, ' & %0.3f', Data2);
    end  

if T.Properties.RowNames{1} == "Benchmark"
fprintf(fileID, ' %s', MLA(im));
end
end



fprintf(fileID, ' \\\\ \n');

end
%==========================================================================
function PrintDataSetHeader(fileID, T)
end
%==========================================================================
function PrintRowColor(fileID, DS)
methods = DefineMethods;

   if ismember(DS, ["GCM", "newAD"])
        rowColor = 'violet!30';
   elseif ismember(DS, methods.data.ADNI_files)
        rowColor = 'blue!20';
   elseif ismember(DS, methods.data.CSF_files)
        rowColor = 'teal!40';
   end

   fprintf(fileID, '\\rowcolor{%s} \n', rowColor);
end
%==========================================================================
function bool = RestartColoring(DS)
methods = DefineMethods;
bool = any(...
    [strcmp(DS, "GCM"),     
    ismember(DS, methods.data.ADNI_files{1}),
    ismember(DS, methods.data.CSF_files{1})]...
   )
end
%==========================================================================
function PrintAccuracyRow(fileID, Acc, T)
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

fprintf(fileID, ['\n \\hline' ...
    '\\rowcolor{gray!40}' ...
    '\\multicolumn{%d}{|c|}{%s}' ...
    '\\\\ \\hline \\hline \n \n'], ...
    width(T) + 1, capitalize(Acc));
end
%==========================================================================
function T = GetBestClassifier(T)

for Acc = ["AUC", "accuracy"]
   T1 = table2cell(T.(Acc));
   T2 = cellfun(@max, T1(1:4,:));
   T3 = max(T2, [], 1);
   T1(end,:) = num2cell(T3);
   T4 = cell2table(T1);
   for i = ["RowNames", "VariableNames"]
       T4.Properties.(i) = T.(Acc).Properties.(i);
   end
   T.(Acc) = T4;
end



end
%==========================================================================
function PrintTable(fileID, T)


MLA = ["L-PCA", "R-PCA", "SVM-L", "SVM-R", "Log", "RUS", "BAG"];


PrintHeader(fileID, T.AUC);


for Acc = ["AUC", "accuracy"]
    PrintAccuracyRow(fileID, Acc, T.(Acc));
for ir = 1:height(T.AUC)-1
    if mod(ir, 2) == 1, fprintf(fileID, '\\rowcolor{blue!20} \n'); end
    PrintRow(fileID, T.(Acc)([ir end],:));
end
fprintf(fileID, '\n \\hline \n');
end


end
%==========================================================================


