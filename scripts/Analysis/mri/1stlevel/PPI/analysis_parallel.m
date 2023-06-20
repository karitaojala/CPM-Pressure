function analysis_parallel
% extended now to also do second level
% adapted from the same script for rodents
hostname = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostname
    case 'mahapralaya'
        base_dir          = 'd:\offhum_cb_new\';
        n_proc            = 4;
    case 'Rainbow'
        base_dir          = 'd:\offhum_cb_new\';
        l_string          = '';
        neuromorpho_mask  = 'c:\Users\buechel\Documents\MATLAB\spm12\atlas\MNI_Asym_neuromorphometrics.nii';
        n_proc            = 12;
    case 'motown'
        % to add private matlab path as variable
        base_dir          = 'c:\Users\buechel\Data\offhum_cb_new\';
        l_string          = '-c "c:\Users\buechel\Documents\license.lic"';
        neuromorpho_mask  = 'c:\Users\buechel\Documents\MATLAB\spm12\tpm\labels_Neuromorphometrics.nii';
        n_proc            = 8;
    otherwise
        error('Only hosts motown, Rainbow and mahapralaya accepted');
end



%all_subs     = [4:10 12 14:19 21    24 26 27 29:35 37:39]; %all
all_subs     = [4:10 11 12 14:19 21     22 24 26 27 29:35 37:39]; % very all

%all_subs    =  [4:10    12 14:19 21        24 26 27 29:35 37:39]; %exclude 11 22

groups = {all_subs};
group_weights_T = [1; -1];
group_names_T   = {'Pos','Neg'};

group_weights_F = [1];
group_names_F   = {'All'};

ana_names       = {'offset_fir','offset_hrf','offset_hrf_lsa','offset_ppi'};


%all_subs     = [6:10 11 12 14:19 21     22 24 26 27 29:35 37:39]; % very all

all_subs    = [4];


%% house keeping
TR                = 1.58;
dummies           = 0;
skern             = 0;
ana               = 2;  %1=OffsetFIR, 2=OffsetHRF 3=Offset hrf LS-A 4=PPI
parallel          = 0;
concatenate       = 1;
%% What to do on the 2nd level
n_type            = 'wv';  % (wv=with vasa, w=w/o)


%% ToDo list
do_model   = 0;
do_est     = 0;
do_vasa    = 0;
do_rois    = 1;
do_rois_atlas  = 0;
do_rois_flodin = 0;
do_lss     = 0;
do_cons    = 0;

%Dartel options
do_dwarp   = 0;
do_dsmooth = 0;

do_raw_correct_vasa = 0;

do_anova      = 0;
do_anova_con  = 0;

do_fact       = 0;
do_fact_con   = 0;

do_add_mask   = 0;

%% derived and standard variables
epi_folders       = {'run001','run002','run003'};

u_rc1_mean_templ  = '^u_rc1mean.*\.nii';
u_rc1_templ       = '^u_rc1.*\.nii';

rfunc_file        = '^randata.nii';
%rfunc_file        = '^radata.nii';

realign_str       = '^rp_adata.*\.txt';

con_temp          = 'con_%04.4d.nii';
beta_temp         = 'beta_%04.4d.nii';

if size(skern,2) == 3
    skernel           = skern;
else
    skernel           = skern;
    skernel           = repmat(skern,1,3);
end

sm_str = sprintf('%1.1f_',skernel); %smoothing_string
sm_str = strrep(sm_str,'.','_'); %clean up

spm_path          = fileparts(which('spm')); %get spm path
mat_name          = which(mfilename);
[~,mat_name,~]    = fileparts(mat_name);


if size(all_subs) < n_proc
    n_proc = size(all_subs,2);
end
%%prepare for multiprocessing
subs              = splitvect(all_subs, n_proc);

% noise_corr        = ['mov24_wm_csf_roi']; %the whole lot
% noise_corr        = ['mov24_wm_csf']; %the whole lot
%noise_corr        = ['mov24']; %the whole lot
noise_corr        = ['mov24_retro']; %the whole lot
% noise_corr        = ['mov6']; %the whole lot
% noise_corr        = ['mov6_wm_csf']; %the whole lot
% noise_corr        = ['mov6_wm_csf_roi']; %the whole lot



cvi               = 'None';
shift             = 0; %in TRs

if ana == 1 % Offset FIR
    warp_beta         = 0;
    warp_con          = 1;
    anadirname        = [noise_corr '_pain_offset_fir_' num2str(shift) '_' cvi];
    n_base            = 34;
    n_cond            = 4; % offset control
    cond_names        = {'control','offset','control_rate','offset_rate'};
    f_con             = [1 0 0 0; 0 1 0 0; -1 1 0 0]; % these will get extended later
    f_con_names       = {'control','offset','diff'};
    t_con_names       = {'21_30_offT3<conT3','13_17_offT2>conT2','19_22_offT3<conT3'};
    t_con = [ zeros(1,20) ones(1,10) zeros(1,4) zeros(1,20) -ones(1,10) zeros(1,4)  zeros(1,n_base*2);...
        zeros(1,12) ones(1,5) zeros(1,17) zeros(1,12) -ones(1,5) zeros(1,17) zeros(1,n_base*2);...
        zeros(1,18) ones(1,3) zeros(1,13) zeros(1,18) -ones(1,3) zeros(1,13) zeros(1,n_base*2)];
    
end

