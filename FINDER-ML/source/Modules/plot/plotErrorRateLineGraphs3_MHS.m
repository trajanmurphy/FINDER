function plotErrorRateLineGraphs3_MHS
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

%% Plot Parameters
p.NanSpacing = 1; 
p.MapSpacing = 10;
p.MarkerSize = 8;
p.Clim = [-1,1];
p.FixedWindow = false;
p.tFS = 27;
p.xFS = 25;
p.yFS = 24;
p.aFS = 17;
p.lFS = 18;
p.cFS = 24;
p.alpha = [0.0001, 0.001, 0.05];
p.Markers = ["*", "**", "***"];
p.LineColors = [0.12, 0.21, 1; %MLS
    1, 0.04, 0.12; %ACA-S
    0.25, 0.25, 0.25; %ACA-L
    0.5, 0.1, 0.8; %SVMs
    0.85, 0.67, 0.2]; %Boost/Bag;

%% Finally Begin Making Plots

p = GetDataSets(p);

for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS); 
    p.da = p.DA(iDS);
    p.Trunc = p.Truncs(iDS);
    p = CreateFigure(p);
    p = GetFiles(p);
    fprintf('Processing %s \n', p.ds);

   p.iBest = nan(size(p.Algos));
for iacc = 1:length(p.Accs)
    p.Acc = p.Accs(iacc);
         
    for iAlgo = 1:length(p.Algos)
    p.Algo = p.Algos(iAlgo); 
    p = GetPlotData(p);
    PlotLineGraphs(p);                              
    end

end
AddLegend(p);
AddPVal(p);
%IDBest(p);
p = CreateEffectSizeMaps(p);
p = PlotEffectSizeMaps(p);

%FixAxes(ax);
ExportGraph(p);
end

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
p.isFinder = @(A) ismember(A, p.Finder);
p.Accs = ["errorRate", "recall", "specificity", "precision"];

%% Get File IDs
Accs2 = strjoin(upper(extractBefore(p.Accs,4)), "-");
p.plotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,"Graphs", p.Normalized, Accs2);
if ~isfolder(p.plotPath), mkdir(p.plotPath), end

for Source = p.Sources
    p.(Source).texName = Source + "_" + p.Normalized + ".tex";
    p.(Source).texPath = fullfile(p.plotPath, p.(Source).texName);
    p.(Source).fID = fopen(p.(Source).texPath, "w+");
end

%% Pit Algos Against Each Other
Algos = ["SVMs", "Boost/Bag", p.Finder];
AlgoMatrix = Algos(:) + " vs. " + Algos(:)';
i1 = 1:length(Algos); i2 = i1(:) < i1(:)';
AlgoVersus = AlgoMatrix(i2);
delVs = ["SVMs vs. Boost/Bag", "ACA-S vs. ACA-L"];
AlgoVersus(ismember(AlgoVersus, delVs)) = [];
p.AlgoVersus = [];
for Algo = ["SVMs", "Boost/Bag", "MLS"]
    p.AlgoVersus = [p.AlgoVersus; ...
        AlgoVersus(startsWith(AlgoVersus, Algo))];
end

p.GetMethodIndices = @(AV) [find(p.Algos == extractBefore(AV, " vs.")), find(p.Algos == extractAfter(AV, "vs. "))];

%% Tags for Balance and Kernel Regime
dagger = "$\dagger$";
p.Balances = ["", dagger]; 
p.Kernels = ["Lin", "RBF"];
p.Bfun = @(x) p.Balances(x.parameters.multilevel.splitTraining + 1);
p.Kfun = @(x) p.Kernels(x.parameters.svm.kernal + 1);
p.minmax = @(x) [min(x), max(x)];
p.isSVM = @(x) contains(x.parameters.misc.MachineList, "SVM");
end
%% ========================================================================
%% ========================================================================
function p = CreateFigure(p)
N = length(p.Accs);

%Use tiledlayout function to get axes placements
fig0 = figure(Units = "normalized", Position = [0.05, 0.05, 0.8, 0.65]);
tl0 = tiledlayout(2,N, TileIndexing = "rowmajor", TileSpacing = "loose", ...
    Padding = "loose", PositionConstraint = "innerposition");
for i = 1:N
ax0(i) = nexttile;
end
ax0(5) = nexttile(5,[1,2]);
ax0(6) = nexttile(7, [1,2]);

