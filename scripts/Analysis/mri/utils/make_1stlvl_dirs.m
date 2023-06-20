options = get_options();
subj = options.subj.all_subs;

analysis_version = '13Apr23-spinal';
modelNo = 5;
[model,options] = get_model(options,modelNo);

for sub = subj
   
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    
    if ~exist(firstlvlpath,'dir')
        mkdir(firstlvlpath)
    end
    
end