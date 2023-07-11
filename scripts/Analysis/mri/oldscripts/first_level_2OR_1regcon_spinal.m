function [problems] = first_level_2OR_1regcon_spinal

subs              = [4 5 7:10 12:20 22:24 28:33 35:43 45:48 51 52 54:62 65:68 70:72 74:88 90 91 93:99];%

exclude = [30];

if ~isempty(exclude)
    subs = subs(~ismember(subs,exclude));
end

num_sess          = 8;
n_scans           = 153;
basedir           = '/projects/crunchie/remi3/';
logdir            = fullfile(basedir,'logs');

analysis = 'first_level_hrf_2OR_1regcon_nophysio';

problems = {};

load('/home/tinnermann/remi3/Paradigma_MRT/rand_seq_all.mat');

timestamp = datestr(now,'yyyy_mm_dd_HHMMSS');
copyfile(which(mfilename),[logdir filesep analysis '_' timestamp '.m']);
logfile = [analysis '_log.txt'];
diary(logfile)
diary on

for g = 1:size(subs,2)
    name = sprintf('Sub%02.2d',subs(g));
    subdir = fullfile(basedir,name);
    dirout  = fullfile(subdir,'results_spinal',analysis);
    if exist(dirout,'dir')
        rmdir(dirout,'s');
    end
    mkdir(dirout);
    matlabbatch = cell(1,3);
    all_nuis = cell(1,num_sess);
    z = cell(1,num_sess);
    go = 1;
    co = 0;
    disp(name);
    
    matlabbatch{go}.spm.stats.fmri_spec.timing.units   = 'scans';
    matlabbatch{go}.spm.stats.fmri_spec.timing.RT      = 2.65;
    matlabbatch{go}.spm.stats.fmri_spec.timing.fmri_t  = 16;
    matlabbatch{go}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    
    matlabbatch{go}.spm.stats.fmri_spec.fact             = struct('name', {}, 'levels', {});
    matlabbatch{go}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{go}.spm.stats.fmri_spec.volt             = 1;
    matlabbatch{go}.spm.stats.fmri_spec.global           = 'None';
    matlabbatch{go}.spm.stats.fmri_spec.cvi              = 'none'; % none
    
    for se = 1:num_sess
        rundir = fullfile(subdir,sprintf('Run%d',se));

        % select scans
        scans = cellstr(spm_select('ExtFPList',fullfile(rundir,'sct'), '^fmri_moco_norm.nii',1:n_scans));
        matlabbatch{go}.spm.stats.fmri_spec.sess(se).scans = scans;
        
        % select multicond files
        cond   = fullfile(basedir,'multicond',sprintf('Sub%02.0f_multicond_2OR_1regcon_run%d.mat', subs(g),se));
        matlabbatch{go}.spm.stats.fmri_spec.sess(se).cond  = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
        matlabbatch{go}.spm.stats.fmri_spec.sess(se).multi = {cond};
        
        % select movement regressors
        fm       = spm_select('FPList',fullfile(rundir,'realign_sess'), '^rp_f.*.txt$');
        movement = load(fm);
        
        % select physio regressors
        load(fullfile(rundir,'brain',sprintf('Sub%02.0f_physio_run%d.mat',subs(g),se)));
        
        % select csf regressor
        load(fullfile(rundir,'sct',sprintf('Sub%02.0f_csf_reg_spinal_run%d.mat',subs(g),se)));
        
        % exclude bad volumes
        try
            noise = load(fullfile(rundir,'realign_sess',sprintf('Sub%02.0f_nui_reg_spinal_run%d.mat',subs(g),se)));
            badvols = noise.nui;
        catch
            badvols = [];
        end
         
        all_nuis{se} = [movement csf_reg badvols]; %
        n_nuis   = size(all_nuis{se},2);
        z{se}    = zeros(1,n_nuis);
        
        for nuis = 1:size(all_nuis{se},2)
            matlabbatch{go}.spm.stats.fmri_spec.sess(se).regress(nuis) = struct('name', cellstr(num2str(nuis)), 'val', all_nuis{se}(:,nuis));
        end
        matlabbatch{go}.spm.stats.fmri_spec.sess(se).multi_reg  = {''};
        matlabbatch{go}.spm.stats.fmri_spec.sess(se).hpf        = 128;
        
        clear scans badvols cond physio n_nuis movement noise
        
        block = rand_seq_all(se,subs(g));
        
        if block == 2 || block == 4
            %             {'Cue','Con','Var1','Var2','Rating1','Rating2','Rating3','BreathRem','Cue_R','Online_Rcon','Online_Roff'}
            %             = 11
            %cue
            a{se}         = [1 0 0 0 0 0 0 0 0 0 0];
            e{se}         = [-1 0 0 0 0 0 0 0 0 0 0];
            b{se}         = [0 1 1 1 0 0 0 0 0 0 0];
            c{se}         = [0 -1 -1 -1 0 0 0 0 0 0 0];
            d{se}         = [0 0 0 0 0 0 0 0 0 0 0];
            %constant contrasts
            a1{se}        = [0 1 0 0 0 0 0 0 0 0 0]; 
            a5{se}        = [0 -1 0 0 0 0 0 0 0 0 0];
            %offset contrasts
            b1{se}        = [0 0 1 1 0 0 0 0 0 0 0];
            b2{se}        = [0 0 1 0 0 0 0 0 0 0 0];
            b3{se}        = [0 0 0 1 0 0 0 0 0 0 0];
            b4{se}        = [0 0 -1 -1 0 0 0 0 0 0 0];
            b5{se}        = [0 0 -1 0 0 0 0 0 0 0 0];
            b6{se}        = [0 0 0 -1 0 0 0 0 0 0 0];
            b7{se}        = [0 0 1 -1 0 0 0 0 0 0 0];
            b8{se}        = [0 0 -1 1 0 0 0 0 0 0 0];
        else
            %             {'Cue','Con','Var1','Var2','Rating1','Rating2','Rating3','BreathRem'}
            %             = 8
            %cue
            a{se}         = [1 0 0 0 0 0 0 0];
            e{se}         = [-1 0 0 0 0 0 0 0];
            b{se}         = [0 1 1 1 0 0 0 0];
            c{se}         = [0 -1 -1 -1 0 0 0 0];
            d{se}         = [0 0 0 0 0 0 0 0];
            %constant contrasts
            a1{se}        = [0 1 0 0 0 0 0 0]; 
            a5{se}        = [0 -1 0 0 0 0 0 0];
            %offset contrasts
            b1{se}        = [0 0 1 1 0 0 0 0];
            b2{se}        = [0 0 1 0 0 0 0 0];
            b3{se}        = [0 0 0 1 0 0 0 0];
            b4{se}        = [0 0 -1 -1 0 0 0 0];
            b5{se}        = [0 0 -1 0 0 0 0 0];
            b6{se}        = [0 0 0 -1 0 0 0 0];
            b7{se}        = [0 0 1 -1 0 0 0 0];
            b8{se}        = [0 0 -1 1 0 0 0 0];
        end
    end
    
    copyfile(which(mfilename),dirout);
    matlabbatch{go}.spm.stats.fmri_spec.dir = {dirout};
    
    mask = spm_select('FPList',fullfile(basedir,'PAM50'),'PAM50_cord_crop_1vm.nii'); 
    if isempty(mask); warning('No mask found');end
    matlabbatch{go}.spm.stats.fmri_spec.mask = {mask};
    matlabbatch{go}.spm.stats.fmri_spec.mthresh = -Inf;
    
    go = go + 1;
    matlabbatch{go}.spm.stats.fmri_est.spmmat           = {[dirout filesep 'SPM.mat']};
    matlabbatch{go}.spm.stats.fmri_est.method.Classical = 1;
    
    go = go + 1;
    matlabbatch{go}.spm.stats.con.spmmat = {[dirout filesep 'SPM.mat']};
    
    
  %----- 1 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Cue_base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [a{1} z{1} a{2} z{2} a{3} z{3} a{4} z{4} d{5} z{5} d{6} z{6} d{7} z{7} d{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 2 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Cue_infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [d{1} z{1} d{2} z{2} d{3} z{3} d{4} z{4} a{5} z{5} a{6} z{6} a{7} z{7} a{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 3 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Cue_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [a{1} z{1} a{2} z{2} a{3} z{3} a{4} z{4} e{5} z{5} e{6} z{6} e{7} z{7} e{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 4 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Cue_infs>base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [e{1} z{1} e{2} z{2} e{3} z{3} e{4} z{4} a{5} z{5} a{6} z{6} a{7} z{7} a{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 5 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Pain';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b{1} z{1} b{2} z{2} b{3} z{3} b{4} z{4} b{5} z{5} b{6} z{6} b{7} z{7} b{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 6 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Pain_base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b{1} z{1} b{2} z{2} b{3} z{3} b{4} z{4} d{5} z{5} d{6} z{6} d{7} z{7} d{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 7 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Pain_infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [d{1} z{1} d{2} z{2} d{3} z{3} d{4} z{4} b{5} z{5} b{6} z{6} b{7} z{7} b{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 8 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Pain_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b{1} z{1} b{2} z{2} b{3} z{3} b{4} z{4} c{5} z{5} c{6} z{6} c{7} z{7} c{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 9 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Pain_infs>base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [c{1} z{1} c{2} z{2} c{3} z{3} c{4} z{4} b{5} z{5} b{6} z{6} b{7} z{7} b{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 10 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Con_base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [a1{1} z{1} a1{2} z{2} a1{3} z{3} a1{4} z{4} d{5} z{5} d{6} z{6} d{7} z{7} d{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 11 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Con_infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [d{1} z{1} d{2} z{2} d{3} z{3} d{4} z{4} a1{5} z{5} a1{6} z{6} a1{7} z{7} a1{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 12 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Con_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [a1{1} z{1} a1{2} z{2} a1{3} z{3} a1{4} z{4} a5{5} z{5} a5{6} z{6} a5{7} z{7} a5{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 13 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Con_infs>base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [a5{1} z{1} a5{2} z{2} a5{3} z{3} a5{4} z{4} a1{5} z{5} a1{6} z{6} a1{7} z{7} a1{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 14 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var_base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b1{1} z{1} b1{2} z{2} b1{3} z{3} b1{4} z{4} d{5} z{5} d{6} z{6} d{7} z{7} d{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 15 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var_infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [d{1} z{1} d{2} z{2} d{3} z{3} d{4} z{4} b1{5} z{5} b1{6} z{6} b1{7} z{7} b1{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 16 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b1{1} z{1} b1{2} z{2} b1{3} z{3} b1{4} z{4} b4{5} z{5} b4{6} z{6} b4{7} z{7} b4{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 17 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var_infs>base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b4{1} z{1} b4{2} z{2} b4{3} z{3} b4{4} z{4} b1{5} z{5} b1{6} z{6} b1{7} z{7} b1{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 18 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var1_base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b2{1} z{1} b2{2} z{2} b2{3} z{3} b2{4} z{4} d{5} z{5} d{6} z{6} d{7} z{7} d{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 19 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var1_infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [d{1} z{1} d{2} z{2} d{3} z{3} d{4} z{4} b2{5} z{5} b2{6} z{6} b2{7} z{7} b2{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 20 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var1_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b2{1} z{1} b2{2} z{2} b2{3} z{3} b2{4} z{4} b5{5} z{5} b5{6} z{6} b5{7} z{7} b5{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 21 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var1_infs>base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b5{1} z{1} b5{2} z{2} b5{3} z{3} b5{4} z{4} b2{5} z{5} b2{6} z{6} b2{7} z{7} b2{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 22 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var2_base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b3{1} z{1} b3{2} z{2} b3{3} z{3} b3{4} z{4} d{5} z{5} d{6} z{6} d{7} z{7} d{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 23 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var2_infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [d{1} z{1} d{2} z{2} d{3} z{3} d{4} z{4} b3{5} z{5} b3{6} z{6} b3{7} z{7} b3{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 24 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var2_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b3{1} z{1} b3{2} z{2} b3{3} z{3} b3{4} z{4} b6{5} z{5} b6{6} z{6} b6{7} z{7} b6{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 25 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var2_infs>base';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b6{1} z{1} b6{2} z{2} b6{3} z{3} b6{4} z{4} b3{5} z{5} b3{6} z{6} b3{7} z{7} b3{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    %----- 26 -----%
    co = co + 1;
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.name    = 'Var1>2_base>infs';
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.convec  = [b7{1} z{1} b7{2} z{2} b7{3} z{3} b7{4} z{4} b8{5} z{5} b8{6} z{6} b8{7} z{7} b8{8} z{8} zeros(1,num_sess) ];
    matlabbatch{go}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
    
    try
        spm_jobman('run',matlabbatch);
    catch
        warning(['Problems with ' name '! Check again!!']);
        problems{end+1} = name;
    end
    
    clear matlabbatch
end

diary off
movefile(logfile,[logdir filesep analysis '_log' '_' timestamp '.txt']);

end







