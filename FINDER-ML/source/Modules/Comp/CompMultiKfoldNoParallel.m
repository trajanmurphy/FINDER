
function [results, Datas, parameters] = CompMultiKfoldNoParallel(Datas, parameters, methods, results, l)



% array(:,:,1,:,:) = results.array(:,:,l+1,:,:);
sz = size(results.array(:,:,l+1,:,:));
sz(3) = 1;
array = nan(sz);


for i = parameters.data.NAvals

        parameters.data.i = i;
        %tic;
        %t1 = toc;
       
        for j = parameters.data.NBvals

            parameters.data.j = j;
            
           
            
            

           %% Split data into two groups: training and testing 
            [Datas2] = methods.all.prepdata(Datas, parameters);

            %% Compute Transformation K using all training data, apply to training and validation data
            
            Datas3 = methods.transform.tree(Datas2, parameters, methods);
            parameters2 = methods.Multi2.ChooseTruncations(Datas3, parameters, methods);
            

            %% Balance Data and construct multi-level filter
          
            tic; t1 = toc;
            [Datas4, parameters3] = methods.Multi.Filter(Datas3, parameters2, methods);
            

            
            %% Construct Machine
            [Datas5, parameters4] = methods.Multi.machine(Datas4, parameters3, methods,l);


            %% Predict class value using transformed data
            t2 = toc;
            results.DimRunTime(l+1) = t2 - t1;
            fprintf('Test %d， Time = %.2f ms \n', i, 1000*(t2 - t1));
             [array(i,j,1,:,:)] = methods.all.predict(Datas5, parameters4, methods);
   




           % t2 = toc; 
           
            
         
        end


end


results.array(:,:,l+1,:,:) = array(:,:,1,:,:);
