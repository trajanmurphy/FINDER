function [parameters] = InitializeParameters()

%% Data parameters
parameters.data.path = '';
%'/restricted/projectnb/sctad/Audrey/SOMAscan7k_KNNimputed_formatted_data/';
%'/restricted/projectnb/sctad/ADNI_Plasma_Sicheng/';
%'';
%'/restricted/projectnb/sctad/Codes/Yumeng/';



parameters.data.label = 'Plasma_M12_CNLMCI';
%'SOMAscan7k_KNNimputed_EMCI_LMCI';
%'GCM';
%'newAD'; 

parameters.data.name = [parameters.data.label, '.txt'];

parameters.data.validationType = 'Synthetic';  %One of 'Synthetic', 'Kfold', or 'Cross'
parameters.data.numofgene = []; % Set to empty array [] to initialize as latent data dimension
parameters.data.normalize = 1; % if 1 then Data standarized
parameters.data.randomize = true; % true = randomly permute data upon loading

%% Cross Validation Parameters
parameters.cross.NTestA = 1;
parameters.cross.NTestB = 1;


%% K-fold parameters
parameters.Kfold = 1; %If parameters.data.generealization is set to 1,


%% Semi-synthetic data realization parameters
parameters.synthetic.functionTransform = []; %if 'id';
parameters.synthetic.GaussianNoiseFactor = [];
parameters.synthetic.NKLTerms = 88; % KL Truncation for generating Semisynthetic Data
parameters.synthetic.Ars = [600];
parameters.synthetic.Brs = [200];
parameters.synthetic.NTest = 10000;


%% MultiLevel parameters
parameters.snapshots.k1 = 8;% KL Truncation for Class A
parameters.multilevel.svmonly = 1; % 0 = MLS, 1 = Benchmark, 2 = ACA
parameters.multilevel.splitTraining = true; % true = Balanced, false = Unbalanced
parameters.multilevel.eigentag = 'largest'; %'largest' = ACA-L, 'smallest' = ACA-S
parameters.multilevel.Mres_manual = [];%200:200:2000;
parameters.multilevel.Mres_auto = 'MLS';
%parameters.multilevel.Mres = unique([parameters.multilevel.Mres_manual(:),...
 %                             parameters.multilevel.Mres_auto(:)]);

parameters.multilevel.l = 'max'; % number of multilevel subspaces for MLS method (set to max if unsure)
parameters.multilevel.nested = 1; % if 0 then non nested, if 1 nesting is 0-l, if 2 nesting is l-max(l), 

parameters.multilevel.chooseTrunc = false; %manual vs algorithmic MA and Mres selection (still in beta). 
parameters.multilevel.concentration = 0.95; %algorithmic parameter selection parameter

%% Baseline performance parameters
parameters.misc.MachineList = ["SVM_Linear-PCA", "SVM_Radial-PCA", "SVM_Linear", "SVM_Radial", "LogitBoost", "RUSBoost", "Bag"]; %Benchmark learners
%["SVM_Linear-PCA", 
parameters.misc.PCA = [];

%% Ablation List
parameters.Ablation.List = ["2nd degree polynomial kernel",... Use polynomial kernel of order 2
                            "Kernel scaling",... Set Kernel Scaling to 1
                            "L1 quadratic programming solver",...Use L1 Quadrating Programming Solver as the optimization routine
                            ..."10-fold cross validation",...
                            ..."5-fold cross validation",...set Number of folds to 5
                            "Box constraint = 10",...
                            "Standardized",... set to true
                            "Delta gradient tolerance = $10^{-2}$"]; ... Stop convergence early


%% Assorted parameters
parameters.parallel.on = false; %true = use parallel toolbox
parameters.svm.kernal = true; % true = use RBF for SVM separating surface (FINDER only)
parameters.gpuarray.on = false; % true = convert all data arrays to GPU arrays. 
parameters.snapshots.controlRand = false;

%% Transform Parameters (can mostly ignore)
parameters.transform.ComputeTransform = false;
parameters.transform.createPlots = false; 
% parameters.transform.RankTol = 10^-6;
% parameters.transform.alpha = 0.05;
% parameters.transform.beta = 0.05;
% parameters.transform.optimoptions = {'fmincon',...
%                                     ...'DerivativeCheck', 'on',...
%                                     ...'Algorithm', 'active-set',...
%                                     'Display', 'none',...
%                                     'MaxFunctionEvaluations', 10^5,...
%                                     'EnableFeasibilityMode', true,...
%                                     ...'HessianApproximation', 'lbfgs',...
%                                     'SpecifyObjectiveGradient', true, ...
%                                     'SpecifyConstraintGradient', true,...
%                                     'UseParallel', true,...
%                                     'StepTolerance', 10^(-10),...
%                                     'FunctionTolerance', 10^(-6),...
%                                     'MaxIterations', 500};
% parameters.transform.useHessian = true;
% parameters.transform.dimTransformedSpace = 60; %Initialize to empty to default to min(Ntrainingsamples, NFeatures);








if strcmp(parameters.data.validationType, 'Synthetic')
    parameters.data.nk = size(parameters.synthetic.Brs, 2); % num of simulations 
    assert(length(parameters.synthetic.Brs) == length(parameters.synthetic.Ars),...
        'parameters.snapshots.Ars and parameters.snapshots.Brs must have the same number of elements')
else 
    parameters.data.nk = 1;
end


if parameters.parallel.on == 1
    %Initialize Parallel
    parameters.parallel.numofproc = maxNumCompThreads;
    parpool(parameters.parallel.numofproc);
    %parpool(12);
end







end
