function CreateTruncationStruct
methods = DefineMethods;

Balance = [true;false];
Kernel = [true;false];
[Balance, Kernel] = meshgrid(Balance, Kernel);
Balance = Balance(:); Kernel = Kernel(:);
T = table(Balance, Kernel);

BlankColumn = cell(height(T),1);
ColumnNames = ["Accuracy", "Truncation", "Threshold", "Dimension", "Fold", "Time"];
for CN = ColumnNames
    T.(CN) = BlankColumn;
end

TruncStruct = cell(1,2*length(methods.data.all_files));
TruncStruct(1:2:end) = methods.data.all_files;
TruncStruct(2:2:end) = {T};
TruncStruct = struct(TruncStruct{:});
f = fileparts(which('MLS_FCT_FCD_CV.txt'));

answer = questdlg("Are you sure you want to reset the TruncStruct.mat file?",...
                   "",...
                   "Yes", "No", "No");

switch answer
    case "Yes"
        structName = fullfile(f, "TruncStruct.mat");
        save(structName,"TruncStruct");
    case "No"
        return
end

        




end