if ana == 2 % Offset HRF
    warp_beta         = 0;
    warp_con          = 1;
    anadirname        = [noise_corr '_pain_offset_hrf_' num2str(shift) '_' cvi];
    n_cond            = 4;
    n_base            = 3;
    cond_names        = {'control','offset','control_rate','offset_rate'};
    f_con             = [1 0 0 0; 0 1 0 0; -1 1 0 0];
    f_con_names       = {'control','offset','diff'};
    
    t_con = [ 0  0 0 -1 2 -1 zeros(1,6);... %akt
        1 -2 1 -1 2 -1 zeros(1,6);...
        0  1 0  0 -1 0 zeros(1,6);...
        0  0 1  0 0 -1 zeros(1,6);...
        0  0 0  1 0 -1 zeros(1,6);...
        0  0 0  -1 1 0 zeros(1,6);...
        0  0 0   0 1 -1 zeros(1,6);...
        1 -1 0  -1 1 0 zeros(1,6);...
        1 0 -1  -1 0 1 zeros(1,6)];
    t_con_names         = {'offT2>T1_T3',...
        'intT2>T1_T3',...
        'conT2>offT2',...
        'conT3>offT3',...
        'offT3<T1',...
        'offT2>T1',...
        'offT2>T3',...
        'intT2>T1',...
        'intT3>T1'};
end

if ana == 3 % Offset HRF LS-A
    warp_beta         = 1;
    warp_con          = 0;
    anadirname        = [noise_corr '_pain_offset_LSA_' num2str(shift) '_' cvi];
    n_cond            = 4;
    n_base            = 3;
    cond_names        = {'control','offset','control_rate','offset_rate'};
    f_con             = [1 0 0 0; 0 1 0 0; -1 1 0 0];
    f_con_names       = {'control','offset','diff'};
    
    t_con             = [];
    t_con_names       = {};
end

if ana == 4 % PPI
    ppi_ana_dir       = 'ONE_mov24_retro_pain_offset_hrf_0_None'; %where the ppi regressors come from
    region            = 'dPAG';
    ppi_name          = 'gPPI_%s_%d.mat';
    anadirname        = [noise_corr '_pain_offset_gPPI_' region num2str(shift) '_' cvi];

    n_cond            = 13; % 
    cond_names        = {'area','con1','con2','con3','off1','off2','off3','con1_ppi','con2_ppi','con3_ppi','off1_ppi','off2_ppi','off3_ppi'};
    ppi_diff          = [zeros(3,7) eye(3) -eye(3)];
    f_con             = [eye(13); ppi_diff]; % these will get extended later
    f_con_names       = [cond_names {'ppi_diff_1','ppi_diff_2','ppi_diff_3'}];
    
    %    t_con_names       = cond_names;
    %    t_con             = eye(13);
    t_con = f_con;
    t_con_names = f_con_names;
    
    n_t_con           = size(t_con,1);
    n_base            = 1;
    
    cond_use          = [1:n_base*n_cond];
end





if concatenate
    anadirname = ['ONE_' anadirname];
end


cond_use          = [1:n_base*n_cond];


