function WriteKendallWTable
close all
warning('off','all')

p.DSidx = [1:8];
p.alpha = [0.01, 0.05];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";
p.FontSize = "tiny";
p.tail = "both";

p = CreateDataLabels(p);
p = FillArray(p);

%% Create Tables
p.TableName = "KendallW";
p = GetfID(p);
PrintHeader(p);
PrintBody(p);
PrintFooter(p);
fclose all;

end

%==========================================================================
function p = CreateDataLabels(p)
%% Enter Data Set Info:
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
p.DS = DataSets;
p.DA = DataAliases;
p.isGenetic = ismember(p.DS, p.DS(1:2));
p.isPlasma = ismember(p.DS, p.DS(3:5));
p.isCSF = ismember(p.DS, p.DS(6:8));
p.Sources = ["Genetic", "Plasma", "CSF"];
fields = ["DS", "DA", "is" + p.Sources, "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

p.Balances = ["Balanced", "Unbalanced"];
p.Kernels = ["Linear", "Radial"];
p.Finder = ["MLS", "ACA-S", "ACA-L"]; 

p.Accs = ["accuracy", "recall", "specificity", "precision"];
p.DataTable = nan(length(p.Accs), length(p.DS), length(p.Finder),2);

p.Bins0 = [0.1, 0.3, 0.5];
p.Colors0 = ["white", "red", "yellow", "green"];
Colors0 = ["SectionBlue", "StrongCoral", "TableAmber", "StrongGreen"];

nBins = length(p.Bins0);
p.Bins = [-fliplr(p.Bins0), p.Bins0];
DarkColors = fliplr(Colors0(2:end)) + "!20";
LightColors = Colors0(2:end) + "!60";
p.Colors = [DarkColors, Colors0(1), LightColors];

end
%===========================================================================
function p = FillArray(p)
fprintf('Obtaining Performance Metrics\n');

for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS); 
    p.da = p.DA(iDS);
    p.Trunc = p.Truncs(iDS);
    fprintf("\t Processing %s\n", p.ds);

for iAcc = 1:length(p.Accs)
    p.Acc = p.Accs(iAcc);

for iAlgo = 1:length(p.Finder)
    p.Algo = p.Finder(iAlgo);
    p = GetPaths(p);
    load(p.Path);
    if iAlgo == 1
    [A,B] = meshgrid(parameters.data.NAvals,parameters.data.NBvals);
    p.pairs = [A(:), B(:)];
    p.Mres = parameters.multilevel.Mres;
    p.KendallMatrix = nan(length(p.Mres), size(p.pairs,1));
    end
   
for iLevel = 1:length(p.Mres)
for ipair = 1:size(p.pairs,1)
    iA = p.pairs(ipair,1); iB = p.pairs(ipair,2);
    r.array = results.array(iA,iB,iLevel,:,:);
    r = ComputeResultsAccuracy(r);
    if isnan(r.(p.Acc)), keyboard, end
    p.KendallMatrix(iLevel, ipair) = r.(p.Acc);   
end
end

    [pVal,W] = WeightedKendall(p.KendallMatrix);
    p.DataTable(iAcc, iDS, iAlgo,:) = [W,pVal];

end
end
end

end
%==========================================================================
function p = GetPaths(p)
folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X0 = dir(folderpath); 
Paths = fullfile({X0.folder}, {X0.name}); 

idx = contains(Paths, p.Normalized)...
    & contains(Paths, "Eigen-" + p.Trunc)...
    & contains(Paths, p.Algo);

Paths = Paths(idx);
X1 = cellfun(@load, Paths);    
[~, im] = min(arrayfun(@(x) min(x.results.errorRate), X1));
p.Path = Paths{im};   

end
%==========================================================================
function p = GetfID(p)
p.TableFolder = fullfile("..",p.Results,p.MOE, p.CrossVal, "Tables");

if ~isfolder(p.TableFolder), mkdir(p.TableFolder), end
Path = fullfile(p.TableFolder, p.TableName + ".tex");
p.fID = fopen(Path, "w+");
edit(Path); 
end
%==========================================================================
function PrintHeader(p)