fig1 = figure(Units = "normalized", Position = [0.05, 0.05, 0.85, 0.67]);
LeftShift = 0.10;
RightShift = 0.04;
DownShift = 0.09;
HeightFactor = 0.5;
for i = 1:6
ax(i) = axes(fig1, Position = ax0(i).Position, Units = "normalized");
hold on; box on;

if i <= N,ax(i).Position(1) = ax(i).Position(1) - (1 + (N - i)*0.02)*LeftShift;
else,ax(i).Position(2) = ax(i).Position(2) - DownShift;
end

end

axEndLeft = ax(6).Position(1) + RightShift;
axEndHeight = HeightFactor*ax(6).Position(4);
axEndBottom = ax(6).Position(2)  + (1 - HeightFactor)*ax(6).Position(4);
axEndWidth = ax(6).Position(3);
ax(6).Position = [axEndLeft, axEndBottom, axEndWidth, axEndHeight];

p.ax = ax;
close(fig0);
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
NAV = length(p.AlgoVersus);

%[A,B] = meshgrid(Y.parameters.data.NAvals, Y.parameters.data.NBvals);
%p.Pairs = [A(:), B(:)]; Npairs = size(p.Pairs,1);
p.NBVals = Y.parameters.data.NBvals; 
NBVals = length(p.NBVals);
p.LineGraphArray = nan(Nalgos,Nres,Naccs);
p.WilcoxonRArray0 = nan(Nalgos,Naccs,NBVals);
p.KendallWArray0 = nan(length(p.Finder),Naccs,NBVals,Nres);

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
    p.x1 = X.parameters.multilevel.Mres;
    p.LineGraphArray(iAlgo,:,iAcc) = X.results.(p.Acc);
    LegStr = p.Algo + "-" + p.Kfun(X) + p.Bfun(X);        
else
    p.XLimits = p.minmax(X.parameters.multilevel.Mres);
    p.LineGraphArray(iAlgo,1,iAcc) = X.results.(p.Acc)(iX);
    LegStr = X.parameters.misc.MachineList(iX);
    LegStr = replace(LegStr, ["_Linear", "_Radial"], ["-Lin","-RBF"]);
end 

p.legstr(iAlgo) = LegStr;    

if p.Acc == "errorRate"
p = FillEffectSizeArrays(p);
end

end
%% ========================================================================
%% =========================================================================
function Acc = FixString(Acc)
if Acc == "AUC", return, end
indices = regexp(Acc, '[A-Z]'); 
if ~isempty(indices)
Acc = insertBefore(Acc, indices(end), " ");
end
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Acc = capitalize(Acc);
end
%% ==========================================================================
%% ==========================================================================
function PlotLineGraphs(p)

iAlgo = find(p.Algos == p.Algo);
iAcc = find(p.Accs == p.Acc);
ax = p.ax(iAcc);
LineColor = p.LineColors(iAlgo,:);

title(ax, FixString(p.Acc), Units = "points", FontSize = p.tFS, Interpreter =  "latex");

y1 = squeeze(p.LineGraphArray(iAlgo,:,iAcc));
y1 = y1(~isnan(y1));

if p.isFinder(p.Algo)
plot(ax,p.x1,y1, Color = LineColor, LineWidth = 3, Marker = 's', MarkerSize = 8, MarkerFaceColor = "auto");
else
yline(ax, y1, Color = LineColor, LineWidth = 3);
end



ax.FontSize = p.aFS;
if iAlgo == length(p.Algos)
xlim(ax, p.XLimits); 
xlabel(ax, "$M_{res}$", FontSize = p.xFS, Units = "points");
    if sum(~strcmp(ax.XTickLabel,'')) >= 4
        ax.XTickLabel(1:2:end) = {''};
    end
ax.XTickLabelMode = "manual";
ax.XLabel.Position(2) = -30;
for Z = ["X", "Y"]
ax.(Z + "Label").FontSize = p.(lower(Z) + "FS");
ax.(Z + "Label").Interpreter  = "latex";
end
ax.TickLabelInterpreter = "latex";
SetWindow(p); 

end

   
end
%% ========================================================================
%% ========================================================================
function p = AddLegend(p)
ax = p.ax(p.Accs == p.Acc);
Units = "centimeters";
p.leg = legend(ax, ...
    'String', p.legstr,...
    'Interpreter', 'latex',...
    'FontSize', p.lFS,...
    'EdgeColor', 0.2*[1 1 1]);

