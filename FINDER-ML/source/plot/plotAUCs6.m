function plotAUCs6
%% Includes GCM and SVM with PCA
close all

nesting = 'Inner-Nesting';
TrimB = false;

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


DSidx = [1:8];
DataSets = DataSets(DSidx);
DataAliases = DataAliases(DSidx);



DA2 = [repmat("", size(DataAliases)) ; DataAliases ];




Balances = ["Balanced", "Unbalanced"];
Accs = ["F1score", "accuracy"];
Algos = ["MLS", "ACA" "Benchmark"];
switch TrimB, case true, nm = 11; case false, nm = 13; end
barArray = nan(length(DataSets), nm, 2, 2);
McNemar = barArray; Wilcoxon = barArray;

LineColors = DefineLineColors;

[f ax] = CreateFigure;

for iDS = 1:length(DataSets)
    barRow = barArray(iDS,:);
    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    
    X1 = GetFiles(DS, nesting);
    
 for iAcc = 1:length(Accs), Acc = Accs(iAcc);   
    for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);

        if Algo == "Benchmark"
            X2 = X1(contains({X1.name}, "Benchmark"));
            load(fullfile(X2.folder, X2.name));
            if TrimB, [parameters, results] = TrimBenchmark(parameters, results); end
            len = length(parameters.misc.MachineList) - 1;

            barArray(iDS, end-len:end, 1, iAcc) = results.(Acc);
        
        else


            for iB = 1:length(Balances), Balance = Balances(iB);
                X2 = X1(contains({X1.name}, Algo) & ...
                        contains({X1.folder}, Balance));
                X3 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X2);
                
                switch Algo
                    case "MLS", iBar = 1:2;
                    case "ACA", iBar = 3:6;
                end
               
                [barArray(iDS,iBar,iB, iAcc), imax] = arrayfun(@(x) max(x.results.(Acc)), X3);
               % McNemar(iDS, iBar,iB,iAcc) = arrayfun(@(x,y) x.results.("McNemar_pvalue_" + Acc)(y), X3, imax);
               % Wilcoxon(iDS, iBar,iB,iAcc) = arrayfun(@(x,y) x.results.("Wilcoxon_pvalue_" + Acc)(y), X3, imax);
            end

        end
    end

   
end

end

barArrayOld = barArray;
barArray = squeeze(max(barArray,[],3,"omitnan"));
for iAcc = 1:length(Accs)
    Acc = Accs(iAcc);



axes(ax(iAcc));
b = bar(DataAliases , barArray(:,:,iAcc) ,...
    'FaceColor', 'flat', 'LineWidth', 0.2);
    for k = 1:length(b), for j = 1:size(b(k).CData,1)
        b(k).CData(j,:) = LineColors(k,:); 
    end, end


if iAcc == 2
    arrayfun(@(B) set(B,'Interpreter', 'latex'), b)
end

ax(iAcc).YLabel.String = Acc;
end

FixAxes(ax, TrimB);

