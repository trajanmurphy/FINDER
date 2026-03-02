function plotAUCs2
close all

rF = 'results';
lFS = 12;
TrimB = false;

nesting = 'Inner-Nesting';
DSidx = [1:5, 11,9,8]; 
resultFolder = 'Manual_Hyperparameter_Selection';
Balances = ["Balanced", "Unbalanced"];
Accs = ["F1score", "accuracy"];
Algos = ["MLS", "ACA-S", "ACA-L", "Benchmark"];

DataSets = ["GCM", "newAD", ...
            arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]),...
            arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["EMCI_LMCI", "CN_EMCI", "CN_LMCI", "AD_LMCI", "AD_EMCI", "AD_CN"]) ];

DataAliases = ["GCM", "newAD", ...
                arrayfun(@(x) sprintf("ADNI (%s)", x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"]),...
               arrayfun(@(x) sprintf("CSF (%s)",x),...
               ["EMCI vs. LMCI", "CN vs. EMCI", "CN vs. LMCI", "AD vs. LMCI", "AD vs. EMCI", "AD vs. CN"])...
               ];

%% Iterate over ADNIs, Balances, and Accuracy measures

DataSets = DataSets(DSidx); DataAliases = DataAliases(DSidx);


fileIDs = OpenFileIDs(rF, nesting);
Best = MakeBestStruct(DataSets);
Best = arrayfun(@(b,d) setfield(b, 'DS', d), Best, DataSets);
Best = arrayfun(@(b) setfield(b, 'nesting', nesting), Best);

for iDS = 1:length(DataSets)
    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    Best(iDS).DS = DS;
   
    
    f = figure('units','normalized','outerposition',[0.05 0.1 0.8 0.6]);

    

iplot = 0;

for iacc = 1:length(Accs)
    Acc = Accs(iacc);
    

plotData = cell(1,4);
for iBalance = 1:length(Balances)
        iplot = iplot + 1;
        ax = subplot(2,2,iplot); hold on,
        
        %if ismember(iplot, [2 4]), ax.Position(1) = 0.53; end
        Balance = Balances(iBalance);
        X2 = GetFiles(DS, Balance, rF, nesting);
        %if skipDS, continue, end
        assert(~isempty(X2), 'X2 is empty')

        legstr = [];
        for iAlgo = 1:length(Algos)
            Algo = Algos(iAlgo); X3 = X2(contains({X2.name}, Algo));
            

            assert(~isempty(X3), 'X3 is empty')
            [x1, y1, l] = GetPlotData(X3, Acc, Algo);
            legstr = [legstr, l];


        %% Set up axes
       
        PlotOnAxes(DA, Balance, x1, y1, iAlgo, ax, iplot, Acc);
        Best(iDS) = UpdateBest(Best(iDS), x1, y1, l, Acc, Balance);
                               
      
        end

l = legend(legstr,...
    'Location', 'eastoutside',...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.9*[1 1 1]);

end


end

FixAxes(f);


plotPath = fullfile('..',rF,resultFolder,'Kfold','Graphs');
if ~isfolder(plotPath), mkdir(plotPath), end
%exportgraphics(f, fullfile(plotPath, sprintf('%s_%s.pdf', DS, nesting)));
close(f)


end


for iDS = 1:length(DataSets)
    DS = DataSets(iDS); DA = DataAliases(iDS);
    fileID = GetFileID(DA, fileIDs);
    WriteFigureLatex(fileID, DS, DA, Best(iDS));
end
fclose all;

save(fullfile(plotPath, 'BestStruct.mat'), 'Best');



end


%==========================================================================
%==========================================================================
function Best = MakeBestStruct(DS)

for Acc = ["AUC", "accuracy", "F1score"];
%Best.(Acc).DS = [];
Best.(Acc).Performance = 0;
Best.(Acc).Algo = [];
Best.(Acc).Mres = [];
Best.(Acc).Balance = [];
end

Best = repmat(Best, size(DS));

end
%=========================================================================

function Best = UpdateBest(Best, x1, y1, l, Acc, Balance)

[maxy1, imax] = max(y1); maxx1 = x1(imax); 

%if Acc == "accuracy", keyboard, end
if maxy1 >= Best.(Acc).Performance
    Best.(Acc).Performance = maxy1;
    Best.(Acc).Algo = l;
    Best.(Acc).Mres = maxx1;
    Best.(Acc).Balance = Balance;
else
    return 
end

end
%==========================================================================

function fileIDs = OpenFileIDs(rF, nesting)

folder = fullfile('..', rF, 'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
tables = ["Genetic_Graphs", "ADNI_Graphs", "CSF_Graphs"];

fileIDs = nan(size(tables));
for tab = tables
    fileIDs(tables == tab) = fopen(fullfile(folder, ...
        sprintf('%s_%s.tex', tab, nesting)), 'w');
end

end
%==========================================================================

function fileID = GetFileID(DA, fileIDs)

DataAliases = ["GCM", "newAD", ...
                arrayfun(@(x) sprintf("ADNI (%s)", x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"]),...
               arrayfun(@(x) sprintf("CSF (%s)",x),...
               ["EMCI vs. LMCI", "CN vs. EMCI", "CN vs. LMCI", "AD vs. LMCI", "AD vs. EMCI", "AD vs. CN"])...
               ];

if ismember(DA, DataAliases(1:2)), fileID = fileIDs(1);
elseif ismember(DA, DataAliases(3:5)), fileID = fileIDs(2);
elseif ismember(DA, DataAliases(6:end)), fileID = fileIDs(3);
else keyboard
end

end

%==========================================================================
function WriteFigureLatex(fileID, DS, DA, Best)


Benchmarks = {'SVM_Lin', 'SVM_RBF', 'LogitBoost', 'RUSBoost', 'BAGging'};
for Acc = ["AUC", "accuracy"]

switch ismember(Best.(Acc).Algo, Benchmarks)
    case true, Mres_str.(Acc) = '';
        Best.(Acc).Balance = '';
    case false
        Mres_str.(Acc) = sprintf(', $\\Mres = %d$', Best.(Acc).Mres);
end
end


fprintf(fileID, '\\begin{figure}[H] \n');
fprintf(fileID, ['\\centering \n']);
fprintf(fileID, ['\\caption{\\textbf{%s}. Best AUC: %0.3f (%s %s%s). \n' ...
    'Best accuracy: %0.3f (%s %s%s)} \n'], ...
    DA,...
    Best.AUC.Performance, Best.AUC.Balance, Best.AUC.Algo, Mres_str.AUC,...
    Best.accuracy.Performance, Best.accuracy.Balance, Best.accuracy.Algo, Mres_str.accuracy);
fprintf(fileID,...
    ['\\includegraphics['...
    'height = \\globalLGHeight, '...
    'width = \\globalLGWidth]'...
    '{Graphs2/%s_%s.pdf} \n'], DS, Best.nesting);


fprintf(fileID, '\\label{%s_LineGraph} \n', DA);
fprintf(fileID, '\\end{figure} \n\n\n');

end

%==========================================================================



%==========================================================================

function X= GetFiles(DS, Balance, rF, nesting)

    %rF = 'results2';
    MOE = 'Manual_Hyperparameter_Selection';
    %nesting = 'Unnested';
    CrossVal = 'Kfold';

    folderpath = fullfile('..', rF, MOE, CrossVal, DS);
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
    %X2 = X(contains({X.folder}, Balance) | contains({X.name}, 'Benchmark'));

    XBench = X(contains({X.name}, 'Benchmark'));
    XBal = X(contains({X.folder}, Balance));
    XNest = XBal(contains({XBal.name}, nesting));
    X = [XBench; XNest];

end

%=======================================================================

function [x1, y1, l] = GetPlotData(X3, Acc, Algo)
TrimB = false;
 %% Get Better performing Kernel
            X4 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X3);
            [~, iBestAcc] = max( arrayfun(@(x) max(x.results.(Acc)), X4));
            X4 = X4(iBestAcc);
            
            if TrimB, [X4.parameters, X4.results] = TrimBenchmark(X4.parameters, X4.results); end

            switch X4.parameters.svm.kernal
                case true, l = "-RBF";
                case false, l = "-Lin";
            end
                  
            if ismember(Algo, ["MLS", "ACA-S", "ACA-L"])
                    x1 = X4.parameters.multilevel.Mres;
                    y1 = X4.results.(Acc);
                    l = Algo + l;
                    
            elseif Algo == "Benchmark"
                %x1 = minmax(X4.parameters.multilevel.Mres);
                x1 = get(gca, 'XLim');
                [y1, ix] = max(X4.results.(Acc));
                y1 = [1 1] * y1;
                l = X4.parameters.misc.MachineList(ix);
                %l = replace(l, '_', '-');
                l = replace(l, '_Linear', '-Lin');
                l = replace(l, '_Radial', '-RBF');
            end 
            %plotData{iAlgo} = [x1 ; y1];

end

function PlotOnAxes(DA, Balance, x1, y1, ...
                    iAlgo, ax, iplot,Acc)

YTicks = 0.5:0.1:1;

MarkerSize = 8;
tFS = 15;
yFS = 15;
xFS = 15;

YTickLabels = num2cell(YTicks); YTickLabels(1:2:end) = {''};
axNames = {'YLim', 'YGrid', 'YTickMode', 'ytick','YTickLabels', 'FontSize'};
axValues = {[0.5, 1], 'on', 'manual', YTicks, YTickLabels, yFS};
LineArgs = {'LineWidth', 3, 'Marker', 's', 'MarkerSize', MarkerSize, 'MarkerFaceColor', 'auto'};
%AxlabelArgs = {'Interpreter', 'latex', 'FontSize', FontSize};

minmax = @(x) [min(x) max(x)];
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

LineColors = [0.12, 0.21, 1; %MLS
            1, 0.04, 0.12; %ACA-S
            0.25, 0.25, 0.25; %ACA-L
            0.85, 0.67, 0.2]; %Benchmark;
if iplot <= 2
        title({DA, Balance}, 'Interpreter', 'latex', 'FontSize', tFS); 
        end
         %Set up y-axes
        if ismember(iplot, [1 3])
        ylabel(capitalize(Acc), 'FontSize', yFS, 'Interpreter', 'latex');
        end
        cellfun(@(x,y) set(ax,x,y), axNames, axValues);
        
        %Set up data & x-axes
        LineColor = LineColors(iAlgo,:);
        plot(ax,x1,y1,'Color', LineColor, LineArgs{:});
        
        if ismember(iplot, [1 2])
            ax.XTickLabel = {};
        else 
            xlabel('$M_{res}$', 'Interpreter', 'latex', 'FontSize', xFS);
            ax.Position(2) = 0.18;
            if length(ax.XTickLabel) >= 7
                ax.XTickLabel(1:2:end) = {''};
            end
        end
        %ax.XLim = minmax(X4.parameters.multilevel.Mres);

end

%==========================================================================
function FixAxes(f)
minmax = @(x) [min(x) max(x)];
ax = findall(f,'type','axes');
minHeight = min(arrayfun(@(x) x.Position(4), ax));
minWidth = min(arrayfun(@(x) x.Position(3), ax));
for i = 1:4 
    ichild = contains({ax(i).Children.DisplayName}, 'MLS');
    xl = minmax(ax(i).Children(ichild).XData);
    ax(i).XLim = xl;
    p = ax(i).Position;
    p([3 4]) = [minWidth minHeight]; 
    if ismember(i, [1 2])
        p(2) = p(2) + 0.05;
    end
    if ismember(i, [1 3])
        p(1) = p(1) - 0.05;
    end
    ax(i).Position = p;

    %ax(i).XScale = 'log';
end
end
%==========================================================================
function [parameters, results] = TrimBenchmark(parameters, results)

if parameters.multilevel.svmonly ~= 1, return, end

isPCA = contains(parameters.misc.MachineList, "PCA");
parameters.misc.MachineList = parameters.misc.MachineList(~isPCA);
results.AUC = results.AUC(~isPCA);
results.accuracy = results.accuracy(~isPCA);

end
%==========================================================================

% function WriteResultTable(Best, rF)
% TableFolder = fullfile('..', rF, 'Manual_Hyperparameter_Selection', 'Kfold','Graphs');
% TableName = 'AccuracyTable.tex';
% fileID = fopen(fullfile(TableFolder, TableName), "w+");
% 
% 
% end
