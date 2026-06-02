function [results] = PrintResultsTxt(Datas, parameters, methods, results)

switch parameters.multilevel.chooseTrunc
    case false
        MOE = "Manual_Hyperparameter_Selection";
    case true
        MOE = func2str(methods.Multi2.ChooseTruncations);
end

folder = fullfile("..", "results", MOE, parameters.data.validationType,"txt_files");
if ~isfolder(folder), mkdir(folder), end

name = func2str(methods.Multi2.ConstructResidualSubspace) + ".txt";

file = fullfile(folder, name);
fID = fopen(file, "a+");

if mod(parameters.data.irow, 4) == 1
    fprintf(fID, '\n%s\n', parameters.data.label);
end

fprintf(fID, 'Balanced: %d, Kernel: %d', parameters.multilevel.splitTraining, parameters.svm.kernal);
fprintf(fID, ' (AUC = %0.4f, acc = %0.4f, precA = %0.4f, precB = %0.4f)', ...
    results.AUC, results.accuracy, results.precisionA, results.precisionB);
fprintf(fID, ' Run Time: %s\n', results.run_time);
fclose(fID);


end