ax.Units = Units; p.leg.Units = Units;
axPos = ax.Position; legPos = p.leg.Position;
legPos(2) = axPos(4)+axPos(2) - legPos(4);
legPos(1) = axPos(1) + axPos(3) + 1.3;
legPos(3) = 0.8*axPos(3);
p.leg.Position = legPos;
ax.Position = axPos;
end
%% ========================================================================
%% ========================================================================
function IDBest(p)
ax = p.ax(p.Accs == p.Acc);

isErrorRate = find(p.Accs == "errorRate");
LineGraphArray = p.LineGraphArray(:,:,isErrorRate);
[~,imin] = min(LineGraphArray,[], 'all', 'omitnan');
[iAlgo, iMres] = ind2sub(size(LineGraphArray), imin);

BestAlgo = p.Algos(iAlgo);
AlgoString = p.legstr(iAlgo);
BestMres = p.x1(iMres);
BestAccuracy = LineGraphArray(imin);

AccuracyString = sprintf("Max Accuracy: %0.3f", BestAccuracy);
MresString = sprintf("$M_{res}$ = %d", BestMres);
if ~p.isFinder(BestAlgo), MresString = ""; end

str = [AccuracyString; AlgoString;MresString];

l = legend(ax);
annLeft = l.Position(1);
annBottom = ax.Position(2);
annWidth = l.Position(3);
annHeight = ax.Position(4) - l.Position(4) - 0.02;
annPos = [annLeft, annBottom, annWidth, annHeight];

ann = annotation("textbox",...
            "Units", l.Units,...
           "String", str,...
            "FontSize", p.lFS,...
            "VerticalAlignment", 'middle', ...
            "HorizontalAlignment", 'left',...
            "Interpreter", 'latex',...
            "Position",annPos,...
            "EdgeColor", l.EdgeColor,...
            "BackgroundColor", l.Color);

end
%% ========================================================================
function SetWindow(p)
iAcc = find(p.Accs == p.Acc);
ax = p.ax(iAcc);
isErrorRate = p.Acc == "errorRate";

if p.FixedWindow
    % if isErrorRate
    %     YTicks = 0:0.05:0.4;
    %     YTickLabels = string(YTicks);
    %     YTickLabels(~ismember(YTicks,0:0.1:0.5)) = "";
    % else
    %     YTicks = 0:0.125:1;
    %     YTickLabels = string(YTicks);
    %     YTickLabels(~ismember(YTicks,0:0.25:1)) = "";
    % end  
    % ax.YTick = YTicks;
    % ax.YTickLabel = YTickLabels;
    % ax.YLim = [min(YTicks), max(YTicks)];
    ax.YGrid = "on";
else
    GetWindow(p)
end

end
%% ========================================================================
function GetWindow(p)

iAcc = find(p.Accs == p.Acc);
ax = p.ax(iAcc);

%% Get y-axis data
minWindowSize = 0.05;
Children = ax.Children;
YData = p.LineGraphArray(:,:,iAcc);
YData = YData(~isnan(YData));
isErrorRate = strcmp(ax.YLabel.String, 'Error Rate');

IQR = quantile(YData, [0.25, 0.75]);
YIQR = YData(YData >= min(IQR) & YData <= max(IQR));
% YIQR = YData(~isoutlier(YData, "quartiles"));
[~,mu,sigma] = zscore(YIQR);
Z = (YData - mu)/sigma;
YZ = YData(abs(Z) <= 3);
window = [min(YZ), max(YZ)];


BenchVal = p.LineGraphArray(~p.isFinder(p.Algos),1,iAcc);
window(1) = min([window(1); BenchVal]);
window(2) = max([window(2); BenchVal]);


%% Construct a sensible scale
windowSize = window(2) - window(1);
edges = [0, 0.05, 0.15, 0.3, 1];
spacings = [0.01, 0.025, 0.05, 0.2];
fspecs = repmat("%0.2f", size(spacings));
fspecs(spacings == 0.025) = "%0.3f";
idx = discretize(windowSize, edges);
spacing = spacings(idx); fspec = fspecs(idx);
scale = 10^str2double(extractBetween(fspec, ".", "f"));

window(1) = max(spacing * floor(window(1) / spacing),0);
window(2) = min(spacing * ceil(window(2) / spacing),1);

