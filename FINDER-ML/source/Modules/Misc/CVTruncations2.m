function CVTruncations2

%% Initialize Datas, parameters, methods
methods = DefineMethods;

parameters = methods.all.initialization();
parameters.multilevel.chooseTrunc = true;

DS = [...
     methods.data.ADNI_files...  
     ,{'GCM', 'newAD'}...  
     ,methods.data.CSF_files([1 3 5])...
      ];

D = methods.all.ValuesTable(...
                            'Balance', {false,true},...
                            'Kernel', {false,true},...
                            'Algorithm', {0}, ...
                            'CRS', {@MLS_FCT_FCD_CV2},...
                            'Name', DS ...
                            );

warning('off', 'all')

for irow = 13:height(D)

%% Set Up Parameters
parameters.multilevel.splitTraining = D.Balance(irow);
parameters.svm.kernal = D.Kernel(irow);
parameters.multilevel.svmonly = D.Algorithm(irow);
methods.Multi.Filter = D.CRS{irow};
parameters.data.label = D.Name{irow};
parameters.data.name = [D.Name{irow}, '.txt'];
parameters = methods.data.GetCommonParameters(parameters, methods);

[Datas, parameters] = methods.all.readcancerData(parameters, methods);     
parameters = methods.all.Datasize(Datas, parameters);

%% Initialize Truncation Array
[A,B] = meshgrid(parameters.data.NAvals, parameters.data.NBvals);
pairs = [A(:), B(:)];
npairs = size(pairs,1);

p.parameters = parameters;
p.Datas = Datas;
p.methods = methods;
TruncArray = nan(size(pairs));

parameters = methods.all.filefunc(parameters, methods);
Path = fullfile(parameters.datafolder, parameters.dataname);

if ~isfile(Path)
fprintf("File Not Found\n");
keyboard
continue
end

parfor i = 1:npairs
    pair = pairs(i,:);
    p2 = p;
    p2.pair = pair;
    p2.ipair = i;
    p3 = FillPairArray(p2);
    TruncArray(i,:) = p3.HPpair;
end

X = load(Path);
X.results.Truncarray = TruncArray;
save(Path,"-struct", "X");
save("irow.mat", "irow");


end


end

%==========================================================================

function p = FillPairArray(p)

parameters = p.parameters;
Datas = p.Datas;
methods = p.methods;

parameters.data.i = p.pair(1);
parameters.data.j = p.pair(2);

Datas = methods.all.prepdata(Datas, parameters, methods);
[~,parameters] = methods.Multi.Filter(Datas, parameters, methods);
p.HPpair = [parameters.snapshots.k1, parameters.multilevel.Mres];



end