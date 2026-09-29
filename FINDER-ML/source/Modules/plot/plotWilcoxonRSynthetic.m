function plotWilcoxonRSynthetic
close all

p.DSidx = [1:8];
p.Results = "results";
p.alpha = [0.0001, 0.001, .05];
p.MarkersC = ["*", "**", "***"];
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
p.Accs = ["accuracy", "recall", "specificity", "precision"];
p.NanSpacing = 1; 
p.MapSpacing = 10;

p.tFS = 14;
p.aFS = 16;
p.yFS = 14;
p.xFS = 14;
p.mFS = 10;
p.cFS = 11;

p = GetDataSets(p);
p = CreateFigure(p);

for iAcc = 1:length(p.Accs)
p.Acc = p.Accs(iAcc);
fprintf("Processing %s\n", p.Acc);
p.MetricArray = nan(length(p.Algos), length(p.Noise), length(p.DS));
p.WilcoxonRArray = nan(length(p.AlgoVersus), length(p.Noise),2);

    for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS);  p.da = p.DA(iDS); p.Trunc = p.Truncs(iDS);
    p = GetFiles(p);

    for iNoise = 1:length(p.Noise)
    p.NT = p.NoiseTags(iNoise);
    p = FillWilcoxonRArray(p);
    p = ComputeEffectSizes(p);
    end

    end
    
    p = PlotOnAxes(p);

end

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


%% Make Noise Tags
p.NoiseTags = arrayfun(@(x) sprintf("Noise_%g",x), p.Noise);
p.NoiseTagFolder = replace(p.NoiseTags(2), ".", "_");
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
nAV = length(p.AlgoVersus);

%% YAxis Data
NTicks = nAV*p.MapSpacing + (nAV + 1)*p.NanSpacing;
Start = p.NanSpacing + p.MapSpacing / 2;
TickSpacing = p.NanSpacing + p.MapSpacing;
p.YTick = Start:TickSpacing:NTicks;


%% Make Colormap
DF = 0.7; WF = 0.75; GF = 0.8;
red = [1,0,0]; green = [0,1,0]; white = [1,1,1];
gradiate = @(x) [DF*x ; x ; (1-WF)*x + WF*white];
makemap  = @(x1, x2) [gradiate(x1); GF*white ; flipud(gradiate(x2))];
C0 = makemap(red, green);
mypower = @(x,n) sign(x) .* (abs(x).^n); n = 1;
X = mypower(linspace(-1,1,size(C0,1)), n); 
Xq = mypower(linspace(-1,1,100), n);
for i = 1:3
p.Colormap(:,i) = interp1(X, C0(:,i), Xq, "linear");
end
p.Colormap = min(p.Colormap, 1); p.Colormap = max(p.Colormap, 0);

%% Put Information for effect size/statistical significance
p.yStr = "Effect Size";
p.EFStat = "Wilcoxon's $r$";
p.capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
end
%==========================================================================
function p = CreateFigure(p)
nAccs = length(p.Accs);
p.fig = figure(Units = "normalized", OuterPosition = [0.05,0.05,0.6,0.4]);
t = tiledlayout(1, nAccs, TileSpacing = "compact", TileIndexing = "rowmajor", Padding = "loose");
Positions = nan(nAccs, 4);
for i = 1:nAccs
    p.ax(i) = nexttile;
    % Position = ax0.Position; 
    % Positions(i,:) = [1,2,1,0.8].*Position;
    %Positions(i,:) = Position;
end
% clf
% for i = 1:nAccs
%     p.ax(i) = axes(Position = Positions(i,:));
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


end
%==========================================================================
function p = FillWilcoxonRArray(p)

Balances = ["Unbalanced", "Balanced"]; Kernels = ["Linear", "Radial"];

iAcc = p.Accs == p.Acc;
iNT = p.NoiseTags == p.NT;
iDS = p.DS == p.ds;

for iA = 1:length(p.AlgosSub)
    A = p.Algos(iA);
    AS = p.AlgosSub(iA);
    isA = contains(p.paths, A);
    isNoiseless = isA & contains(p.paths, p.NoiseTagFolder);

    X0 = cellfun(@load, p.paths(isNoiseless));
    if ~ismember(AS, p.Finder)
        switch AS
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

        Balance = Balances(X1.parameters.multilevel.splitTraining + 1);
        Kernel = Kernels(X1.parameters.svm.kernal + 1);
        [~,iLevel] = min(X1.results.errorRate);
    end

    idx = isA & contains(p.paths, Balance) & contains(p.paths, Kernel) & contains(p.paths, p.NT);
    if sum(idx) ~= 1, keyboard, end
    X1 = load(p.paths{idx});

    metric = X1.results.(p.Acc)(iLevel);
    p.MetricArray(iA, iNT, iDS) = metric;
end

end
%==========================================================================
function p = ComputeEffectSizes(p)
iNT = p.NoiseTags == p.NT; 

for iAV = 1:length(p.AlgoVersus)
AV = p.AlgoVersus(iAV);
iAV1 = find(extractBefore(AV, " vs.") == p.AlgosSub);
iAV2 = find(extractAfter(AV, "vs. ") == p.AlgosSub);

x = squeeze(p.MetricArray(iAV1,iNT,:));
y = squeeze(p.MetricArray(iAV2,iNT,:));

