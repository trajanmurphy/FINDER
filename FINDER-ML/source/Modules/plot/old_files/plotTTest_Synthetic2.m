function plotTTest_Synthetic2
close all

p.DSidx = [1:8];
p.Results = "results";
p.alpha = [0.01, 0.05];
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Synthetic";
p.TrainA = 600;
p.TrainB = 200;
p.Testing = 10000;
p.Noise = 0:0.1:0.5;

p = GetDataSets(p);
p = CreateFigure(p);

for iDS = 1:length(p.DS)  
p.ds = p.DS(iDS); 
p.da = p.DA(iDS);
p.Trunc = p.Truncs(iDS);

fprintf('Processing %s \n', p.ds);

p.DiscordantArray = nan(length(p.AlgoVersus), length(p.Noise),2);
for iNoise = 1:length(p.Noise)
p.NT = p.NoiseTags(iNoise);
p = GetFiles(p);

for iAV = 1:length(p.AlgoVersus)
p.AV = p.AlgoVersus(iAV);
p = FillDiscordantArray(p);
  
end
end
 
p = PlotOnAxes(p);                              
p = GetWindow(p);
end

p = AddLegend(p);
ExportGraph(p);
end

%==========================================================================
function p = GetDataSets(p)

%% Write Data Sets
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

p.Algos = ["MLS", "ACA-S", "ACA-L", "SVMs", "Boost/Bag"];
p.Finder = ["MLS", "ACA-S", "ACA-L"];
p.Accs = ["errorRate", "recall", "specificity", "precision"];

%% Make Noise Tags
p.NoiseTags = arrayfun(@(x) sprintf("Noise_%g",x), p.Noise);
p.NoiseTagFolder = replace(p.NoiseTags(end), ".", "_");
p.NoiseTags = "/" + replace(p.NoiseTags, ".", "_") + "/";


%% Pit Algos Against Each Other;
p.Finder = ["MLS", "ACA-S", "ACA-L"]; 
p.AlgosSub = ["SVMs", "Boost/Bag", p.Finder]; 
p.Algos = p.AlgosSub; p.Algos(1:2) = "Benchmark";
p.AlgoFields = replace(p.AlgosSub, ["/", "-"], "_");
p.isFinder = ismember(p.AlgosSub, p.Finder);

AlgoMatrix = p.AlgosSub(:) + " vs. " + p.AlgosSub(:)';
i1 = 1:length(p.AlgosSub); i2 = i1(:) < i1(:)';
AlgoVersus = AlgoMatrix(i2);
delVs = ["SVMs vs. Boost/Bag", "ACA-S vs. ACA-L"];
AlgoVersus(ismember(AlgoVersus, delVs)) = [];
p.AlgoVersus = [];
for Algo = p.AlgosSub
    p.AlgoVersus = [p.AlgoVersus; ...
    AlgoVersus(startsWith(AlgoVersus, Algo))];
end

%% Put Information for effect size/statistical significance
p.EFBins = [0.2, 0.5, 0.8,10];
p.yStr = "Effect Size";
p.EFStat = "Cohen's $d$";

BF = 0.2;
p.EFColors = [1,1,1;1,0,0;1,1,0;0,1,0] * (1 - BF) + [1,1,1]*BF;
p.Markers = ["s", "o"];
p.MarkersC = ["$\\blacksquare$", "$\\bullet$"];
p.LineColors = [0,0,1;0,0.7,1;0,1,1;...
                1,0,0;1,0,0.7;1,0,1;...
                0.1,0.4,0.1;0.3,0.8,0.3];%lines(length(p.AlgoVersus));
p.LineColors = p.LineColors * (1 - BF) + [0.5,0.5,0.5] * BF;


LineStyles = ["-", "--", ":"]; nStyles = length(LineStyles);
p.LineStyles = repmat(LineStyles, 1, ceil(length(p.AlgoVersus)/nStyles));
LineWidths = 3:-0.5:2; nWidths = length(LineWidths);
p.LineWidths = repmat(LineWidths, 1, ceil(length(p.AlgoVersus)/nWidths));


