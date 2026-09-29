d = fileparts(pwd);
a = genpath(d);
path(path,a);

x = dir(pwd);
pattern = "." + ("e"|"o") + digitsPattern(7);
isML_Features = arrayfun(@(y) contains(y.name, pattern), x);
ML_FeatureFiles = x(isML_Features);
arrayfun(@(y) delete(y.name), ML_FeatureFiles);

p = pwd;
