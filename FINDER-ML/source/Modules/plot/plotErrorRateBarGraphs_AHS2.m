function plotErrorRateBarGraphs_AHS2
close all

p.DSidx = 1:8;
p.Results = "results";
p.MOE = "MLS_EVT_FCD1";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

p.NanSpacing = 1; 
p.MapSpacing = 10;
p.Clim = [-1,1];
p.tFS = 20;
p.xFS = 18;
p.yFS = 18;
p.aFS = 16;
p.lFS = 14;
p.cFS = 14;
p.alpha = [0.01, 0.05];
p.Markers = ["**", "*"];

p = GetDataSets(p);


for iDS = 1:length(p.DS)  
p.ds = p.DS(iDS); 
p.da = p.DA(iDS);
p.Trunc = p.Truncs(iDS);
p = CreateFigure(p);
fprintf('Processing %s \n', p.ds);

p = GetFiles(p);

for Ch = p.Charts
p.Ch = Ch;
p = PlotBarLineData(p); 
p = PlotHSD(p);
p = PlotWilcoxonR(p);
end


ExportGraph(p);
end

end
%% ========================================================================
%% ========================================================================
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

p.Sources = ["Genetic", "Plasma", "CSF"];
p.Genetic.DS = p.DS(1:2);
p.Plasma.DS = p.DS(3:5);
p.CSF.DS = p.DS(6:8);

fields = ["DS", "DA", "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

p.Algos = ["MLS", "ACA-S", "ACA-L", "SVMs", "Boost/Bag"];
p.Finder = ["MLS", "ACA-S", "ACA-L"];
p.isFinder = @(Algo) ismember(Algo, p.Finder);
p.Accs = ["accuracy", "recall", "specificity", "precision"];
p.Charts = [p.Accs, "HSD", "EF"];
p.LineColors = [0.12, 0.21, 1; %MLS
    1, 0.04, 0.12; %ACA-S
    0.25, 0.25, 0.25; %ACA-L
    0.5, 0.1, 0.8; %SVMs
    0.85, 0.67, 0.2; %Boost/Bag;
    0.05, 0.48, 0.12]; %AHS

GF = 0.2; grey = [1,1,1];
p.LineColors = p.LineColors*(1 - GF) + GF*grey;


%% Get File IDs
Accs2 = strjoin(upper(extractBefore(p.Accs,4)), "-");
p.PlotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,Accs2,"Graphs");
p.TablePath = replace(p.PlotPath, "Graphs", "Tables");
for field = ["Plot", "Table"]
folder = p.(field + "Path");
if ~isfolder(folder), mkdir(folder), end
end

for Source = p.Sources
p.(Source).texName = Source + "_" + p.Normalized + ".tex";
p.(Source).texPath = fullfile(p.PlotPath, p.(Source).texName);
p.(Source).fID = fopen(p.(Source).texPath, "w+");
end

end
%% =========================================================================
%% ========================================================================
function p = CreateFigure(p)
N = length(p.Accs);

%Use tiledlayout function to get axes placements
fig0 = figure(Units = "normalized", Position = [0.05, 0.05, 0.85, 0.5]);
tl0 = tiledlayout(2,N, TileIndexing = "rowmajor", TileSpacing = "loose", ...
    Padding = "loose", PositionConstraint = "innerposition");
for i = 1:N
ax0(i) = nexttile;
end
ax0(5) = nexttile(5,[1,2]);
ax0(6) = nexttile(7, [1,2]);

fig1 = figure(Units = "normalized", Position = [0.05, 0.05, 0.9, 0.6]);
Bins = [1,4.5,6];
Shift = [-0, 0, 0, 0;
         -0.015, -0.05, 0, 0];
for i = 1:6
p.ax(i) = axes(fig1, Position = ax0(i).Position, Units = "normalized");
iS = discretize(i,Bins);
p.ax(i).Position = p.ax(i).Position + Shift(iS,:);
end

close(fig0);
end
%% ========================================================================
%% ========================================================================
function p = GetFiles(p)

p.Balances = ["", "$\dagger$"]; 
p.Kernels = ["Lin", "RBF"];
p.Bfun = @(x) p.Balances(x.parameters.multilevel.splitTraining + 1);
p.Kfun = @(x) p.Kernels(x.parameters.svm.kernal + 1);

p.BestIdx = nan(1,length(p.Algos));
p.LegStr = string(p.BestIdx);
p.YLineVals = nan(length(p.Algos)+1, length(p.Accs));