nesting = GetNesting(X1);
rF = extractBetween(X2(1).folder, 'Code/Code/', '/Manual_Hyperparameter_Selection'); rF = rF{1};
plotPath = fullfile('..',rF,'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
plotName = sprintf('Bar_Graph_%s.pdf', nesting);
if ~isfolder(plotPath), mkdir(plotPath), end


exportgraphics(f, fullfile(plotPath, plotName));

Headers = findall(f,'Type','Legend').String;
save(fullfile(plotPath, 'Bar_Graph_Data.mat'),'barArrayOld', 'Headers', 'McNemar', 'Wilcoxon');
close(f)



end

%==========================================================================

function LineColors = DefineLineColors

blue = [0.12, 0.21, 1]; %MLS
red = [1, 0.04, 0.12]; %ACA
gold = [0.85, 0.67, 0.2]; %Benchmark
violet = [0.5, 0.1, 0.8]; %PCA
white = [1, 1, 1];

t0 = [0.3;0.7];
t1 = [0.4;0.8];
t2 = [0.4;0.7;1];
%t2 = [0.2; 0.5; 1];

MLScolors = t1 .* blue;
ACAScolors = t1 .* red ;
ACALcolors = t0 .* white + (1-t0) .* red;
PCAcolors = t1 .* violet ; %+ (1-t1) .* violet;
SVMcolors = t0 .* white + (1-t0) .* violet; %t0 .* gold;
Othercolors = t2 .* gold; %t2 .* white + (1-t2) .* gold;

LineColors = [MLScolors;
    ACAScolors;
    ACALcolors;
    PCAcolors;
    SVMcolors;
    Othercolors];

end

%==========================================================================

function [f ax] = CreateFigure

f = figure('units','normalized','outerposition',[0 0 0.85 0.85]);
nax = 2;
for i = 1:nax, ax(i) = subplot(nax,1,i); end

end

%==========================================================================

function X = GetFiles(DS, nesting)
    %nesting = 'Unnested';
    resultFolder = 'Manual_Hyperparameter_Selection';
    CrossVal = 'Kfold';
    folderpath = fullfile('..', 'results', resultFolder, CrossVal, DS);
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
    %XB(contains({XB.name}, 'PCA')) = [];
    XN = X(contains({X.name}, nesting));
    X = [XB; XN];
end

%==========================================================================

function FixAxes(ax, TrimB)

%% Global Axes Parameters
YTicks = 0.5:0.05:1; YTickLabels = num2cell(YTicks); YTickLabels(2:2:end) = {''};

MarkerSize = 12;
xFS = 12;
yFS = 17;
tFS = 20;
lFS = 12;

axNames = {'YLim', 'YGrid', 'fontsize', 'YTickMode', 'ytick','YTickLabels'};
axValues = {[0.5, 1], 'on', 11, 'manual', YTicks, YTickLabels};
for iax = 1:length(ax)%, for idir = ["left", "right"]
%yyaxis(idir)
cellfun(@(x,y) set(ax(iax), x,y), axNames, axValues);
end%, end
%LineArgs = {'LineWidth', 3, 'Marker', 's', 'MarkerSize', MarkerSize, 'MarkerFaceColor', 'auto'};
AxlabelArgs = {'Interpreter', 'latex', 'FontSize'};


axes(ax(1))
title('FINDER vs. Benchmarks', AxlabelArgs{:}, tFS) 
legstr  = ["MLS-Lin", "MLS-RBF", "ACA-L-Lin", "ACA-L-RBF", "ACA-S-Lin", "ACA-S-RBF",...
           "SVM-Lin-PCA", "SVM-RBF-PCA", "SVM-Lin", "SVM-RBF",...
           "LogitBoost", "RUSBoost", "BAGging"];

if TrimB, legstr(contains(legstr, "PCA")) = []; end
ax(1).XTickLabel = {};
l = legend(legstr, 'Location', 'southoutside', ...
    'Orientation', 'Horizontal', AxlabelArgs{:}, lFS);
l.NumColumns = 5;
l.Position([1 2]) = [0.2442 0.47];
ylabel('AUC', AxlabelArgs{:}, yFS);


axes(ax(2))
ylabel('Accuracy', AxlabelArgs{:}, yFS);
ax(2).XLabel.FontSize = xFS;
ax(2).XAxis.TickLabelInterpreter = 'latex';

for i = 1:length(ax)
    currentYLim = ax(i).YLim;
    zoom(ax(i), 1.09);
    ax(i).YLim = currentYLim;
end

%ax(2).FontSize = xFS;

% ax1p = ax(1).Position;
% lp = l.Position;
% ax(1).Position([2 4]) = [lp(2) ax1p(4)];
% l.Position([2 4]) = [ax1p(2) lp(4)];



end

%=================
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
%=========================================================================
function [parameters, results] = TrimBenchmark(parameters, results)

if parameters.multilevel.svmonly ~= 1, return, end

isPCA = contains(parameters.misc.MachineList, "PCA");
parameters.misc.MachineList = parameters.misc.MachineList(~isPCA);
results.AUC = results.AUC(~isPCA);
results.accuracy = results.accuracy(~isPCA);

end
%==========================================================================