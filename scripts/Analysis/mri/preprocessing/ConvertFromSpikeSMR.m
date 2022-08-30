% requires CED MATLAB from http://ced.co.uk/upgrades/spike2matson

function ConvertFromSpikeSMR

    baseDir = 'C:\Users\horing\Documents\projects\P7_EquiNox\physio';
    logDir = 'C:\Users\horing\Documents\projects\P7_EquiNox\logs'; 
    
    NChannels = 7; %could use [ iMaxChans ] = CEDS64MaxChan( fhand ); buit there's something weird in channel 31...
    
    DoConversion(baseDir,NChannels); % expects all smr files to be in baseDir; will distribute to subfolders later
    DistributeFiles(baseDir,logDir);
    
    
function DoConversion(baseDir,NChannels)

    cedpath = 'C:\Program Files\CEDMATLAB\CEDS64ML';
    addpath( cedpath );
    CEDS64LoadLib( cedpath );
    
    fileList = ls(baseDir);
    
    for fN = 1:size(fileList,1)

        fileName = strtrim(fileList(fN,:));
        if isempty(regexp(fileName,'.*\.smr','MATCH'))
        %if isempty(regexp(fileName,'sub015_c\.smr','MATCH'))
            continue;
        end
        outName = cell2mat(regexp(fileName,'.*(?=\.smr)','MATCH'));
        outFile = sprintf('%s%s%s.mat',baseDir,filesep,outName);    

        if exist(outFile,'file')
            fprintf('File %s already exists, skipping...\n',outFile);
            continue;
        end

        fhand=CEDS64Open(sprintf('%s%s%s',baseDir,filesep,fileName),1);            
        [ dTBaseOut ] = CEDS64TimeBase( fhand ); % this is the time base, that is, the highest resolution time over all channels, on which i64Div is applied in each to get actual resolution
            
        fprintf('Processing file %s\n',fileName);

        m = matfile(outFile,'writable',true); % instantiate file    

        for iChan = 1:NChannels
            [ iType ] = CEDS64ChanType( fhand, iChan ); % find out if the channel is a wave channel
            
            if ~iType
                continue;
            end
            
%             if iChan==5
%                 1
%             end
            fprintf('\tchannel %d ',iChan);

            tempStruct = struct;

            [ iOk, sTitleOut ] = CEDS64ChanTitle( fhand, iChan );
            [ iOk, sCommentOut ] = CEDS64ChanComment( fhand, iChan);
            
            i64MaxTime = CEDS64ChanMaxTime( fhand, iChan ); 
            if i64MaxTime==-1
                warning('Channel %d of %s is empty, skipping...',iChan,outName)
                continue;
            end
            
            [ i64Div ] = CEDS64ChanDiv( fhand, iChan );                
                
            tempStruct.title = sTitleOut;
            tempStruct.comment = sCommentOut;
            
            fprintf('(%s)... ',sTitleOut);
            
            [ i64MaxTime ] = CEDS64ChanMaxTime( fhand, iChan );
            
            if iType==1 % data channel
            
                [ fRead, fVals, fTime ] = CEDS64ReadWaveF( fhand, 1, ceil(i64MaxTime/i64Div), 0, i64MaxTime );                
                
                [ iOk, dOffsetOut ] = CEDS64ChanOffset( fhand, iChan );              
                [ iOk, sUnitsOut ] = CEDS64ChanUnits( fhand, iChan );
                [ iRead, fVals, i64Time ] = CEDS64ReadWaveF( fhand, iChan, ceil(i64MaxTime/i64Div), 0 );
                fVals = double(fVals);
                
                tempStruct.interval = dTBaseOut*i64Div; % ms resolution
                tempStruct.scale = 0; % unclear
                tempStruct.offset = dOffsetOut;
                tempStruct.units = sUnitsOut;                  
                tempStruct.start = i64Time;
                tempStruct.length = numel(fVals);
                tempStruct.values = fVals;

            elseif iType==3

                [ iRead, i64Times ] = CEDS64ReadEvents( fhand, iChan, ceil(i64MaxTime/i64Div), 0);   
                if isempty(i64Times)
                    warning('Channel %d of %s is empty, skipping...',iChan,outName)
                    continue;
                end
                [ dSeconds ] = CEDS64TicksToSecs( fhand, i64Times );
                
                tempStruct.resolution = dTBaseOut;
                tempStruct.length = numel(dSeconds);
                tempStruct.times = dSeconds;

            end

            %eval(sprintf('sub%03d_Ch%d = tempStruct;',sbId,iChan));        

            %m.(sprintf('sub%03d_Ch%d',sbId,iChan)) = tempStruct;
            m.(sprintf('%s_Ch%d',outName,iChan)) = tempStruct;
            fprintf('done\n');

        end

        CEDS64Close(fhand);

    end

    unloadlibrary ceds64int;
    
    
function DistributeFiles(baseDir,logDir)

    fileList = ls(baseDir);
    fileList = cellstr(fileList);
    
    for fN = 1:size(fileList,1)

        if isempty(regexp(fileList{fN},'sub\d{3}.*?\.mat','MATCH'))
            continue;
        end    

        sbId = str2double(cell2mat(regexp(fileList{fN},'(?<=sub)\d{3}','MATCH')));
        sessionTag = str2double(cell2mat(regexp(fileList{fN},'(?<=sub\d{3}\_)\d(?=\.mat)','MATCH')));
        if ~isempty(sessionTag)
            sessionTag = sprintf('_session%d',sessionTag);
        else
            sessionTag = cell2mat(regexp(fileList{fN},'(?<=sub\d{3}\_).*?(?=\.mat)','MATCH'));
        end
        
        %tarDir = sprintf('%s%ssub%03d%sphysio%s',logDir,filesep,sbId,filesep); % USE THIS IF YOU WANT IT IN LOG DIRECTORY
        tarDir = sprintf('%s%ssub%03d%s',baseDir,filesep,sbId); % USE THIS IF YOU WANT IT IN LOG DIRECTORY
        if ~exist(tarDir,'dir')
            mkdir(tarDir);
        end
        
        fileDest = sprintf('%s%ssub%03d%s.mat',tarDir,filesep,sbId,sessionTag);   
        fprintf('Processing %s...\n',fileList{fN});
        
        if exist(fileDest,'file')
            fprintf('\tDeleting existing destination file %s...\n',fileDest);
            delete(fileDest);
        end
        fprintf('\tWriting destination file %s... ',fileDest);
        copyfile(sprintf('%s%s%s',baseDir,filesep,fileList{fN}),fileDest)
        fprintf('done.\n');
        
    end

