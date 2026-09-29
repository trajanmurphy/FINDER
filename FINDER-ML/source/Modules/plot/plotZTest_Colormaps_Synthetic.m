function plotZTest_Colormaps_Synthetic
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
p.plotAll = false;
p.CrossVal = "Synthetic";
p.TrainA = 600;
p.TrainB = 200;
p.Testing = 10000;
p.Noise = 0:0.005:0.02;
p.NanSpacing = 1; 
p.MapSpacing = 10;

p.tFS = 14;
p.aFS = 16;
p.yFS = 16;
p.xFS = 14;
p.mFS = 10;
p.cFS = 11;

p = GetDataSets(p);
p = CreateFigure(p);

for iDS = 1:length(p.DS)
p.ds = p.DS(iDS);  p.da = p.DA(iDS); p.Trunc = p.Truncs(iDS);
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

end

if p.plotAll
p = ComputeEFOverall(p);
p.DS = [p.DS, "All Data Sets"]; p.ds = p.DS(end);
p.DA = [p.DA, p.DS(end)];
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
p.Accs = ["accuracy", "recall", "specificity", "precision"];

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
p.EFStat = "Cohen's $d$";
%p.Clim = [min(p.EFBins), max(p.EFBins)];

p.AllArray = nan(length(p.Algos), length(p.Noise), length(p.DS));
end
%==========================================================================
function p = CreateFigure(p)
p.fig = figure(Units = "normalized", OuterPosition = [0.05,0.05,0.6,0.9]);
p.t = tiledlayout("flow", TileSpacing = "compact", TileIndexing = "rowmajor");

nplots = length(p.DS) + p.plotAll;
for i = 1:nplots
    p.ax(i) = nexttile;
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
function p = FillDiscordantArray(p)

Balances = ["Unbalanced", "Balanced"]; Kernels = ["Linear", "Radial"];

iAV = p.AlgoVersus == p.AV;
iNT = p.NoiseTags == p.NT;
iDS = p.DS == p.ds;

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

        Balance = Balances(X1.parameters.multilevel.splitTraining + 1);
        Kernel = Kernels(X1.parameters.svm.kernal + 1);
        [~,iLevel] = min(X1.results.errorRate);
    end

    idx = isA & contains(p.paths, Balance) & contains(p.paths, Kernel) & contains(p.paths, p.NT);
    if sum(idx) ~= 1, keyboard, end
    X1 = load(p.paths{idx});

    ca = squeeze(X1.results.array(:,:,iLevel,:,[1,3]));
    ca = ca(:,1) == ca(:,2);
    ca = ca(~isnan(ca));
    BC(:,iA) = ca;

    if isnan( p.AllArray( jAV(iA), iNT, iDS) )
    p.AllArray( jAV(iA), iNT, iDS) = X1.results.accuracy(iLevel);
    end

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
function p = ComputeEFOverall(p)

p.DiscordantArray = nan(size(p.DiscordantArray));

for iAV = 1:length(p.AlgoVersus)
for iNT = 1:length(p.Noise)

AV = p.AlgoVersus(iAV);

iAV1 = find(extractBefore(AV, " vs.") == p.AlgosSub);
iAV2 = find(extractAfter(AV, "vs. ") == p.AlgosSub);

x = squeeze(p.AllArray(iAV1,iNT,:));
y = squeeze(p.AllArray(iAV2,iNT,:));

N = length(x);
[~,pval,~,stats] = ttest(y,x, tail = 'both');
EF = stats.tstat / sqrt(N);
if all( x == y)
EF = 0; pval = 1;
end
p.DiscordantArray(iAV, iNT,:) = [EF, pval];
end
end

end
%==========================================================================
function p = PlotOnAxes(p)

iDS = find(p.DS == p.ds);
ax = p.ax(iDS); %axPos = ax.Position;
GS = p.t.GridSize;
nax = numel(findobj(p.t, 'type', 'axes'));

%% Turn Effect Size Array into ImageSC
EffectSize = nan(p.NanSpacing, length(p.Noise));
for iAV = 1:length(p.AlgoVersus)
    Gap = nan(p.NanSpacing, length(p.Noise));
    Map = repmat(p.DiscordantArray(iAV,:,1), p.MapSpacing,1);
    EffectSize = [EffectSize; Map; Gap];
end

h = imagesc(ax, EffectSize, AlphaData = ~isnan(EffectSize));
colormap(p.Colormap);
clim(ax, [-1,1]);
%clim(ax, p.Clim);

%% Add Effect Size String
%EFString = compose("%0.2f", p.DiscordantArray(:,:,1));
PVString = discretize(p.DiscordantArray(:,:,2), [0,p.alpha], 'categorical', p.MarkersC);
PVString = string(PVString); PVString(ismissing(PVString)) = "";
%TxtString = EFString + PVString; 

[X,Y] = meshgrid(1:length(p.Noise),p.YTick);
%for alpha = alphas(1:end-1)
    %isSig = PVString == alpha;
    %Xt = X(isSig);
    %Yt = Y(isSig);
    ann = text(ax, X(:), Y(:)...ax,Xt, Yt...
        ,PVString(:)... ,TxtString(:)....,alpha...
        ,FontSize = p.mFS...
        ,Interpreter = "latex"...
        ,HorizontalAlignment="center"...
        ,VerticalAlignment="middle"...
        ,EdgeColor="none"...
        );

%end


%% Amend Y Axis
if mod(iDS,GS(1)) == 1
ax.YTick = p.YTick;
ax.YTickLabels = p.AlgoVersus;
else
ax.YTickLabels = {''};
end

%% Amend X Axis
ax.XLim = [0.5, length(p.Noise)+0.5];
if iDS > GS(1) * (GS(2) - 1)
ax.XTick = 1:length(p.Noise);
ax.XTickLabels = string(p.Noise);
ax.XTickLabels(2:2:end) = {''};
ax.XTickLabelRotation = 0;
else
ax.XTickLabels = {''};
end

%% Add Colorbars
if mod(iDS,GS(2)) == 0 || iDS == nax
c = colorbar(ax, FontSize = p.cFS, TickLabelInterpreter = "latex");
%clim(ax, [min(p.EFBins), max(p.EFBins)]);
%c.Ticks = p.EFBins;
c.Ticks = [-0.8,-0.5,-0.2,0.2,0.5,0.8];
end

%% Amend Both Axes
for Z = ["Y", "X"]
ax.(Z + "Axis").TickLabelInterpreter = "latex";
ax.(Z + "Axis").FontSize = p.(lower(Z) + "FS");
end

%% Add Title
title(ax, p.DA(iDS), FontSize = p.tFS, Interpreter = "latex");

if iDS == 1
%% Add X Label
annPos = [0,0.01,1,0.04];
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
p.plotName = strjoin(["TTest", p.Normalized, "Synthetic", "Colormap"], "_");
p.plotPath = fullfile(p.plotFolder, p.plotName) + ".pdf";
exportgraphics(p.fig, p.plotPath);
close(gcf)

p.texName = "TTest_Graph";
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
fprintf(fID, "\\footnotetext{A %s marker (resp. %s marker) denotes that the corresponding t-test statistic is significant at the %d (resp. %d) significance level.}",...
    p.MarkersC(1), p.MarkersC(2), CI(1), CI(2));

end
