function [results] = CompMiscMachines(methods, Datas, parameters, results)

% array(:,:,1,:,:) = results.array(:,:,l+1,:,:);


    tic; t1 = toc;
    array = results.array;
    if parameters.parallel.on
        
        
        parfor i = parameters.data.NAvals
                parameters2 = parameters;
                parameters2.data.i = i;
                array(i,:,:,:,:,:) = runMachines(Datas, parameters2, methods, results);
        end

    elseif ~parameters.parallel.on
       
        for i = parameters.data.NAvals
            parameters.data.i = i;
            array(i,:,:,:,:) = runMachines(Datas, parameters, methods, results);
        end
    end

    t2 = toc; 
    fprintf('Elapsed Time: %0.3f s \n', 1000*(t2 - t1));

    results.array = array;
end





function A = runMachines(Datas, parameters, methods, results)

sz = size(results.array(1,:,:,:,:));
A = nan(sz);

s = 'svm'; if parameters.multilevel.svmonly  ~= 1, s = 'multilevel'; end
t1 = tic;
% if parameters.misc.PCA
%     parameters.misc.MachineList = ["SVM_Linear", "SVM_Radial"];
% end

for machine = parameters.misc.MachineList
    iMachine = parameters.misc.MachineList == machine;
    parameters.misc.PCA = contains(machine, "PCA");
    if parameters.misc.PCA
        machine = extractBefore(machine, "-PCA");
    end
    %fprintf('Computing %s \n', paraters.misc.machineList(iMachine));
    for j = parameters.data.NBvals
        parameters.data.j = j; 
        t2 = toc(t1);
        Datas2 = methods.all.prepdata(Datas, parameters);
        Datas3 = methods.transform.tree(Datas2, parameters, methods);
        [Datas4, parameters4] = methods.misc.PCA(Datas3, parameters, methods);
        %Datas = methods.Multi2.SplitTraining(Datas, parameters);
        Datas5 = methods.misc.prep(Datas4, parameters4);       
        %Datas.Model = 
        parameters4.multilevel.SVMModel = methods.misc.(machine)(Datas5.X_Train, Datas5.y_Train);
        t3 = toc(t1);
        A(1,j,iMachine,:,:) = methods.misc.predict(Datas5, parameters4, methods);
        t4 = toc; 
        %fprintf('Prediction Time: %0.3f \n', 1000*(t3 - t2));
        %disp(squeeze(A(1,j,iMachine,:,:)))
    end
end

end










