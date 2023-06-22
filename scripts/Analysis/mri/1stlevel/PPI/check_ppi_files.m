options = get_options();
subj = options.subj.all_subs;

volume = 'brain';
analysis_version = ['13Apr23-' volume];
modelNo = 5;
[model,options] = get_model(options,modelNo);

roi2test = 3;

for sub = subj
   
    name = sprintf('sub%03d',sub);
    disp(name);
    
    %ppipath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    %ppifile = fullfile(ppipath, 'brain_ppi_roi_VOIs.mat');
    ppipath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'PPI');
    ppifile = fullfile(ppipath, [name '-' volume '_ppi_roi_VOIs.mat']);
    
    if exist(ppifile,'file')
        load(ppifile)
        tc_nans = sum(isnan(data.xY(roi2test).mean));
        warning(['Found ' num2str(tc_nans) ' NaNs in the timecourse'])
    else
        warning('PPI file not found!')
    end
    
end