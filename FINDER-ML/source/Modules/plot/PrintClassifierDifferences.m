function PrintClassifierDifferences

%% Define Parameters

%General parameters
p.DSIdx = 7;
p.Classifiers = ["MLS Unbalanced Radial", "SVM_Linear"];
p.Normalized = "MyUnitVariance2";
p.Trunc = 8;
p.Mres = [NaN,NaN];
p.HS = "Manual_Hyperparameter_Selection";
p.CrossVal = "Kfold";
p.Accs = ["errorRate", "accuracy", "recall", "specificity", "precision"];
p.NTD = 2; %number of trailing digits

%Kfold Parameters
p.HoldOut = 5;

%Synthetic Parameters
p.TrainA = 600;
p.TrainB = 200;
p.Test = [];
p.Noise = 0;

p = DefineDatasets(p);
p = GetFiles(p);
p = GetDifferences(p);

end

%% ========================================================================

function p = DefineDatasets(p)
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");

p.GetFinder = @(str) extract(str, ("MLS"| "ACA-S"| "ACA-L"));
p.GetKernel = @(str) extract(str, ("Linear"|"Radial"));
p.GetBalance = @(str) extract(str, ("Balanced"|"Unbalanced"));

p.DataString = DataSets(p.DSIdx);
end

%% ========================================================================
function p = GetFiles(p)

p.X = cell(2,1);

for i = 1:2

    Balance = p.GetBalance(p.Classifiers(i));
    if isempty(Balance), Balance = "Unbalanced"; end
    Finder = p.GetFinder(p.Classifiers(i));
    Kernel = p.GetKernel(p.Classifiers(i));
    
    switch p.CrossVal
        case "Kfold"
            tag1 = sprintf("Leave_%d_out", p.HoldOut);
        case "Synthetic"
            tag1 = fullfile(...
                sprintf("%d_TrainingA_%d_TrainingB_%d_Testing", p.TrainA, p.TrainB, p.Test),...
                replace(sprintf("Noise_%g", p.Noise), ".", "_"));
    end
    Paths = dir(fullfile("..","results", p.HS, p.CrossVal, p.DataString, tag1, Balance, "*.mat"));
    Paths = fullfile({Paths.folder}, {Paths.name});

    idx = contains(Paths, p.Normalized);
    if isempty(Finder)
        idx = idx & ...
            contains(Paths, "Benchmark");
    else
        idx = idx & ...
            contains(Paths, Finder) &...
            contains(Paths, Kernel) &...
            contains(Paths, "Eigen-"+p.Trunc);
    end

    if sum(idx) ~= 1, keyboard, end

    p.X{i} = load(Paths{idx});

  %  keyboard
end

[A,B] = meshgrid(p.X{1}.parameters.data.NAvals, p.X{1}.parameters.data.NBvals);
p.pairs = [A(:), B(:)];
p.WilcoxonArray = nan(size(p.pairs,1), length(p.Accs),2);


end

%% ========================================================================
function p = GetDifferences(p)

for i = 1:2

    if ~isempty(p.GetFinder(p.Classifiers(i)))
        if isnan(p.Mres(i))
            [~,iLevel(i)] = min(p.X{i}.results.errorRate);
        else
            iLevel(i) = p.Mres(i);
        end
        p.Classifiers(i) = p.Classifiers(i) + sprintf(" [Mres = %d]", p.X{i}.parameters.multilevel.Mres(iLevel(i))); 
    else
        iLevel(i) = find(p.X{i}.parameters.misc.MachineList == p.Classifiers(i));
    end


for ipair = 1:size(p.pairs,1)
    pair = p.pairs(ipair,:);
    results.array = p.X{i}.results.array(pair(1), pair(2), iLevel(i),:,:);
    results = ComputeResultsAccuracy(results);
    p.WilcoxonArray(ipair,:,i) = arrayfun( @(A) results.(A), p.Accs);
end

    
end

for iAcc = 1:length(p.Accs)
end

vsString = strjoin(p.Classifiers, " vs " );
eqString = string(repmat('=', 1, 100));
colString = ["", "Class 1" "Class 2" "Abs Diff" "Rel Diff" "Eff Size" "p value"];
fspecs = repmat("%0." + p.NTD + "f", 1, length(colString)-1); 
fspecs(end) = replace(fspecs(end), "f", "e");


lines = string(nan(length(p.Accs), length(colString)));
for iAcc = 1:length(p.Accs)
    Acc = p.Accs(iAcc);
    x = p.WilcoxonArray(:,iAcc,2);
    y = p.WilcoxonArray(:,iAcc,1);
    [pval, ~, stats] = signrank(x,y,tail = "both", method = "approximate");
    ES = stats.zval / sqrt(length(x));
    a = arrayfun(@(i) p.X{i}.results.(Acc)(iLevel(i)), [1,2]);
    absDiff = a(2) - a(1); 
    relDiff = absDiff / a(1);
    lines(iAcc,:) = [Acc, compose(fspecs, [100*a, 100*absDiff, 100*relDiff, ES, pval])];
    lines(iAcc,2:end-2) = lines(iAcc,2:end-2) + "%";
end

msl = max(strlength([colString;lines]),[],1);
colString = pad(colString, msl, "both");
colString = sprintf(" %s |", colString);
lines = pad(lines, msl, "both");

fprintf("%s\n",[eqString, p.DataString, vsString, eqString, colString, eqString]);
for i = 1:size(lines,1)
    line = lines(i,:);
    fprintf(" %s |", line);
    fprintf("\n");
end

end
