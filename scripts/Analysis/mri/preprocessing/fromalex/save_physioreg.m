function save_physioreg

subs              = [4 5 7:10 12:20 22:24 28:33 35:43 45:48 51 52 54:62 65:68 70:72 74:88 90 91 93:99] ; 

nsess             = 8;
n_scans           = 157;
dummy             = 4;
TR                = 2.65;
basedir           = '..\..\..\..\data\CPM-Pressure-01\Experiment-01';
physiodir         = fullfile(basedir,'physio');

logdir = fullfile(basedir,'logs');

timestamp = datestr(now,'yyyy_mm_dd_HHMMSS');
copyfile(which(mfilename),[logdir filesep mfilename '_' timestamp '.m']);


for g = 1:size(subs,2)
    name = sprintf('Sub%02.2d',subs(g));     
    disp(name);
    
    for se = 1:nsess 
        rundir = fullfile(basedir,name,sprintf('Run%d',se),'brain');
        
        %no pulse signal in Sub38, Run1
        if (subs(g) == 38 && se == 1) 
            physio = [];
        else
            physio = get_physio(physiodir,name,se,n_scans,TR);
            physio = physio(dummy+1:n_scans,:);
        end       
        save(fullfile(rundir,sprintf('sub%02.0f_physio_run%d.mat',subs(g),se)),'physio');
    end
end