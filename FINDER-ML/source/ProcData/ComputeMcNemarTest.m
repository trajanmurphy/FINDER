Datasets = [...
              "newAD", 
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
rF = ["results"];
CV = ["Kfold"];
Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];




for DS = Datasets(:)'
  fprintf('Processing %s \n', DS);

  %Get Balanced result
  homePath = fullfile('..', rF, 'Manual_Hyperparameter_Selection', CV, DS, 'Leave_1_out');
  X = dir(fullfile(homePath, '**', '*.mat'));
  isBench = contains({X.name}, 'Benchmark');
  XB = X(isBench);
  YB = load(fullfile(XB.folder, XB.name));

for Acc = Accs

  [BestBaseline,iBest] = max(YB.results.(Acc));

  BenchmarkActual = squeeze(YB.results.array(:,:,iBest,:,1));
  BenchmarkActual = BenchmarkActual(~isnan(BenchmarkActual));
  BenchmarkPredicted = squeeze(YB.results.array(:,:,iBest,:,3));
  BenchmarkPredicted = BenchmarkPredicted(~isnan(BenchmarkPredicted));
  BenchmarkCorrect = BenchmarkActual == BenchmarkPredicted;
  BenchmarkIncorrect = ~BenchmarkCorrect;

  XF = X(~isBench);

for i = 1:length(XF)
   % fprintf('\n%s\n', extractBefore(XF(i).name, '-Eigen'));
    
    %Get result
    fileName = fullfile(XF(i).folder, XF(i).name);
    YF = load(fileName);
    nL = size(YF.results.array,3);

    pvaluesMcNemar = nan(1,nL);
    pvaluesWilcoxon = pvaluesMcNemar;
    for iL = 1:nL
    
    FinderActual = squeeze(YF.results.array(:,:,iL,:,1));
  FinderActual = FinderActual(~isnan(FinderActual));
  FinderPredicted = squeeze(YF.results.array(:,:,iL,:,3));
  FinderPredicted = FinderPredicted(~isnan(FinderPredicted));
  FinderCorrect = FinderActual == FinderPredicted;
  FinderIncorrect = ~FinderCorrect;

[C, order] = confusionmat(BenchmarkCorrect, FinderCorrect, 'Order', [1 0]); 
order = string(num2str(order));
C = array2table(C, RowNames = ["True0" "True1"], VariableNames = ["Predicted0" "Predicted1"]);
%disp(C)


  B = sum(BenchmarkCorrect & FinderIncorrect);
  C = sum(BenchmarkIncorrect & FinderCorrect);
  
  switch YF.results.(Acc)(iL) > BestBaseline
      case true 
         testStatistic = (abs(B - C) - 1)^2 / (B + C);
      case false 
          testStatistic = 0;
  end
  pvaluesMcNemar(iL) = chi2cdf(testStatistic,1,'upper');
  pvaluesWilcoxon(iL) = signrank(double(FinderCorrect), ...
      double(BenchmarkCorrect), 'tail', 'right');
 
    end

   fieldnameMcNemar = sprintf('McNemar_pvalue_%s', Acc);
   fieldnameWilcoxon = sprintf('Wilcoxon_pvalue_%s', Acc);
  YF.results.(fieldnameMcNemar) = pvaluesMcNemar;
  YF.results.(fieldnameWilcoxon) = pvaluesWilcoxon;

  % fprintf('\nMcNemar p-values: \n');
  % fprintf('%0.3f, ', pvaluesMcNemar);
  % fprintf('\nWilcoxon p-values: \n', pvaluesWilcoxon);
  % fprintf('%0.3f, ', pvaluesWilcoxon);
  save(fileName, '-struct', 'YF');

end

end 

end 








