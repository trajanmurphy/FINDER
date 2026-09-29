function [results] = CompMultiKfold2(Datas, parameters, methods, results, l)


sz = size(results.array(:,:,l+1,:,:));
sz(3) = 1;
array = nan(sz);

parfor i = parameters.data.NAvals
        parameters.data.i = i; 

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
            [Datas6, parameters6] = methods.Multi.machine(Datas5, parameters5, methods,l);

            %% Predict class value using transformed data
             [array(i,j,1,:,:), TruncArray(i,j,:)] = methods.all.predict(Datas6, parameters6, methods); %,...
         
        end

end
results.array(:,:,l+1,:,:) = array(:,:,1,:,:);