%% Add MHS Finder Results
folderpath2 = fullfile('..', p.Results, "Manual_Hyperparameter_Selection", p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X5 = dir(folderpath2); 
X6 = fullfile({X5.folder}, {X5.name});
X7 = X6((contains(X6,p.Nesting) &contains(X6,"Eigen-" + p.Trunc))|contains(X6,"Benchmark"));
X7 = X7( contains(X7,p.Normalized));

for Algo = p.Algos
p.Algo = Algo;
if ~p.isFinder(p.Algo)
    Algo = "Benchmark";
end
X8 = X7(contains(X7, Algo));
X9 = cellfun(@load, X8, "UniformOutput", false);

if Algo == p.Finder(1)
x = X9{1}; 
[A,B] = meshgrid(x.parameters.data.NAvals, x.parameters.data.NBvals);
p.pairs = [A(:), B(:)];
p.WilcoxonRArray = nan(size(p.pairs,1), length(p.Algos)+1, length(p.Accs));
end

[~,iX9] = min(cellfun(@(x) min(x.results.errorRate), X9));
p.BestX = X9{iX9};
p = FillWilcoxonRArray(p);
end

%% Get AHS results
folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X0 = dir(folderpath); 
X1 = fullfile({X0.folder}, {X0.name});
X2 = X1(contains(X1,p.Nesting) & contains(X1,p.Normalized) &  contains(X1,"Eigen-" + p.Trunc));
X3 = cellfun(@load, X2);
[~,iX3] = min(arrayfun( @(x) x.results.errorRate, X3));

%p.XLabels = arrayfun(p.Bfun, X3) + "_" + arrayfun(p.Kfun, X3); 
p.Algo = "AHS";
p.BestX = X3(iX3);
p = FillWilcoxonRArray(p);
p.AHSPaths = X2{iX3};

end
%% ========================================================================
%% ========================================================================
function p = FillWilcoxonRArray(p)
iAlgo = find([p.Algos, "AHS"] == p.Algo);
if p.Algo == "AHS", iAlgo = length(p.Algos)+1; end

if p.isFinder(p.Algo)
[~, iBest] = min(p.BestX.results.errorRate);
Legstr = p.Algo + "-" + p.Kfun(p.BestX) + p.Bfun(p.BestX) + ": $M_{res} = $" + string(p.BestX.parameters.multilevel.Mres(iBest));
elseif ~p.isFinder(p.Algo) && p.Algo ~= "AHS"
    switch p.Algo
    case "SVMs", lg = @(x) x;
    case "Boost/Bag", lg = @not;
    end
iMachine = lg(contains(p.BestX.parameters.misc.MachineList, "SVM"));
Machines = p.BestX.parameters.misc.MachineList(iMachine);
errorRates = p.BestX.results.errorRate(iMachine);
[~,imin] = min(errorRates);
Machine = Machines(imin);
iBest = find(p.BestX.parameters.misc.MachineList == Machine);
Legstr = replace(Machine, ["_Linear", "_Radial"], ["-Lin", "-RBF"]);
elseif p.Algo == "AHS"
iBest = 1;
Legstr = "AHS-" + p.Kfun(p.BestX) + p.Bfun(p.BestX);
end

%if p.Algo ~= "AHS"
p.Legstr(iAlgo) = Legstr;
p.YLineVals(iAlgo,:) = arrayfun( @(A) p.BestX.results.(A)(iBest), p.Accs);
% else
% iBest = 1;
% end

for ipair = 1:size(p.pairs,1)
pair = p.pairs(ipair,:);
results.array = p.BestX.results.array(pair(1), pair(2), iBest,:,:);
results = ComputeResultsAccuracy(results);
p.WilcoxonRArray(ipair,iAlgo,1:length(p.Accs)) = arrayfun( @(A) results.(A), p.Accs);
end

end
%% ========================================================================
%% ========================================================================
function Acc = FixString(Acc)
if Acc == "AUC", return, end
indices = regexp(Acc, '[A-Z]'); 
if ~isempty(indices)
Acc = insertBefore(Acc, indices(end), " ");
end
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Acc = capitalize(Acc);
end
%% ========================================================================
%% ========================================================================
function p = PlotBarLineData(p)

iCh = find(p.Charts == p.Ch);
if ~ismember(p.Ch, p.Accs), return, end
ax = p.ax(iCh);

%% Plot Bars
barData = p.YLineVals(:,iCh);
b = bar(ax, 1, barData, FaceColor = "flat");
for i = 1:length(b), b(i).CData = p.LineColors(i,:); end

%% Set Axes
for Z = ["X", "Y"]
ax.(Z + "Axis").TickLabelInterpreter= "latex";
ax.(Z + "Label").String = "";
end
ax.YGrid = "on"; 
ax.XTick = [];
ax.YLim = [0.5,1]; 
YTick0 = 0.6:0.2:1; YTick1 = 0.5:0.05:1; iTick = ~ismember(YTick1, YTick0);
ax.YTick = YTick1; 
ax.YTickLabels(iTick) = {''};
ax.FontSize = p.aFS;
title(ax, FixString(p.Ch), FontSize = p.tFS, Interpreter = "latex");

%% Set MHS Legend and Title
if iCh == length(p.Accs)
legLeft = p.ax(1).Position(1);
legHeight = 0.07; 
legWidth = p.ax(4).Position(1) + p.ax(4).Position(3) - legLeft;
legBottom = p.ax(1).Position(2) - legHeight - 0.02; 
legPos = [legLeft, legBottom, legWidth, legHeight]; 

leg = legend(ax, String = p.Legstr, Interpreter = "latex", FontSize = p.lFS, Position = legPos, NumColumns = length(p.Legstr));

%leg.Position(1:2) = [ax.Position(1) + ax.Position(3) + 0.01, ax.Position(2) ];
end

end
%% ========================================================================
%% ========================================================================
function p = PlotHSD(p)
if p.Ch ~= "HSD", return, end

iCh = find(p.Charts == p.Ch);
ax = p.ax(iCh);

X2 = load(p.AHSPaths);

MA = X2.results.TruncArray(:,:,1); MA = MA(:); uMA = unique(MA);
Mres = X2.results.TruncArray(:,:,2); Mres = Mres(:); uMres = unique(Mres);%MapTicks = @(x) 1:length(x); 
MapTicks = @(x) min(x):max(x);
%tMA = MapTicks(uMA); %tMres = MapTicks(uMres);
%MresSpacing = min(diff(uMres));
%tMres = min(uMres):MresSpacing:max(uMres);
tMA = uMA;
tMres = uMres;
[Mres2, MA2] = meshgrid(tMres, tMA);

mapData = arrayfun( @(mres, ma) sum(Mres == mres & MA == ma), Mres2, MA2);
mapData = mapData / length(MA);
mapData(mapData == 0) = nan;

cmap = imagesc(ax, mapData', AlphaData = ~isnan(mapData'));
climmax = max(ax.CLim);
clim(ax, [0,climmax]);
colormap jet
colorbar(ax, TickLabelInterpreter = "latex", FontSize = p.cFS);

