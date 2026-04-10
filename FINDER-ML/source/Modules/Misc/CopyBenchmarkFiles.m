Datasets = [...
            "GCM",
            "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscan7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            ];

%myload = @(x) load(fullfile(x.folder, x.name));
thisdir = pwd;
methods = DefineMethods;
resultsFolders = ["Manual_Hyperparameter_Selection"];
CV = ["Synthetic"];
Balances = ["Balanced", "Unbalanced"];

transforms1 = arrayfun(@(x) replace( ...
    sprintf("Noise_%0.g", x),...
    '.', '_'), ...
     5*10.^[-5,-4,-3]);

transforms2 = arrayfun(@(x) sprintf("sin(%dx)",x) , [1,3,7,10:10:40] );
transforms = ["id", transforms1]; %, transforms2];

% homeFolder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
% newFolder = replace(homeFolder, 'Kfold', 'Synthetic');
% if ~isfolder(newFolder), mkdir(newFolder), end
% X0 = dir(fullfile(homeFolder, '*'));
% X1 = contains({X0.name}, ("Datasets"|"corruptions"));
% X0 = X0(X1);
% 
% for i = 1:length(X0)
%     old = fullfile(X0(i).folder, X0(i).name);
%     new = fullfile(newFolder, X0(i).name);
%     copyfile(old, new);
%     delete(old);
% end


% Corruptions by Data Set

folder = fullfile('..', 'results', resultsFolders, CV, 'Graphs');
for DS = Datasets(:)'
    %fprintf('Processing %s \n', DS);
    name = DS + "_corruptions.tex";
    fID = fopen(fullfile(folder, name), 'w+');
    fprintf(fID, ['\\begin{figure}[H]\n' ...
        '\\centering\n\n']);


    for transform = transforms
        caption = replace(transform, '_', '.');
        caption = replace(caption, 'Noise.', 'Noise: ');
        disp(caption)
        plotName = sprintf('%s_%s_Synthetic.pdf', DS, transform);
        fprintf(fID, ['\\begin{subfigure}[b]\n' ...
            '{0.225\\textwidth}\n' ...
            '\\includegraphics[height=0.12\\textheight]\n' ...
            '{%s}\n' ...
            '\\caption*{%s}\n' ...
            '\\end{subfigure}\n%%\n'], ...
            plotName, caption);

    end

    fprintf(fID, '\\end{figure}');

    %fprintf(fID, '\\input{%s_corruption}\n\\hrule\n', DS);
end

%% Data Sets by Corruption

for transform = transforms
    %fprintf('Processing %s \n', DS);
    name = transform + "_Datasets.tex";
    fID = fopen(fullfile(folder, name), 'w+');
    fprintf(fID, ['\\begin{figure}[H]\n' ...
        '\\centering\n\n']);

    caption = replace(transform, '_', '.');
    caption = replace(caption, 'Noise.', 'Noise: ');
    disp(caption)
    for DS = Datasets(:)'
        plotName = sprintf('%s_%s_Synthetic.pdf', DS, transform);
        fprintf(fID, ['\\begin{subfigure}[b]\n' ...
            '{0.225\\textwidth}\n' ...
            '\\includegraphics[height=0.12\\textheight]\n' ...
            '{%s}\n' ...
            '\\end{subfigure}\n%%\n'], ...
            plotName);

    end
    fprintf(fID, '\n\\caption*{%s}\n', caption);
    fprintf(fID, '\\end{figure}');

    %fprintf(fID, '\\input{%s_Datasets}\n\\hrule\n', transform);
end


