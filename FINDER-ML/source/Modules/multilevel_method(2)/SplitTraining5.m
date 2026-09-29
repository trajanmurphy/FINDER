function Datas = SplitTraining5(Datas, parameters, methods, results)

narginchk(2,4);

i = parameters.data.i;
j = parameters.data.j;


%% Compute inidces for training and testing data 
switch parameters.data.validationType
    case 'Kfold'
        ivector = 1:parameters.Kfold:parameters.data.A; 
        jvector = 1:parameters.Kfold:parameters.data.B; 
        
        istart = ivector(i); 
        jstart = jvector(j);
        
        %%
        switch i <= parameters.data.NAvals(end)
            case true, iend = istart + parameters.Kfold -1;
            case false, iend = parameters.data.A;
        end
        
        switch j <= parameters.data.NBvals(end)
            case true, jend = jstart + parameters.Kfold -1;
            case false, jend = parameters.data.B;
        end

        iTesting = istart:iend;
        jTesting = jstart:jend;

        
    case 'Cross'

        iTesting = 1:parameters.cross.NTestA;
        jTesting = 1:parameters.cross.NTestB;

    case 'Synthetic'
         iTesting = 1:parameters.synthetic.NTest;
         jTesting = iTesting;
       
end

if parameters.gpuarray.on 
    Datas.rawdata.AData = gpuArray(Datas.rawdata.AData);
    Datas.rawdata.BData = gpuArray(Datas.rawdata.BData);
end

TestingA = Datas.rawdata.AData(:,iTesting);
TestingB = Datas.rawdata.BData(:,jTesting);

TrainingA = Datas.rawdata.AData; 
TrainingB = Datas.rawdata.BData;
TrainingA(:,iTesting) = []; 
TrainingB(:,jTesting) = []; 

%% Further divide training data into eigen-training and machine-training
NTrainA = size(TrainingA,2);
iData = 1:NTrainA;
if parameters.multilevel.splitTraining
    nTesting = size(TrainingB,2);
    iCov = iData(iData > nTesting);
    iMachine = iData(iData <= nTesting);
else
    iCov = iData;
    iMachine = iData;
end

%% Assign Values
Datas.A.Testing = TestingA;
Datas.B.Testing = TestingB;
Datas.A.Training = TrainingA;
Datas.B.Training = TrainingB; 
Datas.A.CovTraining = Datas.A.Training(:,iCov);
Datas.A.Machine = Datas.A.Training(:,iMachine);
Datas.B.CovTraining = Datas.B.Training; 
Datas.B.Machine = Datas.B.Training;

%% Normalize
if parameters.data.normalize 
    Datas = methods.all.normalizedata(Datas);
end


%% Subtract class A mean
meanXA = mean(TrainingA(:,iCov), 2);
for C = ["A", "B"], for Set = ["CovTraining", "Testing", "Machine"]
        Datas.(C).(Set) = Datas.(C).(Set) - meanXA;
end, end


end