%% Print Table "preamble"
fprintf(p.fID, "\\begin{%s}\n", p.FontSize);
fprintf(p.fID, '\\begin{longtable}[c]\n');

nDS = arrayfun(@(f) sum(p.("is" + f)), p.Sources);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.8em}",[1 x])), [1 nDS]);
columnstr(1) = "C{4.6em}";
columnstr = "|" + strjoin(columnstr,"||") + "|";

fprintf(p.fID, '{%s}\n',columnstr);
fprintf(p.fID, '\\hline \n \\rowcolor{StrongBlue}\n \\textbf{Metric}');

cellchars = repmat("|c||", size(p.Sources));
cellchars(end) = "|c|";
for i = 1:length(p.Sources)
fprintf(p.fID, " & \\multicolumn{%d}{%s}{\\textbf{%s}}",...
    nDS(i), cellchars(i), p.Sources(i));
end
fprintf(p.fID, '\\\\\n \\hline \n\n \\rowcolor{HeaderWhite} \n\n');

%% print actual datasets
pattern = ("ADNI "| "CSF "| "("| ")");
DataAliases = arrayfun(@(x) replace(x,pattern, ''), p.DA);

for i = 1:length(p.Sources)
Source = p.Sources(i);
DA = DataAliases(p.("is" + Source));
fprintf(p.fID, "& \\textbf{%s} ", DA);
end
fprintf(p.fID, " \\\\ \n \\hline");
end

%==========================================================================
function PrintBody(p)
for iAlgo = 1:length(p.Finder)
    p.Algo = p.Finder(iAlgo);
    %% Print Row Header;
    fprintf(p.fID, "\n\\hline " + ...
        "\\rowcolor{StrongBlue}" + ...
        "\\multicolumn{%d}{|c|}{\\textbf{%s}}" + ...
        "\\\\ \n \\hline ", ...
        length(p.DS) + 1, p.Algo);
    PrintData(p);
end
end
%==========================================================================
function PrintData(p)

capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Accs = p.Accs;
Accs = replace(Accs, "F1Score", "F1 Score");
Accs = capitalize(Accs);

%% p.DataTable(iAcc, iDS, iAlgo,:)
iAlgo = find(p.Finder == p.Algo);

%% Convert numeric arrays into parsable strings
Effect_Size = squeeze(p.DataTable(:,:, iAlgo, 1));
p_value = squeeze(p.DataTable(:,:, iAlgo, 2)); 
strFun = @(c,x,a) sprintf("\\cellcolor{%s} $%0.2f^{%s}$", c,x,a);

X = Effect_Size;
P = p_value;
C = discretize(X,[-Inf, p.Bins, Inf],"categorical",p.Colors);
A = string(discretize(P, [0, p.alpha, 1], "categorical", ["*", "**", "EMPTY"]));
A(A == "EMPTY") = "";
DataString = arrayfun(strFun, C,X,A);

%% Print data in table
fprintf(p.fID, "\n\\hline \n");
for iA = 1:length(Accs)
    fprintf(p.fID, "\\cellcolor{HeaderWhite} \\textbf{%s}", Accs(iA));
    fprintf(p.fID, " & %s ", DataString(iA,:));
    fprintf(p.fID, "\\\\ \n");
end
fprintf(p.fID, " \\hline\n");

end
%==========================================================================
function PrintFooter(p)

captionName = p.TableName + "_caption_string.txt";
captionFile = fullfile(p.TableFolder, captionName);
c = readlines(captionFile);

captionString = c(1); footnoteString = c(2);
footnoteString = sprintf(footnoteString,...
    p.TableName,...
    p.Colors0(2), p.Bins0(1), p.Bins0(2),...
    p.Colors0(3), p.Bins0(2), p.Bins0(3),...
    p.Colors0(4), p.Bins0(3),...
    p.alpha(1), p.alpha(2));

fprintf(p.fID, '\\caption{%s\\protect \\footnotemark}\n', captionString);
fprintf(p.fID, "\\label{%s}\n", p.TableName);
fprintf(p.fID, '\\end{longtable} \n');
fprintf(p.fID, "\\end{%s}\n\n", p.FontSize);
fprintf(p.fID, "\\footnotetext{%s}", footnoteString);


end
%==========================================================================