end
%==========================================================================
function p = CreateFigure(p)
p.fig = figure(Units = "normalized", OuterPosition = [0.05,0.05,0.9,0.9]);
EFBins = [0, p.EFBins];
FS = 15;
%% Create Axes
for iax = 1:length(p.DS)
    ax(iax) = subplot(3,3,iax); hold on
    ax(iax).XLim = [min(p.Noise), max(p.Noise)];

    
    ax(iax).XTick = p.Noise;
    ax(iax).XTickLabel(1:2:end) = {''};
    ax(iax).FontSize = FS*0.8;
    ax(iax).TickLabelInterpreter = "latex";

   
    if mod(iax,3) == 1
    ylabel(ax(iax), p.yStr, FontSize = FS, Interpreter = "latex");
    end
    if iax >= length(p.DS) - 1
    xlabel(ax(iax), "Noise", FontSize = FS, Interpreter = "latex");
    end

for ipc = 1:length(p.EFBins)
    x = [ax(iax).XLim, fliplr(ax(iax).XLim)];
    y1 = kron(EFBins([ipc, ipc+1]),[1,1]);
    y2 = kron(-EFBins([ipc, ipc+1]),[1,1]);
    patch(ax(iax), x,y1,p.EFColors(ipc,:), EdgeColor = "none", FaceAlpha = 0.2);
    patch(ax(iax), x,y2,p.EFColors(ipc,:), EdgeColor = "none", FaceAlpha = 0.2);
end

title(ax(iax), p.DA(iax), FontSize = FS*1.05, Interpreter = "latex");

end
p.ax = ax;
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
function p = FillDiscordantArray(p)

Balances = ["Unbalanced", "Balanced"]; Kernels = ["Linear", "Radial"];

iAV = p.AlgoVersus == p.AV;
iNT = p.NoiseTags == p.NT;

iAV1 = find(extractBefore(p.AV, " vs.") == p.AlgosSub);
iAV2 = find(extractAfter(p.AV, "vs. ") == p.AlgosSub);
jAV = [iAV1, iAV2];

A = p.Algos(jAV);
AS = p.AlgosSub(jAV);

BC = [];
for iA = 1:length(A)

    isA = contains(p.paths, A(iA));
    isNoiseless = isA & contains(p.paths, p.NoiseTagFolder);

    X0 = cellfun(@load, p.paths(isNoiseless));
    if ~ismember(AS(iA), p.Finder)
        switch AS(iA)
        case "SVMs"
        isMachine = contains(X0.parameters.misc.MachineList, "SVM");
        case "Boost/Bag"
        isMachine = ~contains(X0.parameters.misc.MachineList, "SVM");
        end
        Machines = X0.parameters.misc.MachineList(isMachine);
        [~,iX] = min(X0.results.errorRate(isMachine));
        BestMachine = Machines(iX);

        iLevel = find(X0.parameters.misc.MachineList == BestMachine);
        Balance = "";
        Kernel = "";
    else
        [~,iX] = min(arrayfun(@(x) min(x.results.errorRate), X0));
        X1 = X0(iX);

        Balance = "Balanced";%Balances(X1.parameters.multilevel.splitTraining + 1);
        Kernel = "Radial";%Kernels(X1.parameters.svm.kernal + 1);
        [~,iLevel] = min(X1.results.errorRate);
    end

    idx = isA & contains(p.paths, Balance) & contains(p.paths, Kernel) & contains(p.paths, p.NT);
    if sum(idx) ~= 1, keyboard, end
    X1 = load(p.paths{idx});

    ca = squeeze(X1.results.array(:,:,iLevel,:,[1,3]));
    ca = ca(:,1) == ca(:,2);
    ca = ca(~isnan(ca));
    BC(:,iA) = ca;

end

N = size(BC,1);
[~,pval,~,stats] = ttest(BC(:,2), BC(:,1), tail = 'both');
EF = stats.tstat / sqrt(N);
if all( BC(:,1) == BC(:,2))
EF = 0; pval = 1;
end

p.DiscordantArray(iAV, iNT,:) = [EF, pval];
end
%==========================================================================
function p = PlotOnAxes(p)

ax = p.ax(p.DS == p.ds);
MarkerSize = 8;
LineWidth = 2;

hdls = [];
for iAV = 1:length(p.AlgoVersus)
x = p.Noise; 
y = p.DiscordantArray(iAV,:,1); 
p.LineColor = p.LineColors(iAV,:);

hdl = plot(ax,x,y...
    ,Color = p.LineColor...
    ,LineWidth = p.LineWidths(iAV) ...
    ,LineStyle = p.LineStyles(iAV)...
    );
if p.ds == p.DS(end), hdls = [hdls, hdl]; end


Markers = string(discretize(p.DiscordantArray(iAV,:,2), ...
    [0, p.alpha, 1], 'categorical',[p.Markers, "EMPTY"]));

