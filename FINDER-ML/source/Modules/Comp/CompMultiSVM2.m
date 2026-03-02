clc;
clear all;
close all;


methods = DefineMethods;

MOEs = arrayfun( @(x) str2func(sprintf('MethodOfEllipsoids_%d',x)), 8:11, 'UniformOutput', false);

DS = [methods.data.ADNI_files,...
     {'newAD'},...
     methods.data.CSF_files([1 3 5]),...
     {'GCM'}];

D = methods.all.ValuesTable('Balance', {true, false},...
                            'Kernel', {true, false},...
                            'Eigenspace', {'smallest', 'largest'},...
                            'ChooseTrunc', {true},...
                            'Name', DS,...
                            'Ellipsoid', MOEs,...
                            'PCA', {true},...
                            'Algorithm', {2,0});

D = D(100:end,:);
D = D(D.Balance & D.Kernel,:);

for irow2 = 1:height(D)/2
delete(gcp('nocreate'));
parameters =  methods.all.initialization();
parameters.multilevel.splitTraining = D.Balance(irow2); %D{irow2,1};
parameters.svm.kernal = D.Kernel(irow2); %D{irow2,2};
parameters.multilevel.eigentag = D.Eigenspace{irow2}; % D{irow2,3};
parameters.multilevel.svmonly = D.Algorithm(irow2); %D{irow2,4};
%parameters.multilevel.nested = D.Nesting(irow2);
parameters.misc.PCA = D.PCA(irow2);
parameters.multilevel.chooseTrunc = D.ChooseTrunc(irow2);
methods.Multi2.ChooseTruncations = D.Ellipsoid{irow2};

parameters.data.label = D.Name{irow2};
parameters.data.name = [parameters.data.label '.txt'];
parameters = methods.data.GetCommonParameters(parameters, methods);
    
    

 t0 = tic;
 for k = 1:parameters.data.nk
     t1 = toc(t0);

      % Read Data
      parameters.data.currentiter=k; 
      [Datas, parameters] = methods.all.readcancerData(parameters, methods);     
      
        %Initialize Max Multilevel if need be.
      parameters = methods.all.GetMaxMultiLevel(Datas, parameters, methods);
    

      % Create results structure
      [results] = methods.all.iniresults(parameters);

      


     
     %parameters.transform.istransformed = false;
     
     % Data size
      % update parameters.data.n to number of simulated data points
     [parameters] = methods.all.Datasize(Datas, parameters);

     %Plot Data if handles are there
      if parameters.transform.createPlots
      if ~isempty(methods.transform.createPlot)
          for i = 1:length(methods.transform.createPlot)
              plotHandle = methods.transform.createPlot{i};
              plotHandle(Datas, parameters, methods);
          end
          return
      end
      end

     %Generate random genes
     
     % select random genes
     [Datas] = methods.all.selectgene(Datas, parameters.data.numofgene, parameters.data.B);


     
     switch parameters.multilevel.svmonly 
         case 1
         %SVM Only
         results = methods.SVMonly.CompSVMonly(methods, Datas, parameters, results);
         case 0
         % Multilevel Method with SVM
         results = methods.Multi.CompMulti(methods, Datas, parameters, results);
         %parameters = ResidDimensionForMOLS(Datas, parameters, methods);
         case 2
         %Trajan's Multilevel Method with SVM
         results = methods.Multi2.CompMulti(Datas, parameters, methods, results);
         case 3
         results = methods.Multi2.FeatureSelect(Datas, parameters, methods, results);
         case 4
         results = methods.misc.Ablations(Datas, parameters, methods, results);
             
     end

     
     results = methods.all.ComputeAccuracyAndPrecision(Datas, parameters, methods, results);

     t2 = toc(t0);
      
      results.run_time = duration(0,0,t2 - t1, 'Format', 'hh:mm:ss');
      results.creation_time = datetime;
      

     parameters = methods.all.filefunc(parameters, methods);
     Datas.rawdata.AData = []; Datas.rawdata.BData = [];
     save(fullfile(parameters.datafolder,parameters.dataname), 'parameters', 'results', 'Datas');
     save('irow2.mat', 'irow2');
     clear Datas parameters results

end

end
 