N = length(x);
[pval,~,~] = signrank(y,x, tail = 'both', method = "exact");
[~,~,stats] = signrank(y,x, tail = 'both', method = "approximate");
EF = stats.zval / sqrt(N);
if all( x == y)
EF = 0; pval = 1;
end

p.WilcoxonRArray(iAV, iNT,:) = [EF, pval];

end


end
%==========================================================================
function p = PlotOnAxes(p)

iAcc = find(p.Accs == p.Acc);
ax = p.ax(iAcc);
nax = length(p.Accs);

%% Turn Effect Size Array into ImageSC
NC = size(p.WilcoxonRArray,2);
EffectSize = nan(p.NanSpacing, NC);
for iAV = 1:length(p.AlgoVersus)
    Gap = nan(p.NanSpacing, NC);
    Map = repmat(p.WilcoxonRArray(iAV,:,1), p.MapSpacing,1);
    EffectSize = [EffectSize; Map; Gap];
end

h = imagesc(ax, EffectSize, AlphaData = ~isnan(EffectSize));
colormap(p.Colormap);
clim(ax, [-1,1]);

%% Add Effect Size String
PVString = discretize(p.WilcoxonRArray(:,:,2), [0,p.alpha], 'categorical', p.MarkersC);
PVString = string(PVString); PVString(ismissing(PVString)) = "";

[X,Y] = meshgrid(1:length(p.Noise),p.YTick);

    ann = text(ax, X(:), Y(:)...
        ,PVString(:)... 
        ,FontSize = p.mFS...
        ,Interpreter = "latex"...
        ,HorizontalAlignment="center"...
        ,VerticalAlignment="middle"...
        ,EdgeColor="none"...
        );

%% Amend Y Axis
if iAcc == 1
ax.YTick = p.YTick;
ax.YTickLabels = p.AlgoVersus;
else
ax.YTickLabels = {''};
end

%% Amend X Axis
ax.XLim = [0.5, length(p.Noise)+0.5];
ax.XTick = 1:length(p.Noise);
ax.XTickLabels = string(p.Noise);
ax.XTickLabels(2:2:end) = {''};
ax.XTickLabelRotation = 0;


%% Add Colorbars
if iAcc == nax
c = colorbar(ax, FontSize = p.cFS, TickLabelInterpreter = "latex");
c.Ticks = [-0.8,-0.5,-0.2,0.2,0.5,0.8];
end

%% Amend Both Axes
for Z = ["Y", "X"]
ax.(Z + "Axis").TickLabelInterpreter = "latex";
ax.(Z + "Axis").FontSize = p.(lower(Z) + "FS");
end

%% Add Title
title(ax, p.capitalize(p.Acc), FontSize = p.tFS, Interpreter = "latex");

if iAcc == 1
%% Add X Label
annPos = [0,-0.04,1,0.04];
 ann(1) =  annotation("textbox"...
        ,String = "Noise"...
        ,Units = "normalized"...
        ,Position = annPos...
        ,Interpreter = "latex"...
        ,FontSize = p.aFS...
        ,HorizontalAlignment="center"...
        ,VerticalAlignment="middle"...
        ,EdgeColor = "none");

pvalstr = compose("$^{%s}p < %g$", p.MarkersC(:), p.alpha(:));
pvalstr = strjoin(pvalstr, sprintf(", "));

ann(2) = annotation("textbox"...
        ,String = pvalstr...
        ,Units = "normalized"...
        ,Position = annPos...
        ,FontSize = p.tFS...
        ,Interpreter = "latex"...
        ,EdgeColor = "none"...
        ,BackGroundColor = "none"...
        ,HorizontalAlignment="right"...
        ,VerticalAlignment="middle");
end

end
%==========================================================================
function ExportGraph(p)
Accstr = strjoin(upper(extractBefore(p.Accs,4)),"-");
p.plotFolder = fullfile("..", p.Results, p.MOE, p.CrossVal, "Graphs", Accstr, p.NoiseTagFolder, "Colormaps");
if ~isfolder(p.plotFolder), mkdir(p.plotFolder); end
p.plotName = strjoin(["Wilcoxon_r", p.Normalized, "Synthetic", "Colormap"], "_");
p.plotPath = fullfile(p.plotFolder, p.plotName) + ".pdf";
exportgraphics(p.fig, p.plotPath);
close(gcf)

p.texName = "Wilcoxon_R_Synthetic";
p.texPath = fullfile(p.plotFolder, p.texName) + ".tex";
fID = fopen(p.texPath, "w+");
%edit(p.texPath);

CI = 100*(1 - p.alpha);
fprintf(fID, "\\begin{figure}[h!]\n\\centering\n");
fprintf(fID, "\\setlength{\\fboxrule}{0.1pt}\n"); % Thicker border lin
fprintf(fID, "\\setlength{\\fboxsep}{5pt}\n");
fprintf(fID, "\\fbox{\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2.5/%s}}\n", p.texName + ".pdf");
fprintf(fID, "\\caption{%s between Method 1 vs. Method 2.}", p.EFStat);
fprintf(fID, "\\label{%s}\n", p.plotName);
fprintf(fID, "\\end{figure}\n\n");
%fprintf(fID, "\\footnotetext{A %s marker (resp. %s marker) denotes that the corresponding Wilcoxon's signed rank statistic is significant at the %d (resp. %d) significance level.}",...
%    p.MarkersC(1), p.MarkersC(2), CI(1), CI(2));

end
