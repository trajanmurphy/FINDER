function parameters = GetCommonParameters(parameters, methods)

if ismember(parameters.data.label, methods.data.ADNI_files)
    parameters.data.path = '/restricted/projectnb/sctad/ADNI_Plasma_Sicheng/';
    parameters.snapshots.k1 = 5;
elseif ismember(parameters.data.label, methods.data.CSF_files)
    parameters.data.path = ...
        '/restricted/projectnb/sctad/Audrey/SOMAscan7k_KNNimputed_formatted_data/';
    parameters.snapshots.k1 = 8;
elseif strcmp(parameters.data.label, 'GCM')
    parameters.data.path = '';
    parameters.snapshots.k1 = 39; 
elseif strcmp(parameters.data.label, 'newAD')
    parameters.data.path = '/restricted/projectnb/sctad/Codes/Yumeng/';
    parameters.snapshots.k1 = 8;
end

NAT(:,1) = string(methods.data.all_files)';
NAT(:,3) = ["Normal"; "CN"; ...
    "CN"; "LMCI"; "CN";...
    "CN"; "EMCI" ; "LMCI"; "CN"; "CN";"EMCI"];
NAT(:,2) = ["Tumor"; "AD";...
    "AD";"AD";"LMCI";...
    "AD";"AD";"AD";"EMCI";"LMCI";"LMCI"];

idx = strcmp(NAT(:,1), parameters.data.label);
parameters.data.nominal = char(NAT(idx,2));
parameters.data.anomalous = char(NAT(idx,3));

