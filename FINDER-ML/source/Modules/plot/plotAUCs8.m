function plotAUCs8

%For each of MLS, ACA, and Benchmark, plot the best AUC and accuracy for
%each of the hyperparameter selection methods. 

close all



%% Set Plot Parameters
YTicks = 0.5:0.05:1;
YTicks2 = 0.6:0.2:1;

%MarkerSize = 20;
tFS = 15;
yFS = 15;
xFS = 15;
lFS = 12;

minmax = @(x) [min(x) max(x)];
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

YTickLabels = repmat({''},size(YTicks)); 
YTickLabels(ismember(YTicks,YTicks2)) = num2cell(YTicks2);
axNames = {'YLim', 'YGrid', 'YTickMode', 'ytick','YTickLabels', 'FontSize'};
axValues = {[0.5, 1], 'on', 'manual', YTicks, YTickLabels, yFS};


LineColors = [0.12, 0.21, 1; %blue
             1, 0.04, 0.12; %red
             0.25, 0.25, 0.25; %black
             0.85, 0.67, 0.2]; %gold


%% Set iterates
Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];
Algos = ["MLS", "ACA-S", "ACA-L", "Benchmark"];

resultFolder = ["Manual_Hyperparameter_Selection", ...
    arrayfun(@(x) sprintf("MethodOfEllipsoids_%d",x), 8:11)];
HPS = ["Manual", "Auto-I", "Auto-II", "Auto-III", "Auto-IV"];
CrossVal = 'Kfold';

DataSets = ["GCM", "newAD", ...
            arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]),...
            arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["EMCI_LMCI", "CN_LMCI", "AD_LMCI", "AD_EMCI", "AD_CN"]) ];

DataAliases = ["GCM", "newAD"...
                arrayfun(@(x) sprintf("ADNI (%s)", x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"]),...
               arrayfun(@(x) sprintf("CSF (%s)",x),...
               ["EMCI vs. LMCI", "CN vs. LMCI", "AD vs. LMCI", "AD vs. EMCI", "AD vs. CN"])...
               ];


%% Iterate over ADNIs, Balances, and Accuracy measures
DSidx = [10,8,7];
for iDS = DSidx
    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    
    f = figure('units','normalized','outerposition',[0.05 0.1 0.85 0.75]);
iplot = 0; 
for iacc = 1:length(Accs)
    Acc = Accs(iacc);

for iBalance = 1:length(Balances)
     Balance = Balances(iBalance);
     barData = nan(length(resultFolder), length(Algos));
     iplot = iplot + 1;


for iMethod = 1:length(resultFolder)
    rF = resultFolder(iMethod);

    %folderpath = fullfile('..', 'results', rF, CrossVal, DS);
    folderpath = fullfile('..', 'results', '**', '*.mat');
    X = dir(folderpath); 
    X(matches({X.name}, [".", ".."])) = [];
    X(~contains({X.name}, DS)) = [];
    X(~contains({X.folder},'Kfold')) = [];
    X = X(contains({X.folder}, rF) | contains({X.name}, 'Benchmark'));

    %Leave_K_out = {X.name};
    % Ks = cellfun(@(x) extractBetween(x, 'Leave_', '_out'), {X.folder}); ...,'UniformOutput',false);
    % Ks = cellfun(@str2num, Ks);
    % [K, iK] = min(Ks(Ks > 1));
    % Leave_K_out = sprintf('Leave_%d_out', K);
    X = X(contains({X.folder}, 'Leave_1_out') ) ;
    

    X2 = X(contains({X.folder}, Balance) | contains({X.name}, 'Benchmark'));
        
        legstr = [];
        for iAlgo = 1:length(Algos)
            Algo = Algos(iAlgo);
            X3 = X2(contains({X2.name}, Algo));

            %% Get Better performing Kernel
            X4 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X3);
            if isempty(X4), keyboard, end
            [~, iBestAcc] = max( arrayfun(@(x) max(x.results.(Acc)), X4));
            X4 = X4(iBestAcc);

            switch X4.parameters.svm.kernal
                case true, l = " w/ RBF";
                case false, l = "w/ Linear";
            end
                  

            if ismember(Algo, ["MLS", "ACA-S", "ACA-L"])
                y1 = max(X4.results.(Acc));
                l = Algo + l;
            elseif Algo == "Benchmark"
                [y1, ix] = max(X4.results.(Acc));
                l = X4.parameters.misc.MachineList(ix);
                l = replace(l, '_', '-');
            end
            
            legstr = [legstr, l];                       
            barData(iMethod, iAlgo) = y1;
        end

        

end


        %% Set up axes
        ax = subplot(2,2,iplot); hold on, 
        
        %Set up title
        if iplot <= 2
        title({DA, Balance}, 'Interpreter', 'latex', 'FontSize', tFS); 
        end

        %Set up y-axes
        if ismember(iplot, [1 3])
        ylabel(capitalize(Acc), 'FontSize', yFS, 'Interpreter', 'latex');
        end
        cellfun(@(x,y) set(ax,x,y), axNames, axValues);

        %Set up data & x-axes
        b = bar(HPS, barData, 'FaceColor', 'flat', 'Interpreter', 'none');
        for k = 1:length(b), for j = 1:size(b(k).CData,1)
            b(k).CData(j,:) = LineColors(k,:); 
        end, end
        
        if ismember(iplot, [1 2])
            ax.XTickLabel = {};
        else
            ax.FontSize = xFS;
            ax.XTickLabelRotation = 30;
            ax.Position(2) = 0.18;
        end

        %Set up legend
        legend(legstr, 'Interpreter', 'latex', 'Location', 'eastoutside', 'FontSize', lFS, 'Box', 'off');
        

end


end

plotPath = fullfile('..','results','MethodOfEllipsoids_4', 'Graphs');
if ~isfolder(plotPath), mkdir(plotPath), end
exportgraphics(f, fullfile(plotPath, sprintf('%s.pdf', DS)));
close(f)

end

end
