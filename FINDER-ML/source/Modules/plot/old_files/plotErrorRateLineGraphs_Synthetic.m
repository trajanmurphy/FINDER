function plotErrorRateLineGraphs_Synthetic
close all

p.DSidx = [1:8];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Synthetic";
p.TrainA = 600;
p.TrainB = 200;
p.Testing = 10000;
p.Noise = 0:0.02:0.1;

p = GetDataSets(p);

for iDS = 1:length(p.DS)  
p.ds = p.DS(iDS); 
p.da = p.DA(iDS);
p.Trunc = p.Truncs(iDS);
[f, ax] = CreateFigure(p.Accs);
fprintf('Processing %s \n', p.ds);

for iacc = 1:length(p.Accs)
    p.Acc = p.Accs(iacc);
    p.ax = ax(iacc);
    
        p = GetFiles(p);
        p.legstr = [];
        p.lineHandles = [];
        
        for iAlgo = 1:length(p.Algos)

            p.Algo = p.Algos(iAlgo); 
            p = GetPlotData(p);
            p = PlotOnAxes(p);                              
        end

FixAxes(p);
AddLegend(p);
GetWindow(p);
end


ExportGraph(p);
end

end
%==========================================================================
function Accs = reshapeAccs(Accs)
if mod(length(Accs),2) == 1
    Accs = [Accs, ""];
end
Accs = reshape(Accs, 2,[])';
end
%==========================================================================
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
p.Accs = ["errorRate", "recall", "specificity", "precision"];

%% Make Noise Tags
p.NoiseTags = arrayfun(@(x) sprintf("Noise_%g",x), p.Noise);
p.NoiseTagFolder = replace(p.NoiseTags(end), ".", "_");
p.NoiseTags = "/" + replace(p.NoiseTags, ".", "_") + "/";

%% Get File IDs
Accs2 = strjoin(upper(extractBefore(p.Accs,4)), "-");
p.plotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,"Graphs", Accs2, p.NoiseTagFolder);
if ~isfolder(p.plotPath), mkdir(p.plotPath), end

for Source = p.Sources
    p.(Source).texName = Source + "_" + p.Normalized + ".tex";
    p.(Source).texPath = fullfile(p.plotPath, p.(Source).texName);
    p.(Source).fID = fopen(p.(Source).texPath, "w+");
end


end
%==========================================================================
function [f, ax] = CreateFigure(Accs)

Accs = reshapeAccs(Accs);

[NRows, NCols] = size(Accs);

Units = 'centimeters';
LRMargin = 2.5; TWMargin = 4;
HWBFigs = 7; VWBFigs = 2; 

axWidth = 8; axHeight = 4.5; axProp = 0.6;
figWidth = 4*LRMargin + NCols*axWidth + (NCols-1)*HWBFigs;
figHeight = 2*TWMargin + NRows*axHeight + (NRows-1)*VWBFigs;

f = figure('Units', Units, "Outerposition", [0,0,figWidth,figHeight]);

nax = sum(Accs ~= "", 'all');

for iax = 1:nax
    ax(iax) = subplot(NRows, NCols, iax); 
    hold on; 
    
end

for iax = 1:nax
    if iax == 1
        axLeft = LRMargin;
        axBottom = figHeight - axHeight - TWMargin;
    elseif iax > 1 && iax <= NCols
        axLeft = ax(iax-1).Position(1) + axWidth + HWBFigs; 
        axBottom = ax(iax-1).Position(2);        
    elseif iax > 1 && mod(iax, NCols) == 1
        axLeft = LRMargin;
        axBottom = ax(iax - NCols).Position(2) - axHeight - VWBFigs;
    else 
        axLeft = ax(iax-1).Position(1) + axWidth + HWBFigs;
        axBottom = ax(iax - NCols).Position(2) - axHeight - VWBFigs;
    end
    
    axPos = [axLeft, axBottom, axWidth, axHeight];
    ax(iax).Units = Units; ax(iax).Position = axPos;
end


end
%==========================================================================
function p = GetFiles(p)
    p.TrainStr = sprintf("%d_TrainingA_%d_TrainingB_%d_Testing",p.TrainA, p.TrainB, p.Testing);
    folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.TrainStr,'**', '*.mat');
    X = dir(folderpath); 
    X = fullfile({X.folder}, {X.name});
   
    XBench = X(contains(X,'Benchmark') &...
               contains(X,p.Normalized));
    XBal = X(...
             contains(X,p.Nesting) & ...
             contains(X,p.Normalized) & ...
             contains(X,"Eigen-" + p.Trunc));

    p.paths = [XBench, XBal];
  

    assert(~isempty(p.paths), 'No paths found')