for ial = 1:length(p.alpha)
    Marker = p.Markers(ial);
    xM = x(Markers == Marker);
    yM = y(Markers == Marker);
    plot(ax, xM, yM...
        , LineStyle = "none"...
        , Marker = Marker...
        , MarkerSize = MarkerSize...
        , MarkerFaceColor = "none"...p.LineColors(iAV,:)...
        , MarkerEdgeColor = p.LineColor..."none"...
        , LineWidth = min(p.LineWidths)...
        );
end
end

p.lineHandles = hdls;

end


%==========================================================================
function p = AddLegend(p)

Units = "centimeters";
for iax = 1:length(p.ax)
p.ax(iax).Units = Units;
end

legPos([1,3,4]) = p.ax(end-2).Position([1,3,4]);
legPos(2) = p.ax(end).Position(2);

lFS = p.ax(1).FontSize;

p.leg = legend(p.ax(end), p.lineHandles,...
    'Units', Units,...
    'String', p.AlgoVersus,...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.2*[1 1 1],...
    'Position', legPos);

end
%==========================================================================
function p = GetWindow(p)
ax = p.ax(p.DS == p.ds);

%% Get y-axis data
minWindowSize = 0.05;
Children = findall(ax, 'type', 'line');
YData = [Children.YData];
window = [min(YData), max(YData)];

isBench = ~contains({Children.DisplayName}, ["SVMs", "Boost/Bag"]);
Bench = Children(isBench);
BenchVal = unique([Bench.YData]);
window(1) = min([window(1), BenchVal]);
window(2) = max([window(2), BenchVal]);


%% Construct a sensible scale
windowSize = window(2) - window(1);
%edges =    [0.05, 0.15 , 0.25, 0.5, 1, 2,   4];
%spacings = [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1];
spacings = kron([1, 10, 100], [0.001, 0.0025, 0.005]);
edges = spacings*5;
idx = discretize(windowSize, [0,edges]);
spacing = spacings(idx); 
fspec = "%0.2f";

window(1) = spacing * floor(window(1) / spacing);
window(2) = spacing * ceil(window(2) / spacing);


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
if window(1) < 0 && 0 < window(2)
YTick = [window(1):spacing:0, 0:spacing:window(2)];
YTick = sort(unique(YTick));
is0 = find(YTick == 0)+1;
YTickLabels = arrayfun(@(x) sprintf(fspec, x), YTick);
YTickLabels(is0:-2:1) = "";
YTickLabels(is0:2:end) = "";
else
YTick = window(1):spacing:window(2);
YTickLabels = arrayfun(@(x) sprintf(fspec,x), YTick);
YTickLabels(2:2:end) = "";
end

ax.YLim = window;
ax.YTick = YTick;
ax.YTickLabels = YTickLabels;
ax.YGrid = "on";
ax.XGrid = "on";
ax.GridColor = 0.4*ax.GridColor;

end
%==========================================================================
function ExportGraph(p)

p.plotFolder = fullfile("..", p.Results, p.MOE, p.CrossVal, "Graphs");
if ~isfolder(p.plotFolder), mkdir(p.plotFolder); end
p.plotName = strjoin(["TTest", p.Normalized, p.NoiseTagFolder, "Synthetic"], "_");
p.plotPath = fullfile(p.plotFolder, p.plotName) + ".pdf";
exportgraphics(p.fig, p.plotPath);
close(gcf)

p.texName = "TTest_Graph";
p.texPath = fullfile(p.plotFolder, p.texName) + ".tex";
fID = fopen(p.texPath, "w+");
edit(p.texPath);

CI = 100*(1 - p.alpha);
fprintf(fID, "\\begin{figure}[h!]\n\\centering\n");
fprintf(fID, "\\setlength{\\fboxrule}{0.1pt}\n"); % Thicker border lin
fprintf(fID, "\\setlength{\\fboxsep}{5pt}\n");
fprintf(fID, "\\fbox{\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2.5/%s}}\n", p.texName + ".pdf");
fprintf(fID, "\\caption{%s between Method 1 vs. Method 2. \\protect\\footnotemark}\n", p.EFStat);
fprintf(fID, "\\label{%s}\n", p.plotName);
fprintf(fID, "\\end{figure}\n\n");
fprintf(fID, "\\footnotetext{A %s marker (resp. %s marker) denotes that the corresponding t-test statistic is significant at the %d (resp. %d) significance level.}",...
    p.MarkersC(1), p.MarkersC(2), CI(1), CI(2));

end
