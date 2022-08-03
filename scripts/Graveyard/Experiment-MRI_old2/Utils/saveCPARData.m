function saveCPARData(trialData,cparFile,block,trial)
% Save CPAR data

try
   
    if exist(cparFile,'file')
        loadedData = load(cparFile);
        cparData = loadedData.cparData;
    end
    
    cparData(block).data(trial) = trialData;
    
    if ~isempty(cparData) && ~isempty(trialData)
        save(cparFile,'cparData');
    end
    
catch
    fprintf(['Saving trial ' num2str(trial) ' data failed.\n']);
end

end