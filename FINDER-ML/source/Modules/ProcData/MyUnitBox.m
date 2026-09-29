function Datas = MyUnitBox(Datas)

for C = ["A", "B"], for Set = ["CovTraining", "Machine", "Testing"]
X = Datas.(C).(Set);
X = X - min(X,[],1); 
X = X ./ max(X,[],1);
Datas.(C).(Set) = X;
end, end



end