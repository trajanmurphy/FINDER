Datasets = [...
            "GCM",
            "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            "SOMAscan7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",            
            ];

Noise = 0:0.02:0.1;
NoiseTags = arrayfun(@(x) sprintf("Noise_%g",x), Noise);
NoiseTags = replace(NoiseTags, ".", "_");

Truncs = [39,8,5,5,5,8,8,8];

thisdir = pwd;
methods = DefineMethods;

Accs = ["AUC", "accuracy"];
Balances = ("Balanced"|"Unbalanced");
Kernels = ("Linear"|"Radial");
Algos = ("MLS"|"ACA-S"|"ACA-L"|"Benchmark");
Normalize = ("MyUnitVariance2");
PatternArray = [Balances, Kernels, Algos, Normalize];

for DS = Datasets(:)'
fprintf("Processing %s\n", DS);
%for NoiseTag = NoiseTags
    Folder = fullfile("..", "results", "Manual_Hyperparameter_Selection", "Synthetic");
    oldFolder = fullfile(Folder, DS, "*", "*");
    oldFolders = dir(oldFolder);
    oldFolders = oldFolders(~ismember({oldFolders.name}, [NoiseTags, ".", ".."]));
    oldFolders = string(fullfile({oldFolders.folder}, {oldFolders.name}));
    replaceFun = @(OF) string(replaceBetween(OF, "Synthetic", DS, "/old_files/"));
    newFolders = arrayfun(replaceFun, oldFolders);
    %fullfile(Folder, "old_files", DS, NoiseTag);
    arrayfun( @(OF, NF) movefile(OF, NF), oldFolders, newFolders);
    
%end
end