%% main loop
for np = 1:size(subs,2)
    matlabbatch = [];
    mbi = 0;
    for g = 1:size(subs{np},2)
        n_sess      = size(epi_folders,2);
        name        = sprintf('sub%03.3d',subs{np}(g));
        name_s      = sprintf('sub%03.3d',subs{np}(g));
        st_dir      = [base_dir name filesep 'run000' filesep];
        mepi_dir    = [base_dir name filesep 'run001' filesep];
        u_rc1_file_ana  = spm_select('FPList', st_dir, u_rc1_templ);
        u_rc1_file_epi  = spm_select('FPList', mepi_dir, u_rc1_mean_templ);
        template = [];
        template.spm.stats.fmri_spec.timing.units   = 'scans';
        template.spm.stats.fmri_spec.timing.RT      = TR;
        template.spm.stats.fmri_spec.timing.fmri_t  = 16;
        template.spm.stats.fmri_spec.timing.fmri_t0 = 8;
        
        template.spm.stats.fmri_spec.fact             = struct('name', {}, 'levels', {});
        if ana==1 % FIR
            template.spm.stats.fmri_spec.bases.fir.length = TR*n_base;
            template.spm.stats.fmri_spec.bases.fir.order  = n_base;
        else
            template.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        end
        template.spm.stats.fmri_spec.volt             = 1;
        template.spm.stats.fmri_spec.mthresh          = -Inf;
        template.spm.stats.fmri_spec.global           = 'None';
        template.spm.stats.fmri_spec.cvi              = cvi;
        template.spm.stats.fmri_spec.mask             = cellstr([base_dir name filesep 'run000' filesep 's3skull_strip.nii']);
        
        if ana == 1 || ana == 2 || ana == 3 || ana == 4
            a_dir    = [base_dir name filesep anadirname];
        end
        
        
        for sess = 1:n_sess
            
            s_dir    = [base_dir name filesep epi_folders{sess}];
            fm       = spm_select('FPList', s_dir, realign_str);
            movement = normit(load(fm));
            seg_noise = load([s_dir filesep 'segment_noise.mat']);
            roi_noise = load([s_dir filesep 'roi_noise.mat']);
            
            ri_str    = [base_dir 'Physio' filesep name '_physio_run' num2str(sess) '.mat'];
            retroicor = load(ri_str);
            
            
            mov_final   = normit(movement(dummies+1:end,:));
            mov_final_d = diff(mov_final);
            mov_final_d = normit([mov_final_d(1,:); mov_final_d]);
            mov_final_2 = mov_final.^2;
            mov_final_d_2 = mov_final_d.^2;
            
            
            
            if strfind(noise_corr,'mov6')
                all_nuis{sess} = [mov_final];
            elseif strfind(noise_corr,'mov24')
                all_nuis{sess} = [mov_final normit(mov_final_2) mov_final_d normit(mov_final_d_2)];
            end
            if strfind(noise_corr,'retro')
                all_nuis{sess} = [all_nuis{sess} normit(retroicor.physio)];
            end
            if strfind(noise_corr,'wm')
                all_nuis{sess} = [all_nuis{sess} normit(seg_noise.segment(1).data(dummies+1:end,:))];
            end
            
            if strfind(noise_corr,'csf')
                all_nuis{sess} = [all_nuis{sess} normit(seg_noise.segment(2).data(dummies+1:end,:))];
            end
            
            if strfind(noise_corr,'roi')
                all_nuis{sess} = [all_nuis{sess} normit(roi_noise.roi(1).data(dummies+1:end,:))];
                all_nuis{sess} = [all_nuis{sess} normit(roi_noise.roi(2).data(dummies+1:end,:))];
            end
            
            %all_nuis{sess} = [];
            n_nuis         = size(all_nuis{sess},2);
            z{sess}        = zeros(1,n_nuis); %handy for contrast def
            
            scans = spm_select('ExtFPList', [base_dir filesep name filesep epi_folders{sess}], rfunc_file,inf);
            
            scans = scans(dummies+1:end,:);
            scan_vec(sess) = size(scans,1);
            scan_ind = [ [1 cumsum(scan_vec)+1]' [cumsum(scan_vec) 0]'];
            c_ind = scan_ind(sess,1):1:scan_ind(sess,2);
            template.spm.stats.fmri_spec.sess(sess).scans = cellstr(scans);
            %template.spm.stats.fmri_spec.sess(sess).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
            template.spm.stats.fmri_spec.sess(sess).multi = {''};
            
            onset_file = spm_select('FPList',[base_dir 'logfiles' filesep name_s filesep],['^' name_s '_run' num2str(sess) '.*\.mat']);
            RES = extract_offset(onset_file, cond_names);
            if ana == 1
                for rr=1:numel(RES)
                    RES{rr}.dur    = 0;
                    RES{rr}.onset  = RES{rr}.onset + shift;
                end
            end
            if ana == 2
                RES_new{1} = RES{1};RES_new{1}.name = 'Const_T1';RES_new{1}.dur = 15/TR;RES_new{1}.onset = RES_new{1}.onset + shift;
                RES_new{2} = RES{1};RES_new{2}.name = 'Const_T2';RES_new{2}.dur = 10/TR;RES_new{2}.onset = RES_new{2}.onset+15/TR + shift;
                RES_new{3} = RES{1};RES_new{3}.name = 'Const_T3';RES_new{3}.dur = 15/TR;RES_new{3}.onset = RES_new{3}.onset+25/TR + shift;
                
                RES_new{4} = RES{2};RES_new{4}.name = 'Offset_T1';RES_new{4}.dur = 15/TR;RES_new{4}.onset = RES_new{4}.onset + shift;
                RES_new{5} = RES{2};RES_new{5}.name = 'Offset_T2';RES_new{5}.dur = 10/TR;RES_new{5}.onset = RES_new{5}.onset+15/TR + shift;
                RES_new{6} = RES{2};RES_new{6}.name = 'Offset_T3';RES_new{6}.dur = 15/TR;RES_new{6}.onset = RES_new{6}.onset+25/TR + shift;
                
                RES_new{7} = RES{3};RES_new{7}.name = 'C_Rate_T1';RES_new{7}.dur = 15/TR;RES_new{7}.onset = RES_new{7}.onset + shift;
                RES_new{8} = RES{3};RES_new{8}.name = 'C_Rate_T2';RES_new{8}.dur = 10/TR;RES_new{8}.onset = RES_new{8}.onset+15/TR + shift;
                RES_new{9} = RES{3};RES_new{9}.name = 'C_Rate_T3';RES_new{9}.dur = 15/TR;RES_new{9}.onset = RES_new{9}.onset+25/TR + shift;
                
                RES_new{10} = RES{4};RES_new{10}.name = 'O_Rate_T1';RES_new{10}.dur = 15/TR;RES_new{10}.onset = RES_new{10}.onset + shift;
                RES_new{11} = RES{4};RES_new{11}.name = 'O_Rate_T2';RES_new{11}.dur = 10/TR;RES_new{11}.onset = RES_new{11}.onset+15/TR + shift;
                RES_new{12} = RES{4};RES_new{12}.name = 'O_Rate_T3';RES_new{12}.dur = 15/TR;RES_new{12}.onset = RES_new{12}.onset+25/TR + shift;
                
                RES = RES_new;
            end
            if ana == 3
                ind  = 1;all = [];
                test = cell2mat(RES);
                for r = 1:numel(RES)
                    new = [];
                    new(:,1) = test(r).onset';
                    new(:,2) = repmat(r,size(new(:,1),1),1);
                    all = [all ; new];
                end
                [~,i] = sort(all(:,1));
                resorted = all(i,:);
                for j=1:size(resorted,1)
                    Rnew{ind}.name  = ['T1_' RES{resorted(j,2)}.name];
                    Rnew{ind}.onset = resorted(j,1) + shift;
                    Rnew{ind}.dur   = 15/TR;
                    ind = ind + 1;
                    Rnew{ind}.name  = ['T2_' RES{resorted(j,2)}.name];
                    Rnew{ind}.onset = resorted(j,1) + 15/TR + shift;
                    Rnew{ind}.dur   = 10/TR;
                    ind = ind + 1;
                    Rnew{ind}.name  = ['T3_' RES{resorted(j,2)}.name];
                    Rnew{ind}.onset = resorted(j,1) + 25/TR + shift;
                    Rnew{ind}.dur   = 15/TR;
                    ind = ind + 1;
                end
                RES = Rnew;
                % recalc cond_use
                cond_use          = [1:ind-1];
            end
            
            if ana ~= 4 % all but ppi
                conds_i = 0;
                for conds = 1:size(RES,2)
                    conds_i = conds_i + 1;
                    template.spm.stats.fmri_spec.sess(sess).cond(conds_i).name     = RES{conds}.name;
                    template.spm.stats.fmri_spec.sess(sess).cond(conds_i).onset    = RES{conds}.onset;
                    template.spm.stats.fmri_spec.sess(sess).cond(conds_i).duration = RES{conds}.dur; %in seconds
                end
                cov_int = 0;
                
            else  % PPI
                % $$$ only put relevant part in here as this will be concatenated later
               if ~concatenate
                   ppi_f = [base_dir name filesep ppi_ana_dir filesep sprintf(ppi_name,region,sess)];
               else
                   ppi_f = [base_dir name filesep ppi_ana_dir filesep sprintf(ppi_name,region,1)];
               end
               
                p     = load(ppi_f);
                all_cov = [p.PPI{1}.Y(c_ind,:) p.PPI{1}.P(c_ind,:) p.PPI{2}.P(c_ind,:) p.PPI{3}.P(c_ind,:) p.PPI{4}.P(c_ind,:) p.PPI{5}.P(c_ind,:) p.PPI{6}.P(c_ind,:),... 
                           p.PPI{1}.ppi(c_ind,:) p.PPI{2}.ppi(c_ind,:) p.PPI{3}.ppi(c_ind,:) p.PPI{4}.ppi(c_ind,:) p.PPI{5}.ppi(c_ind,:) p.PPI{6}.ppi(c_ind,:)];
                
                for cov_int = 1:size(all_cov,2)
                    template.spm.stats.fmri_spec.sess(sess).regress(cov_int) = struct('name', cellstr(cond_names{cov_int}), 'val', all_cov(:,cov_int));
                end
                final_scan = size(all_cov,1)+dummies;
            end
            
            template.spm.stats.fmri_spec.sess(sess).multi_reg = {''};
            template.spm.stats.fmri_spec.sess(sess).hpf = 180;
            for nuis = 1:n_nuis
                template.spm.stats.fmri_spec.sess(sess).regress(cov_int+nuis) = struct('name', cellstr(num2str(nuis)), 'val', all_nuis{sess}(:,nuis));
            end
        end
        if concatenate
            warp_beta = 1;
            warp_con  = 0; %see how this goes
            % now take template struc and create a single session ...
            c_scan_vec = cumsum(scan_vec);
            new_t = template;
            new_t.spm.stats.fmri_spec.sess(2:end) = []; %kill original sessions
            for sess = 2:n_sess
                new_t.spm.stats.fmri_spec.sess(1).scans = [new_t.spm.stats.fmri_spec.sess(1).scans;template.spm.stats.fmri_spec.sess(sess).scans];
                for re = 1:numel(new_t.spm.stats.fmri_spec.sess(1).regress)
                    if numel(new_t.spm.stats.fmri_spec.sess(1).regress) == numel(template.spm.stats.fmri_spec.sess(sess).regress)
                        new_t.spm.stats.fmri_spec.sess(1).regress(re).val = [new_t.spm.stats.fmri_spec.sess(1).regress(re).val; template.spm.stats.fmri_spec.sess(sess).regress(re).val];
                    else
                        error('number of nuisance variables needs to be identical');
                    end
                end
                if isfield(template.spm.stats.fmri_spec.sess(sess),'cond')
                    l_c = numel(template.spm.stats.fmri_spec.sess(sess).cond);
                else
                    l_c = 0; % PPI
                end
                for c=1:l_c
                    if ana == 3 %LS A
                        new_t.spm.stats.fmri_spec.sess(1).cond(end+1).name   = template.spm.stats.fmri_spec.sess(sess).cond(c).name; %end is now end+1 ... be careful
                        new_t.spm.stats.fmri_spec.sess(1).cond(end).onset    = template.spm.stats.fmri_spec.sess(sess).cond(c).onset + c_scan_vec(sess-1);
                        new_t.spm.stats.fmri_spec.sess(1).cond(end).duration = template.spm.stats.fmri_spec.sess(sess).cond(c).duration;
                    else
                        if strcmp(template.spm.stats.fmri_spec.sess(1).cond(c).name,[template.spm.stats.fmri_spec.sess(sess).cond(c).name]) %OK same name
                            new_t.spm.stats.fmri_spec.sess(1).cond(c).onset   = [new_t.spm.stats.fmri_spec.sess(1).cond(c).onset template.spm.stats.fmri_spec.sess(sess).cond(c).onset + c_scan_vec(sess-1)];
                        else
                            error('Condition order does not match')
                        end
                    end
                end
            end
            if isfield(template.spm.stats.fmri_spec.sess(sess),'cond')
                lss_ind  = [1:numel(new_t.spm.stats.fmri_spec.sess(1).cond) ones(1,n_sess + numel(z{1})).*NaN];
                cond_use = [1:numel(new_t.spm.stats.fmri_spec.sess(1).cond)];
            end
            n_sess   = 1; %set # of sessions to 1
            template = new_t;
            z        = z(1);
        end
        
        
        
        
        if do_model
            mbi = mbi + 1;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = sprintf('--------------\ndoing Subject %s\n--------------\n',name);
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'fprintf';
            
            mbi = mbi + 1;
            matlabbatch{mbi} = template;
            mkdir(a_dir);
            copyfile(which(mfilename),a_dir);
            matlabbatch{mbi}.spm.stats.fmri_spec.dir = {[a_dir]};
            
            if concatenate
                mbi = mbi + 1;
                matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = [a_dir filesep 'SPM.mat'];
                matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{2}.evaluated = scan_vec;
                matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
                matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'spm_fmri_concatenate';
            end
        end
        
        if do_est
            mbi = mbi + 1;
            matlabbatch{mbi}.spm.stats.fmri_est.spmmat           = {[a_dir filesep 'SPM.mat']};
            matlabbatch{mbi}.spm.stats.fmri_est.method.Classical = 1;
        end
        
        if do_lss
            mbi = mbi + 1;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = [a_dir filesep 'SPM.mat'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{2}.evaluated = lss_ind;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'spm_spm_lss';
        end
        
        if do_vasa
            mbi = mbi + 1;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = [a_dir filesep 'SPM.mat'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'cb_vasa';
        end
        
        if do_rois

            xY(1).def  = 'sphere';
            xY(1).xyz  = [36 4.5 10.5]';
            xY(1).spec = 4;
            xY(1).rad  = 4;
            xY(1).str  = 'daIns';
            xY(1).Ic   = 1;
            xY(1).T    = 1; %eoi
            
            xY(2) = xY(1);
            xY(2).xyz  = [37.5 -16.5 18]';
            xY(2).str  = 'dpIns';
            
            xY(3) = xY(1);
            xY(3).xyz  = [49.5 -30 28.5]';
            xY(3).str  = 'S_II';
            
            xY(4) = xY(1);
            xY(4).xyz  = [0 10.5 34.5]';
            xY(4).str  = 'mid_ACC';
            xY(4).spec = 8;
            xY(4).rad  = 8;
            
            xY(5) = xY(1);
            xY(5).str  = 'vPAG';
            xY(5).xyz  = [0.00 -34.00 -11.00]';

            xY(6) = xY(1);
            xY(6).xyz  = [0.00 -31.00 -8.00]';
            xY(6).str  = 'mPAG';

            xY(7) = xY(1);
            xY(7).str  = 'dPAG';
            xY(7).xyz  = [0.00 -26.00 -4.00]';
            
           
            
            mbi = mbi + 1;
            % loop over control and offset
            temp = eye(6);
            for tt=1:size(temp,1)
                Uu{tt} = [[1:12]' ones(12,1) [temp(tt,:)'; zeros(6,1)]];
            end

            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string    = [a_dir filesep 'SPM.mat'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{2}.string    = [mepi_dir filesep 'wtmeanadata.nii'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{3}.string    = [mepi_dir filesep 'y_epi_2_template.nii'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{4}.evaluated = skern;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{5}.evaluated = xY;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{6}.evaluated = Uu;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{7}.evaluated = 'roi_';
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'get_roi_ts';            
        end

        if do_rois_flodin
            
            fl = load('pain_coords.mat');
            for co = 1:size(fl.pain_coords,1)
                xY(co).def  = 'sphere';
                xY(co).xyz  = fl.pain_coords(co,:)';
                xY(co).Ic   = 1;
                xY(co).spec = 4;
                xY(co).str  = num2str(co);
            end
            mbi = mbi + 1;
            % loop over control and offset
            temp = eye(6);
            for tt=1:size(temp,1)
                Uu{tt} = [[1:12]' ones(12,1) [temp(tt,:)'; zeros(6,1)]];
            end

            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string    = [a_dir filesep 'SPM.mat'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{2}.string    = [mepi_dir filesep 'wtmeanadata.nii'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{3}.string    = [mepi_dir filesep 'y_epi_2_template.nii'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{4}.evaluated = skern;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{5}.evaluated = xY;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{6}.evaluated = Uu;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{7}.evaluated = 'flodin_';
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'get_roi_ts';            
        end
        

        
        if do_rois_atlas
            atlas_name = 'MNI_Asym_Schaefer2018_100Parcels_17Networks_order';
            w_rois     = [1:100]; % linear index into the atlas NOT label 
            % if looking for a specific label use this: find(squeeze(cat(xA.labels.index)) == 55)
            xA         = spm_atlas('load',atlas_name);
            
            for i=1:numel(w_rois)
                xY(i).name = xA.labels(w_rois(i)).name;
                xY(i).str  = strrep(xA.labels(w_rois(i)).name,' ','_');
                xY(i).ind  = xA.labels(w_rois(i)).index;
                xY(i).spec = xA.info.files.images;
                xY(i).def  = 'mask';
                xY(i).xyz  = Inf;
                xY(i).Ic   = 1;
            end
            
            
            mbi = mbi + 1;
            Uu = [];
            
            temp = eye(6);
            for tt=1:size(temp,1)
                Uu{tt} = [[1:12]' ones(12,1) [temp(tt,:)'; zeros(6,1)]];
            end
          
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string    = [a_dir filesep 'SPM.mat'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{2}.string    = [mepi_dir filesep 'wtmeanadata.nii'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{3}.string    = [mepi_dir filesep 'y_epi_2_template.nii'];
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{4}.evaluated = skern;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{5}.evaluated = xY;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{6}.evaluated = Uu;
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.inputs{7}.evaluated = 'Schaefer_100_';
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{mbi}.cfg_basicio.run_ops.call_matlab.fun = 'get_roi_ts';
        end
        
        
        

        
        %%template for contrasts
        template = [];
        template.spm.stats.con.spmmat = {[a_dir filesep 'SPM.mat']};
        template.spm.stats.con.delete = 1;
        fco = 0;
        fco = fco + 1; %counter for f-contrasts
        template.spm.stats.con.consess{fco}.fcon.name   = 'eff_of_int';
        template.spm.stats.con.consess{fco}.fcon.convec = {[ repmat([eye(size(cond_use,2)) zeros(size(cond_use,2),n_nuis)],1,n_sess) zeros(size(cond_use,2),n_sess)]};
        co_i  = 0;
        simple_con = []; simple_beta = [];%takes the indices of simüple contratsts for ANOVA etc
        if ana == 1 || ana == 2 || ana == 4  %basic contrasts for ANOVA
            for co = 1:n_cond
                for i_fir = 1:n_base
                    tpl        = zeros(1,n_base);
                    tpl(i_fir) = 1;
                    tpl        = [zeros(1,(co-1)*n_base) tpl zeros(1,(n_cond-co)*n_base)];
                    convec = [];
                    for i_sess = 1:n_sess
                        convec = [convec tpl z{i_sess}];
                    end
                    co_i = co_i + 1;
                    template.spm.stats.con.consess{co_i+fco}.tcon.name    = [cond_names{co} '_' num2str(i_fir)];
                    all_t_con_names{co_i}                                 = [cond_names{co} '_' num2str(i_fir)];
                    template.spm.stats.con.consess{co_i+fco}.tcon.convec  = [convec zeros(1,size(epi_folders,2))];
                    template.spm.stats.con.consess{co_i+fco}.tcon.sessrep = 'none';
                    simple_con  = [simple_con co_i+fco];
                    simple_beta = [simple_beta co_i];
                end
            end
        end
        if ana == 2 %additional constrasts for one sample t test
            for co = 1:size(t_con_names,2)
                co_i = co_i + 1;
                template.spm.stats.con.consess{co_i+fco}.tcon.name    = [t_con_names{co}];
                all_t_con_names{co_i}                                 = [t_con_names{co}];
                t_vec = [];
                for i_sess=1:n_sess
                    t_vec = [t_vec t_con(co,:) z{i_sess}];
                end
                template.spm.stats.con.consess{co_i+fco}.tcon.convec  = [t_vec zeros(1,n_sess)];
                template.spm.stats.con.consess{co_i+fco}.tcon.sessrep = 'none';
            end
        end
        
        %PREPARE LIST OF CON and BETA files
                
        if do_cons
            mbi = mbi + 1;
            matlabbatch{mbi} = template; %now add constrasts
        end
        
        
        %prepare_warp
        template = [];
        con_files   = '';
        if warp_con
            for co = 1:size(all_t_con_names,2)
                con_files(co,:) = [a_dir filesep sprintf(con_temp,co+fco)];
            end
        end
        
        if warp_beta
            for be = 1:size(cond_use,2)
                con_files = strvcat(con_files,[a_dir filesep sprintf(beta_temp,cond_use(be))]);
            end
        end
        con_files = strvcat(con_files,[a_dir filesep 'mask.nii']);
        
        
        if do_raw_correct_vasa
            
            vasa_file = [a_dir filesep 'vasa_res.nii'];
            for co = 1:size(con_files,1)
                mbi = mbi + 1;
                c_f = strtrim(con_files(co,:));
                matlabbatch{mbi}.spm.util.imcalc.input  = {c_f,vasa_file}';
                matlabbatch{mbi}.spm.util.imcalc.output = ins_letter(c_f,'v');
                matlabbatch{mbi}.spm.util.imcalc.outdir = {''};
                matlabbatch{mbi}.spm.util.imcalc.expression = 'i1./i2';%
                matlabbatch{mbi}.spm.util.imcalc.var = struct('name', {}, 'value', {});
                matlabbatch{mbi}.spm.util.imcalc.options.dmtx = 0;
                matlabbatch{mbi}.spm.util.imcalc.options.mask = 0;
                matlabbatch{mbi}.spm.util.imcalc.options.interp = 1;
                matlabbatch{mbi}.spm.util.imcalc.options.dtype = 16;
            end
        end
        
        if do_dwarp
            %using nlin coreg + DARTEL
            mbi = mbi + 1;
            matlabbatch{mbi}.spm.util.defs.comp{1}.def = {[mepi_dir filesep 'y_epi_2_template.nii']};
            matlabbatch{mbi}.spm.util.defs.out{1}.pull.fnames = cellstr(spm_file(con_files, 'prefix','v')); 
            matlabbatch{mbi}.spm.util.defs.out{1}.pull.savedir.savesrc = 1;
            matlabbatch{mbi}.spm.util.defs.out{1}.pull.interp = 4;
            matlabbatch{mbi}.spm.util.defs.out{1}.pull.mask = 1;
            matlabbatch{mbi}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
            matlabbatch{mbi}.spm.util.defs.out{1}.pull.prefix = 'w';
                
        end
        
        if do_dsmooth
            mbi = mbi + 1;
            matlabbatch{mbi}.spm.spatial.smooth.data = cellstr(spm_file(con_files, 'prefix','wv')); 
            matlabbatch{mbi}.spm.spatial.smooth.fwhm = skernel;
            matlabbatch{mbi}.spm.spatial.smooth.prefix = ['s' sm_str];
        end
        
    end
    if ~isempty(matlabbatch)
        if parallel
            save([num2str(np) '_' mat_name],'matlabbatch');
            lo_cmd = ['clear matlabbatch;load(''' num2str(np) '_' mat_name ''');'];
            ex_cmd = ['addpath(''' spm_path ''');addpath(''c:\Users\buechel\HiDrive\MATLAB\'');spm(''defaults'',''FMRI'');spm_jobman(''initcfg'');spm_jobman(''run'',matlabbatch);exit'];
            system(['start matlab.exe ' l_string ' -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r "' lo_cmd ex_cmd ';exit"']);
        else
            spm_jobman('initcfg');
            spm('defaults', 'FMRI');
            spm_jobman('run',matlabbatch);
        end
    end
end

if do_fact || do_fact_con
    addon   = 'FACT';
    out_dir = [base_dir 'Second_Level' filesep addon '_' anadirname '_' n_type '_' sm_str];
    matlabbatch = [];
    
    %% --------------------- MODEL SPECIFICATION --------------------- %%
    matlabbatch{1}.spm.stats.factorial_design.dir = {out_dir};
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).name = 'GROUP';
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).dept = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).variance = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).ancova = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).name = 'SUBJECT';
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).dept = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).variance = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).ancova = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).name = 'CONDITION';
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).dept = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).variance = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).ancova = 0;
    if ana == 1  % FIR
        matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).variance = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).dept = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).variance = 1;
    end
    
    %GROUP SUBJECT DAY CONDITION
    allfiles  = [];
    imat      = [];
    inc_su = 1;
    for gr = 1:size(groups,2)
        for su = 1:size(groups{gr},2)
            for co = 1:size(cond_use,2)
                name        = sprintf('sub%03.3d',groups{gr}(su));
                a_dir       = [base_dir name filesep anadirname filesep];
                s_string    = sprintf('s%s',sm_str);
                if skern == 0;s_string = '';end
                if warp_beta
                    swcon_file = [a_dir sprintf(['%s%s' beta_temp], s_string, n_type,simple_beta(co))];
                end
                if warp_con
                    swcon_file = [a_dir sprintf(['%s%s' con_temp], s_string, n_type,simple_con(co))];
                end
                allfiles    = strvcat(allfiles,swcon_file);
                mat_entry   = [1 gr inc_su co];
                imat        = [imat; mat_entry];
            end
            inc_su = inc_su + 1;
        end
    end
    
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans    = cellstr(allfiles);
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fsuball.specall.imatrix  = imat;
    
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.maininters{1}.fmain.fnum  = [3];
    %matlabbatch{1}.spm.stats.factorial_design.des.fblock.maininters{2}.fmain.fnum  = [2];
    %matlabbatch{1}.spm.stats.factorial_design.des.fblock.maininters{2}.inter.fnums = [1 3];
    
    matlabbatch{1}.spm.stats.factorial_design.cov                  = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov            = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none   = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im           = 1;
    %matlabbatch{1}.spm.stats.factorial_design.masking.em           = {[base_dir 'TPL_' ana_names{ana} '_' n_type '_mask.nii']};
    matlabbatch{1}.spm.stats.factorial_design.masking.em           = {neuromorpho_mask};
    
    %% --------------------- MODEL ESTIMATION --------------------- %%
    
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {[out_dir '\SPM.mat']};
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
end

if do_fact
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    save('fact.mat','matlabbatch');
    spm_jobman('run',matlabbatch);
    copyfile(which(mfilename),out_dir);
    
end

if do_fact_con
    matlabbatch = [];
    clear SPM; load([out_dir '\SPM.mat']); %should exist by now
    matlabbatch{1}.spm.stats.con.spmmat = {[out_dir '\SPM.mat']};
    matlabbatch{1}.spm.stats.con.delete = 1;
    
    n_conds = size(cond_use,2);
    n_subs  = size(all_subs,2);
    
    co = 1;
    matlabbatch{1}.spm.stats.con.consess{co}.fcon.name   = 'eff_of_int';
    Fc = spm_FcUtil('Set','F_iXO_Test','F','iX0',[],SPM.xX.X);
    matlabbatch{1}.spm.stats.con.consess{co}.fcon.convec = {Fc.c'};
    co = co + 1; %increment by 1
    
    for gw = 1:numel(group_names_F)
        for fc = 1:numel(f_con_names)
            matlabbatch{1}.spm.stats.con.consess{co}.fcon.name   = [group_names_F{gw} '_' f_con_names{fc}];
            %fcon = kron(group_weights_F(gw,:),kron(diag(f_con(fc,:)),eye(n_base)));
            fcon = kron(group_weights_F(gw,:),kron(f_con(fc,:),eye(n_base)));
            %fcon = [fcon zeros(size(fcon,1),n_subs)];
            Fc = spm_FcUtil('Set','F_iXO_Test','F','c+',fcon',SPM.xX.X);
            matlabbatch{1}.spm.stats.con.consess{co}.fcon.convec = {Fc.c'};
            co = co + 1; %increment by 1
        end
    end
    
    for gw = 1:numel(group_names_T)
        for tc = 1:numel(t_con_names)
            matlabbatch{1}.spm.stats.con.consess{co}.tcon.name    = [group_names_T{gw} '_' t_con_names{tc}];
            matlabbatch{1}.spm.stats.con.consess{co}.tcon.convec  = [kron(group_weights_T(gw,:),t_con(tc,:))];
            matlabbatch{1}.spm.stats.con.consess{co}.tcon.sessrep = 'none';
            co = co + 1; %increment by 1
        end
    end
    
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    save('fact_con.mat','matlabbatch');
    spm_jobman('run',matlabbatch);
end


if do_anova || do_anova_con
    addon   = 'ANOVA';
    out_dir = [base_dir 'Second_Level' filesep addon '_' anadirname '_' n_type '_' sm_str];
    matlabbatch = [];
    
    for g = 1:size(all_subs,2)
        name       = sprintf('%04.4d',all_subs(g));
        all_files = [];assemb_cons = [];
        for co = 1:size(cond_use,2)
            swbeta_templ      = sprintf('s%s%sbeta_%0.4d.nii', sm_str, n_type,cond_use(co));
            all_files         = strvcat(all_files,[base_dir name filesep paradigm filesep anadirname filesep swbeta_templ]);
            assemb_cons = [assemb_cons cond_use(co)];
        end
        matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(g).scans = cellstr(all_files);
        matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(g).conds = assemb_cons;
        
        %% --------------------- MODEL SPECIFICATION --------------------- %%
        matlabbatch{1}.spm.stats.factorial_design.dir = {out_dir};
        matlabbatch{1}.spm.stats.factorial_design.des.anovaw.dept = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.anovaw.variance = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.anovaw.gmsca = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.anovaw.ancova = 0;
        matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
        matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
        matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {'d:\rodent_SIGMA\mean_wskull.nii'};
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
        matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
        matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
        
        %% --------------------- MODEL ESTIMATION --------------------- %%
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {[out_dir '\SPM.mat']};
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
        
    end
end

if do_anova
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    copyfile(which(mfilename),out_dir);
end

if do_anova_con
    matlabbatch = [];
    clear SPM; load([out_dir '\SPM.mat']); %should exist by now
    matlabbatch{1}.spm.stats.con.spmmat = {[out_dir '\SPM.mat']};
    matlabbatch{1}.spm.stats.con.delete = 1;
    
    n_conds = size(cond_use,2);
    n_subs  = size(all_subs,2);
    
    co = 1;
    matlabbatch{1}.spm.stats.con.consess{co}.fcon.name   = 'eff_of_int';
    Fc = spm_FcUtil('Set','F_iXO_Test','F','iX0',[n_conds*numel(group_names)+1:n_conds*numel(group_names)+n_subs],SPM.xX.X);
    matlabbatch{1}.spm.stats.con.consess{co}.fcon.convec = {Fc.c'};
    co = co + 1; %increment by 1
    
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
end

if do_add_mask
    matlabbatch = [];
    all_files = [];
    for g = 1:size(all_subs,2)
        name       = sprintf('sub%03.3d',all_subs(g));
        all_files  = strvcat(all_files,[base_dir name filesep anadirname filesep n_type 'mask.nii']);
    end
    matlabbatch{1}.spm.util.imcalc.input  = cellstr(all_files);
    matlabbatch{1}.spm.util.imcalc.output = ['SUM_' ana_names{ana} '_' n_type '_mask.nii'];
    matlabbatch{1}.spm.util.imcalc.outdir = cellstr(base_dir);
    matlabbatch{1}.spm.util.imcalc.expression = 'sum(X)';
    matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
    matlabbatch{1}.spm.util.imcalc.options.mask = 0;
    matlabbatch{1}.spm.util.imcalc.options.interp = 1;
    matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
    
    matlabbatch{2} = matlabbatch{1};
    matlabbatch{2}.spm.util.imcalc.output = ['AND_' ana_names{ana} '_' n_type '_mask.nii'];
    matlabbatch{2}.spm.util.imcalc.expression = 'all(X)';
    
    matlabbatch{3} = matlabbatch{2};
    matlabbatch{3}.spm.util.imcalc.input  = cellstr(strvcat(all_files,neuromorpho_mask));
    matlabbatch{3}.spm.util.imcalc.output = ['TPL_' ana_names{ana} '_' n_type '_mask.nii'];
    
    
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    
end

function chuckCell = splitvect(v, n)
% Splits a vector into number of n chunks of  the same size (if possible).
% In not possible the chunks are almost of equal size.
%
% based on http://code.activestate.com/recipes/425044/

chuckCell = {};

vectLength = numel(v);


splitsize = 1/n*vectLength;

for i = 1:n
    %newVector(end + 1) =
    idxs = [floor(round((i-1)*splitsize)):floor(round((i)*splitsize))-1]+1;
    chuckCell{end + 1} = v(idxs);
end

function out = ins_letter(pscan,letter)
for a=1:size(pscan,1)
    [p , f, e] = fileparts(pscan(a,:));
    out(a,:) = [p filesep letter f e];
end

function out = chng_path(pscan,pa)
for a=1:size(pscan,1)
    [p , f, e] = fileparts(pscan(a,:));
    out(a,:) = [pa filesep f e];
end

function RES = extract_offset(onset_file,conditions)
r1 = load(onset_file);
trials      = r1.p.presentation.trialList;
rate_trials = cell2mat (r1.p.log.onratings.conTrial);
trials(rate_trials) = trials(rate_trials)+2; %make rate trials index 3 and 4
onsets              = r1.p.log.PainOnsetScan;
for i=1:size(conditions,2)
    RES{i}.name  = conditions{i};
    RES{i}.onset = onsets(find(trials == i));
end

