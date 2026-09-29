function plotErrorRateHeatMaps_Synthetic2
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
p.Noise = 0:0.005:0.02;

p.xFS = 19;
p.cFS = 18;
p.yFS = 18;
p.tFS = 20;
p.mFS = 12;

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
        
        for iAlgo = 1:length(p.Algos)

            p.Algo = p.Algos(iAlgo); 
            p = GetPlotData(p);
                                         
        end

p = PlotOnAxes(p); 
end


ExportGraph(p);
end

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
p.Accs = ["accuracy", "recall", "specificity", "precision"];

%% Make Noise Tags
p.NoiseTags = compose("Noise_%g", p.Noise); %arrayfun(@(x) sprintf("Noise_%g",x), p.Noise);
p.NoiseTagFolder = replace(p.NoiseTags(2), ".", "_");
p.NoiseTags = "/" + replace(p.NoiseTags, ".", "_") + "/";

%% Get File IDs
Accs2 = strjoin(upper(extractBefore(p.Accs,4)), "-");
p.plotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,"Graphs", Accs2, p.NoiseTagFolder, "Colormaps");
if ~isfolder(p.plotPath), mkdir(p.plotPath), end

for Source = p.Sources
    p.(Source).texName = Source + "_" + p.Normalized + ".tex";
    p.(Source).texPath = fullfile(p.plotPath, p.(Source).texName);
    p.(Source).fID = fopen(p.(Source).texPath, "w+");
end

p.Balances = ["", "$\dagger$"]; 
p.Kernels = ["Lin", "RBF"];
p.Bfun = @(x) p.Balances(x.parameters.multilevel.splitTraining + 1);
p.Kfun = @(x) p.Kernels(x.parameters.svm.kernal + 1);
end
%==========================================================================
function [f, ax] = CreateFigure(Accs)

f = figure(Units = "normalized", Position = [0.05, 0.05, 0.7, 0.6]);
t = tiledlayout(1,length(Accs));
for i = 1:length(Accs)
    ax(i) = nexttile;
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
    
    X1 = load(X{end});

    p.Mres = X1.parameters.multilevel.Mres;
    p.NanSpacing = ceil(0.5*length(p.Mres));
    p.NanPad = nan(p.NanSpacing, length(p.Noise));

    p.ImageArray = [];
    p.legstr = [];
end
%==========================================================================
function p = GetPlotData(p)

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
    p.l = p.Algo + "-" + p.Kfun(X1(iX)) + p.Bfun(X1(iX));
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
p.z1(:,iN) = repmat(X3.results.(p.Acc)(iX), length(p.Mres), 1);
end
     
end

p.ImageArray = [p.z1 ; p.NanPad ; p.ImageArray];
p.legstr = [p.legstr, p.l];
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


iAcc = find(p.Accs == p.Acc);

%% Plot Image
p.ImageArray = flipud([nan(p.NanSpacing, length(p.Noise)) ; p.ImageArray]);
p.map = imagesc(p.ax, p.ImageArray ...
    , AlphaData = ~isnan(p.ImageArray) ...
    , CDataMapping = "direct"...
);
clim(p.ax, [0,1]);


%% Plot Title
title(p.ax, FixString(p.Acc), FontSize = p.tFS, Interpreter = "latex");

%% Plot X Axis Info
%xlabel(p.ax, "Noise", FontSize = FS*1.1, Interpreter = "latex");
p.ax.XLim = [0.5,length(p.Noise)+0.5];
p.ax.XTick = 1:size(p.ImageArray,2);
p.ax.XTickLabels = string(p.Noise);
p.ax.XTickLabels(2:2:end) = {''};
p.ax.XGrid = "on";
p.ax.XAxis.FontSize = p.xFS;
p.ax.XTickLabelRotation = 0;
p.ax.TickLabelInterpreter= "latex";


%% Plot Y Axis Info
p.ax.YDir = "reverse";
if iAcc == 1
Nres = length(p.Mres);
Start = p.NanSpacing + Nres/2;
Spacing = p.NanSpacing + Nres;
NTicks = length(p.Algos)*Nres + p.NanSpacing * (Nres + 1);
YTicks = Start:Spacing:NTicks;
p.ax.YTick = YTicks;
p.ax.YTickLabelRotation = 0;
p.ax.YTickLabels = p.legstr; %p.Algos;
p.ax.YGrid = "off"; 
p.ax.YMinorGrid = "on";
p.ax.YAxis.FontSize = p.yFS;
else
p.ax.YTick = [];
end


%% Add Colorbar
if iAcc == length(p.Accs)
colormap jet;
Colorbar = colorbar(p.ax...
    ...,Limits = [0,1]...
    ,Ticks = 0:0.2:1 ... 
    ,TickLabelInterpreter = "latex"...
    ,FontSize = p.cFS);
end

%% Add Mres Labels
if iAcc == 1
minmax = @(x) [min(x) max(x)];
X = mean([1, length(p.Noise)]) * [1, 1];

Y = p.NanSpacing + [-.5, Nres+1.5]; %+ NS2*[-1,1];
textstr = "$Mres = " + string(p.Mres([end,1])) + "$";
ann = text(p.ax,X, Y...
    ,textstr...
    ,FontSize = p.mFS...
    ,Interpreter = "latex"...
    ,HorizontalAlignment="center"...
    ,VerticalAlignment="middle"...
    ,EdgeColor="none"...
    );
end

%% Add X Axis Label
if iAcc == 1
annotation("textbox"...
    ,String = "Noise"...
    ,Units = "normalized"...
    ,Position = [0,-0.02,1,0.04]...
    ,Interpreter = "latex"...
    ,FontSize = p.tFS...
    ,HorizontalAlignment="center"...
    ,VerticalAlignment="middle"...
    ,EdgeColor = "none");
end


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
fprintf(fID, "\\caption{Quasi-Bootstrapped \\textbf{%s} Performance Metrics}\n", p.da);
%fprintf(fID, "\\setlength{\\fboxrule}{0.1pt}\n"); 
%fprintf(fID, "\\setlength{\\fboxsep}{5pt}\n\\fbox{");
fprintf(fID, "\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2.5/%s}\n", p.plotName + ".pdf");
%fprintf(fID, "}");
fprintf(fID, "\\label{%s_LineGraph_Synthetic}\n", p.da);
fprintf(fID, "\\end{figure}\n\n");

end
