function WriteTimeTable2
close all
warning('off','all')

p.NTakes = 8;
p.DSidx = [1:8];
rng(0);

p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

methods = DefineMethods();
p = CreateDataLabels(p);
for iDS = 1:length(p.DS)
p.ds = p.DS(iDS);
p.da = p.DA(iDS);
p.Trunc = p.Truncs(iDS);
fprintf('Processing %s \n', p.da);  

for iM = 1:p.NMachines 
fprintf('\t %s. ', p.LegendString(iM));
p.Algo = p.Classifiers(iM,:);
p = GetBestRegime(p);
load(p.Path);
[Datas,parameters] = methods.all.readcancerData(parameters, methods);

if p.isFinder(p.Algo(1))
parameters.multilevel.Mres = parameters.multilevel.Mres(p.BestLevel);
parameters.multilevel.l = 1;
end
       

for iT = 1:p.NTakes
    parameters.data.i = randi(max(parameters.data.NAvals));
    parameters.data.j = randi(max(parameters.data.NBvals));
    parameters2 = parameters;
    Datas2 = methods.all.prepdata(Datas, parameters, methods);
   
    t0 = tic; 
    if p.Algo(1) == "MLS"
        l = parameters.multilevel.l;
        t1 = toc(t0);
        [Datas2, parameters2] = methods.Multi.Filter(Datas2, parameters2, methods);
        [Datas2, parameters2] = methods.Multi.machine(Datas2, parameters2, methods,l);
    elseif contains(p.Algo(1), "ACA") 
        t1 = toc(t0);
        Datas2 = methods.Multi2.ConstructResidualSubspace(Datas2, parameters, methods);
        parameters2.multilevel.iMres = 1;
        Datas2 = methods.Multi2.SepFilter(Datas2, parameters2, methods); 
        Datas2 = methods.SVMonly.Prep(Datas2); 
        parameters2 = methods.SVMonly.fitSVM(Datas2, parameters2, methods); 
    else 
        machine = p.Algo(1);
        parameters2.misc.PCA = contains(machine, "PCA");
        machine = replace(machine, "-PCA", "");
        t1 = toc(t0);   
        [Datas2, parameters2] = methods.misc.PCA(Datas2, parameters2, methods);
        Datas2 = methods.misc.prep(Datas2); 
        parameters2.multilevel.SVMModel = methods.misc.(machine)(Datas2.X_Train, Datas2.y_Train);
    end
    methods.all.predict(Datas2, parameters2, methods);
    t2 = toc(t0);

    p.Run_Times(iDS, iM, iT) = t2 - t1;
    Datas2 = Datas;
    parameters2 = parameters;
end
rt = squeeze(p.Run_Times(iDS, iM, :));
mrt = mean(rt);
trt = sum(rt);
fprintf(' Elapsed Time: %0.2f s (mean = %0.2f s).\n', trt, mrt);
    


end

    
    
    

end
p.Run_Times = trimmean(p.Run_Times, 20, 3);
save(fullfile(p.TablePath, 'RunTimeData.mat'), "p");
fprintf('All Done! \n')
end

%==========================================================================
function p = CreateDataLabels(p)


%% Enter Data Set Info:
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
p.DS = DataSets;
p.DA = DataAliases;

%p.isGenetic = ismember(p.DS, p.DS(1:2));
p.isGCM = p.DS == "GCM";
p.isnewAD = p.DS == "newAD";
p.isPlasma = ismember(p.DS, p.DS(3:5));
p.isCSF = ismember(p.DS, p.DS(6:8));

%p.Sources = ["Genetic", "Plasma", "CSF"];
p.Sources = ["GCM", "newAD", "Plasma", "CSF"];
fields = ["DS", "DA", "is" + p.Sources, "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

p.Balances = ["Balanced", "Unbalanced"];
p.Kernels = ["Linear", "Radial"];
p.Finder = ["MLS", "ACA-S", "ACA-L"]; 

p.TablePath = fullfile("..",p.Results,p.MOE, p.CrossVal, "Tables");
if ~isfolder(p.TablePath), mkdir(p.TablePath); end

%% Algorithms
F = ["MLS", "ACA-S", "ACA-L"]; K = ["Linear", "Radial"];
[F,K] = meshgrid(F,K); FK = [F(:), K(:)]; 
[S,K2,P] = ndgrid("SVM_", ["Linear", "Radial"], ["", "-PCA"]);

p.Algos = [FK ; "Benchmark" ""];
p.SVMs = S(:) + K2(:) + P(:);
p.Boosts = ["LogitBoost"; "RUSBoost"; "Bag"];
p.Benchmarks = [p.SVMs ; p.Boosts];
p.Classifiers = [FK ; p.Benchmarks , repmat("", size(p.Benchmarks))];

%% Accuracy Measures
p.Accs = ["errorRate", "recall", "specificity", "precision"];

%% Legend String
p.FINDER = F(:) + "-" + K(:);
p.LegendString = replace([p.FINDER; p.Benchmarks], ["Linear", "Radial"], ["Lin", "RBF"]);
p.isFinder = @(str) contains(str, ["MLS", "ACA-S", "ACA-L"]);

p.NMachines = length(p.LegendString);
p.Run_Times = nan(length(p.DS), p.NMachines, p.NTakes);
end
%==========================================================================
function p = GetBestRegime(p)
DataPath = fullfile("..", p.Results, p.MOE, p.CrossVal, p.ds,p.HoldOut, "**", "*.mat");
X = dir(DataPath); 
Paths = fullfile({X.folder}, {X.name});

idx = contains(Paths, p.Normalized);
if p.isFinder(p.Algo(1))
idx = idx & ...
    contains(Paths, "Eigen-" + p.Trunc) & ...
    contains(Paths, p.Algo(1)) & ... 
    contains(Paths, p.Algo(2));
end

Paths = Paths(idx);
if isempty(Paths), keyboard, end
X = cellfun(@load, Paths);

im = 1;
if p.isFinder(p.Algo(1))
m = arrayfun(@(x) min(x.results.errorRate), X);
[~,im] = min(m);
[~, p.BestLevel] = min(X(im).results.errorRate); 
end
p.Path = Paths{im};

if iscell(p.Path), keyboard, end
end
%==========================================================================