ax.XTick = 1:length(tMA); ax.YTick = 1:length(tMres);
ax.XTickLabels = string(tMA); 
ax.YTickLabels = string(tMres);
ax.TickLabelInterpreter = "latex";
ax.FontSize = p.aFS*0.6;
xlabel(ax, "$M_\mathbf A$", Interpreter = "latex", FontSize = p.xFS);
ylabel(ax, "Percentile", Interpreter = "latex", FontSize = p.yFS);
for Z = ["Y"]%, "X"]
%Ticks = cellfun(@str2num, ax.(Z + "TickLabel"));
Ticks = ax.(Z + "Tick");
if length(Ticks) >= 2, TS = Ticks(2) - Ticks(1); else, TS = 1; end
ax.(Z + "Lim") = [min(Ticks), max(Ticks)] + 0.5*TS*[-1, 1];
ax.(Z + "TickLabelRotation") = 0;
NTicks = length(Ticks);

if NTicks > 6
Spacing = floor(NTicks/4);
newTicks = Ticks(Spacing:Spacing:end);
iTick = ~ismember(Ticks, newTicks);
ax.(Z + "TickLabels")(iTick) = {''};
end
end

title(ax, "Hyperparameter Distribution", Interpreter = "latex", FontSize = p.tFS);
ax.Color = 0.75*[1,1,1];
end
%% ========================================================================
%% ========================================================================
function p = PlotWilcoxonR(p)

if p.Ch ~= "EF", return, end
ax = p.ax(p.Charts == p.Ch);
ax.Position(1) = ax.Position(1) + 0.05;

EffectSizes0 = nan(length(p.Algos), length(p.Accs));
pValues = EffectSizes0;

