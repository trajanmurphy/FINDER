function parameters = GetCommonParameters(parameters, methods)

if ismember(parameters.data.label, methods.data.ADNI_files)
    parameters.data.path = '/restricted/projectnb/sctad/ADNI_Plasma_Sicheng/';
    parameters.snapshots.k1 = 5;
    parameters.multilevel.Mres_manual = 20:20:140;
elseif ismember(parameters.data.label, methods.data.CSF_files)
    parameters.data.path = ...
        '/restricted/projectnb/sctad/Audrey/SOMAscan7k_KNNimputed_formatted_data/';
    parameters.snapshots.k1 = 8;
     parameters.multilevel.Mres_manual = 700:700:6998;
elseif strcmp(parameters.data.label, 'GCM')
    parameters.data.path = '';
    parameters.snapshots.k1 = 39; 
     parameters.multilevel.Mres_manual = 1600:1600:16000;
elseif strcmp(parameters.data.label, 'newAD')
    parameters.data.path = '/restricted/projectnb/sctad/Codes/Yumeng/';
    parameters.snapshots.k1 = 8;
     parameters.multilevel.Mres_manual = 200:200:2000;
end