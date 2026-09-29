function plotErrorRateHeatMaps_Synthetic
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
p.NanSpacing = 3;
p.MapSpacing = 5;

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

%FixAxes(p);
%AddLegend(p);
%GetWindow(p);
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
p.plotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,"Graphs", Accs2, p.NoiseTagFolder, "Colormaps");
if ~isfolder(p.plotPath), mkdir(p.plotPath), end

for Source = p.Sources
    p.(Source).texName = Source + "_" + p.Normalized + ".tex";
    p.(Source).texPath = fullfile(p.plotPath, p.(Source).texName);
    p.(Source).fID = fopen(p.(Source).texPath, "w+");
end


end
%==========================================================================
function [f, ax] = CreateFigure(Accs)

%Accs = reshapeAccs(Accs);

%[NRows, NCols] = size(Accs);
% % NRows = 1; NCols = 4;
% % 
% % Units = 'centimeters';
% % LRMargin = 2.5; TWMargin = 4;
% % HWBFigs = 3; VWBFigs = 2; 
% % 
% % axWidth = 8; axHeight = 4.5; axProp = 0.6;
% % figWidth = 4*LRMargin + NCols*axWidth + (NCols-1)*HWBFigs;
% % figHeight = 2*TWMargin + NRows*axHeight + (NRows-1)*VWBFigs;

%f = figure('Units', Units, "Outerposition", [0,0,figWidth,figHeight]);
f = figure(Units = "normalized", Outerposition = [0.05, 0.05, 0.5, 0.9]);
t = tiledlayout(1,length(Accs));
for i = 1:length(Accs)
    ax(i) = nexttile;
end

% nax = sum(Accs ~= "", 'all');
% 
% for iax = 1:nax
%     ax(iax) = subplot(NRows, NCols, iax); 
%     hold on; 
% end
% 
% for iax = 1:nax
%     if iax == 1
%         axLeft = LRMargin;
%         axBottom = figHeight - axHeight - TWMargin;
%     elseif iax > 1 && iax <= NCols
%         axLeft = ax(iax-1).Position(1) + axWidth + HWBFigs; 
%         axBottom = ax(iax-1).Position(2);        
%     elseif iax > 1 && mod(iax, NCols) == 1
%         axLeft = LRMargin;
%         axBottom = ax(iax - NCols).Position(2) - axHeight - VWBFigs;
%     else 
%         axLeft = ax(iax-1).Position(1) + axWidth + HWBFigs;
%         axBottom = ax(iax - NCols).Position(2) - axHeight - VWBFigs;
%     end
% 
%     axPos = [axLeft, axBottom, axWidth, axHeight];
%     ax(iax).Units = Units; ax(iax).Position = axPos;
% end


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
    p.ImageArray = [];
    p.legstr = [];
    p.YAxisleft = [];
    p.YAxisright = [];
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
p.z1(:,iN) = repmat(X3.results.(p.Acc)(iX), length(p.Mres), 1);
end
     
end

%if ismember(p.Algo, p.Finder)
    if p.Algo == "MLS"
    YAxisright = "$Mres = " + string(p.Mres) + "$";
    YAxisright(2:end-1) = "";
    else
    YAxisright = repmat("", size(p.Mres));
    end
    YAxisleft = repmat("",size(p.Mres));
    midpoint = ceil(length(p.Mres)/2);
    YAxisleft(midpoint) = p.l;
%else
    %YAxisright = "";
    %YAxisleft = p.l;
%end

p.nanpad = repmat(nan, p.NanSpacing, size(p.z1,2));
p.strpad = repmat("", p.NanSpacing, 1);

p.ImageArray = [p.z1 ; p.nanpad ; p.ImageArray];
p.YAxisleft = [YAxisleft(:) ; p.strpad ; p.YAxisleft];
p.YAxisright = [YAxisright(:) ; p.strpad ; p.YAxisright];
%p.legstr = [p.legstr, p.l];
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

FS = 12;
iAcc = find(p.Accs == p.Acc);

p.ax.FontSize = FS;
title(p.ax, FixString(p.Acc), FontSize = FS*1.1, Interpreter = "latex");

if iAcc > 2
xlabel(p.ax, "Noise", FontSize = FS, Interpreter = "latex");
end

p.ImageArray = [nan(p.NanSpacing, size(p.ImageArray,2)) ; p.ImageArray];
p.map = imagesc(p.ax, p.ImageArray);

sides = ["right","left"];
iside = mod(iAcc,2) + 1;
jside = 3 - iside;
side = sides(iside);
edis = sides(jside);


p.ax.YLim = [1, size(p.ImageArray,1)];
p.ax.YTick = 1:size(p.ImageArray,1);
p.ax.YTickLabelRotation = 90;
p.ax.TickLabelInterpreter= "latex";
p.ax.YAxis.TickLength = [0,1];
%p.ax.YAxis.LabelColor = 'k';
p.ax.YTickLabels = [p.strpad ; p.("YAxis" + side)];

p.ax.YGrid = "on"; p.ax.XGrid = "on";


shading interp
p.map.AlphaData = ~isnan(p.ImageArray);
p.ax.XLim = [1,size(p.ImageArray,2)];
p.ax.XTick = 1:size(p.ImageArray,2);
p.ax.XTickLabels = string(p.Noise);
p.ax.XTickLabels(2:2:end) = {''};

%colormap(flipud(autumn));
colormap jet
p.Colorbar = colorbar(p.ax);
if p.Acc == "errorRate"
p.Colorbar.Ticks = 0:0.1:0.5;
else
p.Colorbar.Ticks = 0:0.2:1;
end
minmax = @(x) [min(x), max(x)];
p.Colorbar.Limits = minmax(p.Colorbar.Ticks);
p.Colorbar.TickLabelInterpreter = "latex";


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
