Datasets = [...
            "GCM",
            "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscn7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            ];

thisdir = pwd;
methods = DefineMethods;


for DS = Datasets'
    fprintf('Processing %s\n', DS);
    folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Synthetic', DS,'600_TrainingA_200_TrainingB_10000_Testing');
    d = dir(fullfile(folder, '**', '*.mat'));
    d(contains({d.folder}, 'id_old')) = [];
    d(contains({d.folder}, [".", ".."])) = [];

    dates = datetime({d.date}); 
    nowish = datetime("now") - 12/24;
    outstanding = dates <= nowish;
    if any(outstanding)
    fprintf('\t%s\n', d(outstanding).name);
    end
    

    for id = d'
        path = fullfile(id.folder, id.name);
        Y1 = load(path);
        Y1.parameters.multilevel.Mres = Y1.parameters.multilevel.Mres_auto;
        save(path, "-struct", "Y1");
    end


end







