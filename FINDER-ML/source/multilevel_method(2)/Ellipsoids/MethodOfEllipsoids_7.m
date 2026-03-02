function parameters = MethodOfEllipsoids_7(Datas, parameters, methods)%Finds the number of Class A points lying inside the 0.95-Ellipsoid


close all
if ~parameters.multilevel.chooseTrunc, return, end

%% Copy over Training Portion of Data and eliminate testing data
%for C = 'AB', D1.(C).rawdata = Datas.(C).Training; end
%for Set = ["CovTraining", "Machine", "Testing"], D1.B.(Set) = D1.B.rawdata; end

D1 = ReduceData(Datas);


% BestMA = []; BestMres = []; BestMisplaced = Inf;
% BestRelChangeMSD = Inf; 
% 
% CompMSD0 = @(X)  ((sum(X.^2,1) + sum(X'.^2,2)) - 2*X'*X );
% CompMSD = @(X) 1 / (size(X,2)^2 - size(X,2)) * sum(CompMSD0(X),'all');
% 
% %% Separate Testing Cohort from Class A and Class B Training
% switch parameters.data.validationType
%     case 'Synthetic' 
%         NATest = parameters.synthetic.NTest;
%         NBTest = parameters.synthetic.NTest;
%     case 'Cross'
%         NATest = parameters.cross.NTestA;
%         NBTest = parameters.cross.NTestB;
%     case 'Kfold'
%         NATest = parameters.Kfold;
%         NBTest = parameters.Kfold;
% end
% Testsize.A = NATest; Testsize.B = NBTest;

for C = 'AB'
% D1.(C).CovTraining = D1.(C).rawdata;
% %D.(C).CovTraining(:,Testsize.(C)) = [];
% D1.(C).CovTraining(:,end) = [];
% D1.(C).Machine = D1.(C).CovTraining;
NC = size(D1.(C).CovTraining,2);
% %D.(C).Testing = D.(C).rawdata(:,Testsize.(C));
% D1.(C).Testing = D1.(C).rawdata(:,end);
MC = mean(D1.(C).CovTraining,2);
X.(C) = (NC - 1)^(-0.5)*(D1.(C).CovTraining - MC);
[U.(C), S.(C), ~] = svd(X.(C), 'econ', 'vector');
end


%% Create List of Admissible Truncation Parameters
nzeros = max(0, size(U.A,1) - length(S.A));
normA2 = S.A(1)^2; 
S.A = padarray(S.A, nzeros, 0, 'post');
S.A = S.A.^2; 
S.A = 1 - S.A/normA2;
S.B = S.B.^2 / normA2;
XB = U.B;
%XB = U.B .* (S.B)';

SAB =  methods.Multi2.BinarySVD(X.A, XB);
%SAB = S.A .* SAB;

ABS = nan(size(SAB,2), 1);
for ima = 1:size(SAB,2)
    sab = SAB(1:end-ima+1,:);
    ABS(ima) = FMN(sab);
end

%if min(MA) > 37, keyboard, end

for ima = uTrunc

    parameters.snapshots.k1 = ima; %min(MA);
    D2 = methods.Multi2.ConstructResidualSubspace(D1, parameters, methods); %Construct Filter
    SB = cumsum(D2.B.CovTraining.^2,1) ./ sum(D2.B.CovTraining.^2,1); 
    EVB = mean(SB,2);
    %q = quantile(EVB,20);
    q = 0.05:0.05:1;
    Mres = arrayfun( @(x) find(EVB < x, 1, 'last'), q);

    for imres = 1:length(Mres)
        parameters.multilevel.iMres = Mres(imres);
        D3 = methods.Multi2.SepFilter(D2, parameters, methods); 

        MSDTrain = CompMSD(D3.A.Machine) + CompMSD(D3.B.Machine);
        MSDTest = CompMSD([D3.A.Machine, D3.A.Testing]) + ...
            CompMSD([D3.B.Machine, D3.B.Testing]);

        relMSDChange = abs(MSDTest - MSDTrain) / MSDTrain;

        if relMSDChange < BestRelChangeMSD
            BestMA = ima;
            BestMres = Mres(imres);
            BestRelChangeMSD = relMSDChange;
        end

    end
    
    
end

parameters.snapshots.k1 = BestMA;

if parameters.multilevel.splitTraining 
    parameters.snapshots.k1 = min(BestMA, size(Datas.A.CovTraining,2));
end

parameters.multilevel.Mres = BestMres;


   
%% Get List of Mres to try


%fprintf('MA = %d, Mres = %d \n', parameters.snapshots.k1, parameters.multilevel.Mres);
end

%======================

function r = FMN(X)
%Fast matrix norm, from experiments, this seems to be the quickest way to
%compute a matrix norm

[m, n] = size(X);
if m > n %tall matrix
    r = sqrt(norm(X'*X));
elseif m < n %wide matrix
    r = sqrt(norm(X*X'));
elseif m == n
    r = norm(X);
end


end

%====================================
function Datas = ReduceData(Datas)

X = [Datas.A.CovTraining , Datas.B.CovTraining ];
XC = X - mean(X,2);
[U,S,~] = svd(XC, 'econ', 'vector');
EV = cumsum(S.^2) / sum(S.^2);
npc = find(EV >= 0.95, 1, 'first');
PC = U(:, 1:npc);
for C = 'AB'
    Datas.(C).CovTraining = PC' * Datas.(C).CovTraining;
end

end

%=====================================
function KLD = GetKLDivergence(Datas)

K = size(Datas.A.CovTraining, 1);
for C = 'AB'
    N.(C) = size(Datas.(C).CovTraining, 2);
    M.(C) = mean(Datas.(C).CovTraining, 2);
    X.(C) = (N.(C) - 1)^(-0.5) * (Datas.(C).CovTraining - M.(C));
    [U.(C), S.(C), ~] = svd(X.(C), 'vector');
    S.(C) = S.(C).^2;
end
for C = 'AB'
    Y.(C) = U.B' * (S.B.* (X.(C) - M.B));
end

t1 = sum(Y.A .* Y.A, 1);
t2 = mean(Y.A, 2);
KLD = 0.5 * ( sum(t1 + t2 - 1 - ln(t1))) ;



% t1 = (X.A' * X.A) .* (X.B' * X.B);
% t1 = sum(t0, 'all');
% 
% t2 = U.B * ((1./S.B) .* U.B');
% t2 = (M.B - M.A)' * t2 * (M.B - M.A);
% 
% t3 = log(prod(S.B) / prod(S.A));
% 
% KLD = 0.5 * (t1 + t2 + t3) - K;


end








