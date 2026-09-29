function [results,Datas,parameters] = CompMultiKFold2(Datas, parameters, methods, results, l)


sz = size(results.array(:,:,l+1,:,:));
sz(3) = 1;

parameters.data.l = l+1;
array = nan(sz);
TruncArray = results.TruncArray;

switch parameters.parallel.on
    case true
        
        parfor i = parameters.data.NAvals
        parameters2 = parameters;
        parameters2.data.i = i;
        [arraySub, TruncArraySub] = CompMultiKfold2Sub(Datas, parameters2, methods,results);
        array(i,:,:,:,:) = arraySub;
        TruncArray(i,:,:) = TruncArraySub;
        end
    case false
        for i = parameters.data.NAvals
        parameters2 = parameters;
        parameters2.data.i = i;
        [arraySub, TruncArraySub] = CompMultiKfold2Sub(Datas, parameters2, methods,results);
        array(i,:,:,:,:) = arraySub;
        TruncArray(i,:,:) = TruncArraySub;
        end
end

results.array(:,:,l+1,:,:) = array;
results.TruncArray = TruncArray;
end

%%=========================================================================
%%=========================================================================

function [array, TruncArray] = CompMultiKfold2Sub(Datas, parameters, methods,results)

i = parameters.data.i;
l = parameters.data.l;
array = results.array(i,:,l,:,:);
TruncArray = results.TruncArray(i,:,:);

for j = parameters.data.NBvals
    

    parameters2 = parameters;
    Datas2 = Datas; 
    parameters2.data.j = j;

    %% Split data into two groups: training and testing 
    [Datas3] = methods.all.prepdata(Datas2, parameters2, methods);

    %% Compute Transformation K using all training data, apply to training and validation data
    Datas4 = methods.transform.tree(Datas3, parameters2, methods);
    parameters3 = methods.Multi2.ChooseTruncations(Datas4, parameters2, methods);

    %% Balance Data and construct multi-level filter

    [Datas5, parameters5] = methods.Multi.Filter(Datas4, parameters3, methods);

    %% Construct Machine
    [Datas6, parameters6] = methods.Multi.machine(Datas5, parameters5, methods,l-1);

    %% Predict class value using transformed data
    [array(:,j,:,:,:), TruncArray(:,j,:)] = methods.all.predict(Datas6, parameters6, methods); %,...

   %For diagnostic purposes only. Comment Out later
   % disp(squeeze(array(:,j,:,:,:)));
   % disp(squeeze(TruncArray(:,j,:)));

end

end



