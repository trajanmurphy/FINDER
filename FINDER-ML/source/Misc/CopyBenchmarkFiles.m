Datasets = ["newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscan7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            "GCM"...
            ];

myload = @(x) load(fullfile(x.folder, x.name));
thisdir = pwd;
methods = DefineMethods;
resultsFolders = ["Manual_Hyperparameter_Selection"];
CV = ["Kfold"];
Balances = ["Balanced", "Unbalanced"];


for DS = Datasets(:)'
    fprintf('Processing %s \n', DS);
for rF = resultsFolders

    homePath = fullfile('..', 'results', rF, CV, DS, 'Leave_1_out', '**', '*.mat');
    

    
end 
end

numFiles = 0;
for i = 8:11
    f = fullfile('..', 'results', sprintf('MethodOfEllipsoids_%d', i), '**', '*.mat');
    numFiles = numFiles + length(dir(f));
end
disp(numFiles)