end
%==========================================================================
function p = GetPlotData(p)

 %% Get Better performing Kernel
if p.Acc == "errorRate", opt = @min; else opt = @max; end
iAcc = p.Accs == p.Acc;
iAlgo = p.Algos == p.Algo;


if ismember(p.Algo, p.Finder), idx = contains(p.paths, p.Algo);
else, idx = contains(p.paths, "Benchmark"); end

Paths = p.paths(idx);
X0 = cellfun(@load, Paths);

%% Collect Machine Information
X1 = cellfun(@load, Paths(contains(Paths, p.NoiseTagFolder)));

if ~ismember(p.Algo, p.Finder)
    switch p.Algo
        case "SVMs"
            isMachine = contains(X1.parameters.misc.MachineList, "SVM");
        case "Boost/Bag"
            isMachine = ~contains(X1.parameters.misc.MachineList, "SVM");
    end
    Machines = X1.parameters.misc.MachineList(isMachine);
    [~,iX] = min(X1.results.errorRate(isMachine));
    BestMachine = Machines(iX);
    iX = find(X1.parameters.misc.MachineList == BestMachine);
    p.l = X1.parameters.misc.MachineList(iX);
    p.l = replace(p.l, ["_Linear", "_Radial"], ["-Lin","-RBF"]);
else
    [~,iX] = min(arrayfun(@(x) min(x.results.errorRate), X1));
    p.l = p.Algo;
    switch X1(iX).parameters.svm.kernal
        case true, p.l = p.l+"-RBF";
        case false, p.l = p.l+"-Lin";
    end
    if X1(iX).parameters.multilevel.splitTraining, p.l = p.l + "*"; end

end

%% x = Noise, y = Algo, z = Performance Metric
p.x1 = p.Noise; 
p.y1 = repmat(find(iAlgo), size(p.Noise)); 
p.z1 = [];
for iN = 1:length(p.Noise)
    X2 = X0(contains(Paths, p.NoiseTags(iN)));
   
if ismember(p.Algo, p.Finder)
X3= X2(iX);
p.z1(:,iN) = X3.results.(p.Acc);
else
X3 = X2;
p.z1(:,iN) = X3.results.(p.Acc)(iX);
end
     
end

p.legstr = [p.legstr, p.l];
%p.legstr = [p.legstr, p.l, repmat("", 1, size(p.z1,1)-1)]; 
end
%==========================================================================
function Acc = FixString(Acc)
if Acc == "AUC", return, end
indices = regexp(Acc, '[A-Z]'); 
if ~isempty(indices)
Acc = insertBefore(Acc, indices(end), " ");
end
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Acc = capitalize(Acc);
end
%==========================================================================
function p = PlotOnAxes(p)

iAlgo = p.Algos == p.Algo;

MarkerSize = 8;
tFS = 15;
yFS = 12;
xFS = 12;

LineArgs = {'LineWidth', 3, 'Marker', 's', 'MarkerSize', MarkerSize, 'MarkerFaceColor', 'auto'};

LineColors = ...
[0.12, 0.21, 1; %MLS
1, 0.04, 0.12; %ACA-S
0.25, 0.25, 0.25; %ACA-L
0.5, 0.1, 0.8; %SVMs
0.85, 0.67, 0.2]; %Boost/Bag;
LineColor = LineColors(iAlgo,:);
white = [1,1,1];
t0 = linspace(0,0.5,size(p.z1,1)); t0 = t0(:);
if ismember(p.Algo, p.Finder), LineColors2 = LineColor .* (1 - t0) + white .* t0;
else, LineColors2 = LineColor;
end

title(p.ax , FixString(p.Acc) + " vs. Noise", 'FontSize', tFS, 'Interpreter', 'latex');

for ic = 1:size(p.z1,1)
x = p.x1; y = p.y1; z = p.z1(ic,:);
hdl = plot3(p.ax,x,y,z,'Color', LineColors2(ic,:), LineArgs{:});
if ic == 1, p.lineHandles = [p.lineHandles, hdl]; end
end

end
%==========================================================================
function p = AddLegend(p)

lFS = p.ax(1).FontSize;
Units = "centimeters";

p.ax.Units = Units; axPos = p.ax.Position;


p.leg = legend(p.ax, p.lineHandles,...
    'String', p.legstr,...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.2*[1 1 1]);


p.leg.Units = Units;
legPos = p.leg.Position;
legPos(2) = axPos(4)+axPos(2) - legPos(4);
legPos(1) = axPos(1) + axPos(3) + 0.5;
p.leg.Position = legPos;
p.ax.Position = axPos;

