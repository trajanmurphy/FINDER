function [Datas, parameters] = corruptData(Datas, parameters, methods)

if ~strcmp(parameters.data.validationType, 'Synthetic'), return, end

omega = parameters.synthetic.functionTransform;
sigma = parameters.synthetic.GaussianNoiseFactor;

logicGate = xor(isempty(omega) , isempty(sigma));

assert(logicGate, ...
    ['Exactly one of parameters.synthetic.functionTransform ' ...
    'and parameters.synthetic.GaussianNoiseFactor can be nonempty']);

%% Compute Sine Transform 
if ~isempty(omega)
    if isnumeric(omega)
        transformHandle = @(x) sin(omega*x);
        for CData = ["AData", "BData"]
            Datas.rawdata.(CData) = transformHandle(Datas.rawdata.(CData));
        end
    end

end


%% Add Gaussian Noise
if ~isempty(sigma)
    if isnumeric(sigma)
        D = Datas.rawdata.AData;
        %D = (D - mean(D,2)) * (size(D,2) - 1)^(-0.5);
        %[~,scaleFactor,~] =  svds(D,1,'largest');
        scaleFactor = sqrt(sum( var(D,[],2) ));
        scaleFactor = sigma*scaleFactor;
    for CData = ["AData", "BData"]       
        noise = scaleFactor * randn(size(Datas.rawdata.(CData)));
        Datas.rawdata.(CData) = Datas.rawdata.(CData) + noise;
    end
    end

end


 end