for iAlgo = 1:length(p.Algos)
for iAcc = 1:length(p.Accs)
    x = p.WilcoxonRArray(:,iAlgo,iAcc);
    y = p.WilcoxonRArray(:,end,iAcc);
    [pValues(iAlgo, iAcc),~,stats] = signrank(y,x,tail = "both", method = "approximate");
    EffectSizes0(iAlgo, iAcc) = stats.zval / sqrt(length(x));
end
end

%% Pad Effect Sizes With Nans
nanPadding = nan(p.NanSpacing, length(p.Accs));
EffectSizes = nanPadding;
for iAlgo = 1:length(p.Algos)
    newRow = ones(p.MapSpacing,1) .* EffectSizes0(iAlgo,:);
    EffectSizes = [EffectSizes; newRow ;nanPadding];
end

%% Create Custom Color Map
Colormap0 = [0.8,0,0; 1,0,0; 0.8*[1,1,1] ; 0, 1, 0; 0, 0.8, 0];
X = linspace(0,1,size(Colormap0,1)); Xq = 0:0.01:1;
for i = 1:3
Colormap(:,i) = interp1(X, Colormap0(:,i), Xq, "spline");
end
Colormap = min(Colormap, 1); Colormap = max(Colormap, 0);

%% Plot
cmap = imagesc(ax, EffectSizes, AlphaData = ~isnan(EffectSizes));
colormap(ax, Colormap);
%colorbar(ax, TickLabelInterpreter= "latex", FontSize = p.cFS);
clim(ax, p.Clim);

%% Set X Axis
ax.XTick = 1:length(p.Accs);
ax.XTickLabels = arrayfun(@FixString, p.Accs);
ax.XTickLabelRotation = 0;

%% Set Y Axis
Start = p.NanSpacing + p.MapSpacing/2;
Spacing = p.NanSpacing + p.MapSpacing;
ax.YTick = Start:Spacing:size(EffectSizes,1);
ax.YTickLabels = p.Algos;

for Z = ["X", "Y"]
ax.(Z + "Axis").TickLabelInterpreter = "latex";
ax.(Z + "Axis").FontSize = p.aFS;
end

EffectSizeString = compose("%0.2f", EffectSizes0);
pValuesString = discretize(pValues, [0, p.alpha], "categorical", [p.Markers]);
pValuesString = string(pValuesString); 
pValuesString(ismissing(pValuesString)) = "";

textString = EffectSizeString + pValuesString;

[Xt, Yt] = meshgrid(ax.XTick, ax.YTick);

for alpha = [p.Markers, ""]
    isSig = pValuesString == alpha;
    Xs = Xt(isSig);
    Ys = Yt(isSig);
    Ts = textString(isSig);
text(ax, Xs, Ys, Ts...
    ,FontSize = p.aFS...
    ,Interpreter = "latex"...
    ,HorizontalAlignment = "center"...
    ,VerticalAlignment = "middle"...
    ,EdgeColor = "none");
end
title(ax, "Effect Size (Wilcoxon's $r$)", Interpreter = "latex", FontSize = p.tFS);


%% Add p-value annotation: 
annPos = p.ax(end).Position;
annPos(1) = annPos(1) + annPos(3) + 0.01;
annPos(3) = 6*annPos(3);
str = compose("$^{%s}p < %g$", p.Markers(:), p.alpha(:));
%str = strjoin(str, sprintf(",    "));

ann = annotation("textbox"...
    ,String = str...
    ,Position = annPos...
    ,FontSize = p.lFS...
    ,Interpreter = "latex"...
    ,EdgeColor = "none"...
    ,BackGroundColor = "none"...
    ,HorizontalAlignment="left"...
    ,VerticalAlignment="middle");
end
%% ========================================================================
%% ========================================================================
function ExportGraph(p)

p.PlotName = strjoin([p.ds, p.Normalized, "AHS"], "_");
p.GraphPath = fullfile(p.PlotPath, p.PlotName) + ".pdf";
exportgraphics(gcf, p.GraphPath);
close(gcf)

iSource = arrayfun(@(x) ismember(p.ds, p.(x).DS), p.Sources);
Source = p.Sources(iSource);

if isempty(Source), keyboard, end

fID = p.(Source).fID;
fprintf(fID, "\\begin{figure}[h!]\n\\centering\n");
fprintf(fID, "\\caption{\\textbf{%s}: Performance Metrics based on Algorithmically Selected Hyperparameters}\n", p.da);
fprintf(fID, "\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch3/%s}\n", p.PlotName + ".pdf");
fprintf(fID, "\\label{%s_AHS}\n", p.da);
fprintf(fID, "\\end{figure}\n\n");

end
