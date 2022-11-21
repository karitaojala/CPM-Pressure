options = get_options();

subj = options.subj.all_subs;

analysis_version = '09Nov22';
modelname = 'Fourier_phasic_tonic';

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    
    clear SPM
    load(fullfile(firstlvlpath,'SPM.mat'))
    
    figure;
    all = SPM.xX.X*SPM.xCon(1).c;
    exp = SPM.xX.X*SPM.xCon(3).c;
    con = SPM.xX.X*SPM.xCon(16).c;
    plot([all exp con])
    title(name)
    
end