end
%==========================================================================
function FixAxes(p)

if contains(p.ax.Title.String, "Error Rate")
    view(p.ax, 305, 25);
    p.ax.XTickLabelRotation = -20;
else
    view(p.ax, 55,30);
    p.ax.XTickLabelRotation = 20;
end

p.ax.YTick = 0:length(p.Algos)+1;
p.ax.YTickLabel = "";
p.ax.YTickLabelRotation = 20;

%p.ax.XLabel.String = "Noise";
p.ax.XTick = p.Noise;
p.ax.XTickLabel = arrayfun(@(N) sprintf("%0.2f", N), p.Noise);
p.ax.XTickLabel(1:2:end) = {''};


p.ax.FontSize = 12;
p.ax.TickLabelInterpreter = "latex";

for A = ["X", "Y", "Z"]
    p.ax.(A + "Grid") = "on";
end


end
%==========================================================================
function p = GetWindow(p)
ax = p.ax;

%% Get y-axis data
Children = ax.Children;
ZData = [Children.ZData];
isErrorRate = contains(ax.Title.String, 'Error Rate');

IQR = quantile(ZData, [0.25, 0.75]);
if abs(IQR(1) - IQR(2)) > eps
YIQR = ZData(ZData >= min(IQR) & ZData <= max(IQR));
[~,mu,sigma] = zscore(YIQR);
Z = (ZData - mu)/sigma;
YZ = ZData(abs(Z) <= 3);
else
    YZ = ZData;
end
window = [min(YZ), max(YZ)];

isBench = ~contains({Children.DisplayName}, ["MLS", "ACA"]);
Bench = Children(isBench);
BenchVal = unique([Bench.ZData]);
window(1) = min([window(1), BenchVal]);
window(2) = max([window(2), BenchVal]);


%% Construct a sensible scale
windowSize = window(2) - window(1);
spacings = [0.002, 0.005, 0.01, 0.025, 0.05, 0.1, 0.2, 0.3,0.4];
edges = [0,spacings*3];
idx = discretize(windowSize, edges);
spacing = spacings(idx); 
halfSpacing = spacing/2;

window(1) = max(halfSpacing * floor(window(1) / halfSpacing),0);
window(2) = min(halfSpacing * ceil(window(2) / halfSpacing),1);

%% Compensate if window is too small
minWindowSize = edges(2);
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

%ZTickMajor =  window(1):spacing:window(2);
ZTickMinor = window(1):halfSpacing:window(2);
ZTickMajor = ZTickMinor;
%FirstEndsWith5 = endsWith(string(window(1)), "5");

numDec = strlength(string(spacing))-2;
fspec = sprintf("%%0.%df",numDec);
scale = 10.^[numDec+1,numDec];


FirstOdd = mod(scale*window(1),2) == 1;


if FirstOdd(1)
ZTickMajor(1:2:end) = [];
else
ZTickMajor(2:2:end) = [];
end

% if FirstOdd(2) && length(ZTickMinor) >= 6
% ZTickMajor(1:2:end) = [];
% else
% ZTickMajor(2:2:end) = [];
% end

ZTickLabels = arrayfun(@(x) sprintf(fspec,x), ZTickMinor);
ZTickLabels(~ismember(ZTickMinor, ZTickMajor)) = "";


ax.ZLim = window;
ax.ZTick = ZTickMinor;
ax.ZTickLabels = ZTickLabels;

end
%==========================================================================
function ExportGraph(p)

p.plotName = strjoin([p.ds, p.Normalized, "Synthetic"], "_");
p.graphPath = fullfile(p.plotPath, p.plotName) + ".pdf";
exportgraphics(gcf, p.graphPath);
close(gcf)

iSource = arrayfun(@(x) ismember(p.ds, p.(x).DS), p.Sources);
Source = p.Sources(iSource);

if isempty(Source), keyboard, end

%edit(p.(Source).texPath);
fID = p.(Source).fID;
fprintf(fID, "\\begin{figure}[h!]\n\\centering\n");
fprintf(fID, "\\caption{\\textbf{%s}. A (*) represents the \\textit{balanced} regime.}\n", p.da);
fprintf(fID, "\\setlength{\\fboxrule}{0.1pt}\n"); % Thicker border lin
fprintf(fID, "\\setlength{\\fboxsep}{5pt}\n");
fprintf(fID, "\\fbox{\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2.5/%s}}\n", p.plotName + ".pdf");
fprintf(fID, "\\label{%s_LineGraph_Synthetic}\n", p.da);
fprintf(fID, "\\end{figure}\n\n");

end
