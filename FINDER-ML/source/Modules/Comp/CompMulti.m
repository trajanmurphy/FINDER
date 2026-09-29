function [results] = CompMulti(methods, Datas, parameters, results)

for l = 0:parameters.multilevel.l 
if parameters.parallel.on == 1
results = methods.Multi.parallel(Datas, parameters, methods, results, l);
elseif parameters.parallel.on == 0
[results, Datas, parameters] = methods.Multi.noparallel(Datas, parameters, methods, results, l);
end    
end

end