%% Compensate if window is too small
windowSize = window(2) - window(1);
if windowSize < minWindowSize
    totalPadding = minWindowSize - windowSize;
    switch isErrorRate
        case false
        t1 = 1 - window(2);
        t2 = spacing*floor(totalPadding/(2*spacing));
        upperPadding = min(t1, t2);
        lowerPadding = totalPadding - upperPadding;

        case true
        t1 = window(1);
        t2 = spacing*floor(totalPadding/(2*spacing));
        lowerPadding = min(t1, t2);
        upperPadding = totalPadding - lowerPadding;
    end
    window = window + [-lowerPadding, upperPadding];
   
end

%% Set YTicks
YTickMajor =  window(1):spacing:window(2);
YTickMinor = window(1):spacing:window(2);
YTickLabels = repmat("", size(YTickMinor));

%% Pare down Y Tick Labels
idelete = mod(round(scale*YTickMajor),2) == 1;
YTickMajor(idelete) = [];
YTickString = arrayfun(@(x) sprintf(fspec, x), YTickMajor);
YTickLabels(ismember(YTickMinor, YTickMajor)) = YTickString;

%% Eliminate Trailing zeros
endsWithZero = endsWith(YTickLabels,"0");
YTickLabels(endsWithZero) = extractBefore(YTickLabels(endsWithZero),5);

ax.YLim = window;
ax.YTick = YTickMinor;
ax.YGrid = "on";
ax.YTickLabels = YTickLabels;

end
%% ========================================================================
%% ========================================================================
function p = FillEffectSizeArrays(p)

iAlgo = find(p.Algos == p.Algo);
NBVals = length(p.NBVals);
Nres = size(p.ResultsArray,3);
EFArray = nan(length(p.Accs), NBVals, Nres);
Accs = replace(p.Accs, "errorRate", "accuracy");

for ival = p.NBVals

for iMres = 1:Nres
results.array = p.ResultsArray(:, ival,iMres,:,:);
results = ComputeResultsAccuracy(results);
accValues = arrayfun( @(A) results.(A), Accs);
EFArray(:,ival,iMres) = accValues;
end
end

if p.isFinder(p.Algo)
p.KendallWArray0(iAlgo,:,:,:) = EFArray;
p.WilcoxonRArray0(iAlgo,:,:) = EFArray(:,:,p.BestMresIdx);
else
p.WilcoxonRArray0(iAlgo,:,:) = EFArray;
end

end
%% ========================================================================
%% ========================================================================
function p = CreateEffectSizeMaps(p)

Accs = replace(p.Accs, "errorRate", "accuracy");

%% WR = Wilcoxon's R. KW = Kendall's W. EF = Effect Size. PV = p value
p.WREF0 = nan(length(p.AlgoVersus), length(Accs));
p.KWEF0 = nan(length(p.Finder), length(Accs));
p.WRPV = p.WREF0;
p.KWPV = p.KWEF0; 

for iAV = 1:length(p.AlgoVersus)
AV = p.AlgoVersus(iAV);
iAlgo = p.GetMethodIndices(AV);
for iAcc = 1:length(Accs)
    x = squeeze(p.WilcoxonRArray0(iAlgo(2),iAcc,:));
    y = squeeze(p.WilcoxonRArray0(iAlgo(1),iAcc,:));
    [p.WRPV(iAV, iAcc),~,stats] = signrank(x,y,tail = "both", method = "approximate");
    p.WREF0(iAV, iAcc) = stats.zval / sqrt(length(x));
end
end

for iAlgo = 1:length(p.Finder)
Algo = p.Finder(iAlgo);
for iAcc = 1:length(Accs)
KendallMatrix = squeeze(p.KendallWArray0(iAlgo,iAcc,:,:));
KendallMatrix = KendallMatrix';
[p.KWPV(iAlgo,iAcc), p.KWEF0(iAlgo,iAcc)] = WeightedKendall(KendallMatrix);
end
end

%% Pad Effect Sizes With Nans
nanPadding = nan(p.NanSpacing, length(Accs));
for stat = ["WREF", "KWEF"]
EF = nanPadding;
EF0 = p.(stat + "0");
for i = 1:size(EF0,1)
    newRow = ones(p.MapSpacing,1) .* EF0(i,:);
    EF = [EF; newRow ;nanPadding];
end
p.(stat) = EF;
end

p.ChartTitles = ["Wilcoxon's $r$", "Kendall's $W$"];
end
%% ========================================================================
%% ========================================================================
function p = PlotEffectSizeMaps(p)

Accs = replace(p.Accs, "errorRate", "accuracy");

