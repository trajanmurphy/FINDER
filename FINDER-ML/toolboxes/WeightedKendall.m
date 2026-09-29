function [p,Ww] = WeightedKendall(X,w)

% Please cite to the following study if you use this file:
% Mahmoudi, A., Abbasi, M., Yuan, J., & Li, L. (2022). Large-Scale Group Decision-Making (LSGDM) for Performance Measurement of Healthcare Construction Projects: Ordinal Priority Approach, Applied Intelligence. https://doi.org/10.1007/s10489-022-04094-y
% if you face any problem executing the code, please contact Amin Mahmoudi:pmp.mahmoudi@gmail.com
% Please read the help file before executing the app.
% This file supports any number of ties and the results are very accurate.
% This file does not support incomplete blocks.

% -------------input data-----------------
% X = the input matrix, columns show the raters and rows show the objects.
% w = the weight of the raters. If the weights of raters are distributed
% equally, the value of weighted Kendall's W is equal to Kendall's W. 
% The proofs and formula are available: Mahmoudi, A., Abbasi, M., Yuan, J., & Li, L. (2022). Large-Scale Group Decision-Making (LSGDM) for Performance Measurement of Healthcare Construction Projects: Ordinal Priority Approach, Applied Intelligence. https://doi.org/10.1007/s10489-022-04094-y  

narginchk(1,2);

if nargin < 1
X=[5	5	4	2
   1	2	2	5
   3	3	2	1
   4	4	5	4
   2	1	1	3];
elseif nargin < 2
%w=[0.520833 0.270833 0.145833 0.062500];
w = ones(1, size(X,2)) / size(X,2);
end

assert(size(X,2) == length(w), "number of weights must equal the number of judges");

% -------------outputs-----------------
% Ww = weighted Kendall's W
% Fdist= probability density function of fisher distribution
% CL= the confidence level index proposed by Mahmoudi et al. (2022)
% p= p-value
% ------------------------------
[n,k]=size(X);
[R,T]=tiedrank(X);
for j=1:k
  for i=1:n
  T (i,j)=numel(find(X(:,j)==i));
  end
end
TT=sum(T.^3-T);
TTT=sum(w.*TT);
wR=R.*w;
RS=sum(wR,2);
S=sum(RS.^2)-n*mean(RS).^2;
F=(n^3-n)-TTT;
Ww=12*S/F;
Fdist=Ww*(k-1)./(1-Ww);
nu1 = n-1-(2/k);
nu2 = nu1*(k-1);
%p=fpdf(Fdist,nu1,nu2);
CL=fcdf(Fdist,nu1,nu2);
p = 1 - CL;

if CL >= 0.99
   SignificanceLevel= 0.01;
elseif CL >= 0.95
   SignificanceLevel= 0.05;
elseif CL >= 0.90
   SignificanceLevel= 0.1;
elseif CL < 0.90
    SignificanceLevel= 'there is no agreement among raters';
end

end

