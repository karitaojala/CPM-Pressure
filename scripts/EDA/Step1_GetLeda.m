function Step1_GetLeda(varargin)
% Expects mat files with data struct which are (yet) unprocessed by Ledalab
%
% IMPORTANTLY, creates copy of these files in outdir, so the original files in baseDir 
% remain untouched.
%
% From the copies, we hand data and processing parameters (defaults) to Ledalab,
% which then
% a) expands the data file with a struct "analysis" containing core
%    parameters over all conditions, at actual temporal resolution
% b) outputs a file _era, containing the params-by-conditions
% c) outputs a file _scrlist, containing a list of all registered SCRs

    if nargin==3
        allSubs = varargin{1};
        baseDir = varargin{2};
        outDir  = varargin{3};
    elseif nargin==2        
        allSubs = varargin{1};
        baseDir = varargin{2};
        outDir  = fullfile(cd,'..','..','..','data','eda','leda');
    elseif nargin==1
        allSubs = varargin{1};
        baseDir = fullfile(cd,'..','..','..','data','eda','triggerdetails');
        outDir  = fullfile(cd,'..','..','..','data','eda','leda');
    elseif nargin==0   
        allSubs = [3 5:8];
        baseDir = fullfile(cd,'..','..','..','data','eda','triggerdetails');
        outDir  = fullfile(cd,'..','..','..','data','eda','leda');
    end             
    addpath('C:\Data\Toolboxes\Ledalab\ledalab-349');
    
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
        
    stimulusDuration = 65;
    
    % CAREFUL, EXPORT_SCRLIST OVERWRITES EXPORT_ERA SETTINGS RE MINIMUM! (leda2.set.export.SCRmin @leda_batchanalysis.m)
%     ledalab_defaults      = {'open', 'mat','downsample', 5,'smooth',{'gauss' '100'}, 'analyze','CDA', 'optimize',10, 'overview',  1, 'export_era', [-1 7 0 1], 'export_scrlist', [0 1], 'export_eta', 1 }; % feargen; original srate 500
    %ledalab_defaults      = {'open','mat','downsample', 10, 'smooth',{'gauss',20}, 'analyze','CDA', 'optimize',6, 'overview',  1, 'export_era', [0 9.5 0.01 1], 'export_scrlist', [0 1]}; % exploratory defaults used for WavePain
    ledalab_defaults      = {'open','mat','downsample', 10, 'smooth',{'gauss',20}, 'analyze','CDA', 'optimize',6, 'overview',  1, 'export_era', [0 stimulusDuration 0.01 1], 'export_scrlist', [0.01 1]}; % exploratory defaults used for WavePain
    
    for sN = 1:numel(allSubs)       
        fileName = sprintf('sub%03d.mat',allSubs(sN));
        if ~exist([baseDir filesep fileName],'file')
            continue;
        end
        targetFile = sprintf('%s%s%s',outDir,filesep,fileName);
        copyfile([baseDir filesep fileName],targetFile);
    end
    
    ledaDir = fullfile(outDir,'leda');
    
    Ledalab(outDir,ledalab_defaults{:})                