%% Create Custom Color Map
Colormap0 = [1,0,0; 0.8*[1,1,1] ; 0, 1, 0];
x = [-1,0,1]; xq = -1:0.01:1;
for i = 1:3
Colormap1(:,i) = interp1(x, Colormap0(:,i), xq, "spline");
end
Colormap1 = min(Colormap1, 1); Colormap1 = max(Colormap1, 0);


EFNames = ["WR", "KW"];
YTickFields = ["AlgoVersus", "Finder"];
ClimEnd = [-1,0];
shortenAxes = @(limits, spacing) limits + spacing/2*[1,-1];
for iEF = 1:2
ax = p.ax(iEF + length(p.Accs));
EFN = EFNames(iEF);
EF0 = p.(EFN + "EF0");
EF = p.(EFN + "EF");
PV = p.(EFN + "PV");

%% Plot
cmap = imagesc(ax, EF, AlphaData = ~isnan(EF));
Colormap = Colormap1(xq > ClimEnd(iEF),:);
colormap(ax, Colormap);
%colorbar(ax, TickLabelInterpreter= "latex", FontSize = p.cFS);
clim(ax, [ClimEnd(iEF), 1]);

%% Set X Axis
XTickLabels = Accs;
ax.XTick = 1:length(XTickLabels);
ax.XTickLabels = arrayfun(@FixString, XTickLabels);
ax.XTickLabelRotation = 0;
ax.XLim = [0.5, size(EF,2)+0.5];

%% Set Y Axis
YTickLabels = p.(YTickFields(iEF));
Start = p.NanSpacing + p.MapSpacing/2;
Spacing = p.NanSpacing + p.MapSpacing;
ax.YTick = Start:Spacing:size(EF,1);
ax.YTickLabel = YTickLabels;
ax.YLim = [1 size(EF,1)] ;
ax.FontSize = p.aFS;
ax.YDir = "reverse";

for Z = ["X", "Y"]
    ax.(Z + "Axis").TickLabelInterpreter = "latex";
end

EFstr = compose("%0.2f", EF0);
PVstr = discretize(PV, [0, p.alpha], "categorical", [p.Markers]);
PVstr = string(PVstr); 
PVstr(ismissing(PVstr)) = "";

textString = EFstr + PVstr;
[Xt, Yt] = meshgrid(ax.XTick, ax.YTick);
text(ax, Xt(:), Yt(:), textString(:)...
    ,FontSize = p.aFS...
    ,Interpreter = "latex"...
    ,HorizontalAlignment = "center"...
    ,VerticalAlignment = "middle"...
    ,EdgeColor = "none");

title(ax, p.ChartTitles(iEF), Interpreter = "latex", Units = "points", FontSize = 0.9*p.tFS);
end

end
%% ========================================================================
%% ========================================================================
function AddPVal(p)
annPos = p.ax(end).Position;
annPos(2) = p.ax(end-1).Position(2);
str = compose("$^{%s}p < %g$", p.Markers(:), p.alpha(:));
str = strjoin(str, sprintf(",    "));

ann = annotation("textbox"...
    ,String = str...
    ,Position = annPos...
    ,FontSize = p.lFS...
    ,Interpreter = "latex"...
    ,EdgeColor = "none"...
    ,BackGroundColor = "none"...
    ,HorizontalAlignment="left"...
    ,VerticalAlignment="bottom");
end
%% ========================================================================
%% ========================================================================
function ExportGraph(p)

p.plotName = strjoin([p.ds, p.Normalized], "_");
p.graphPath = fullfile(p.plotPath, p.plotName) + ".pdf";
exportgraphics(gcf, p.graphPath, Resolution = 150);
close(gcf)

iSource = arrayfun(@(x) ismember(p.ds, p.(x).DS), p.Sources);
Source = p.Sources(iSource);

if isempty(Source), keyboard, end

%edit(p.(Source).texPath);
fID = p.(Source).fID;
fprintf(fID, "\\begin{figure}[h!]\n\\centering\n");
fprintf(fID, "\\caption{\\textbf{%s}. A ($\\dagger$) represents the \\textit{balanced} regime.}\n", p.da);
fprintf(fID, "\\setlength{\\fboxrule}{0.1pt}\n"); % Thicker border lin
fprintf(fID, "\\setlength{\\fboxsep}{5pt}\n");
fprintf(fID, "\\fbox{\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2/%s}}\n", p.plotName + ".pdf");
fprintf(fID, "\\label{%s_LineGraph}\n", p.da);
fprintf(fID, "\\end{figure}\n\n");

end
