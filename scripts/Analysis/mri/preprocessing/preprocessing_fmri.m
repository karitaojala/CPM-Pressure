function preprocessing_fmri

hostname = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostname
    case 'isnb05cda5ba721' % work laptop
        base_dir          = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\';
        l_string          = '';
        n_proc            = 2; % maximum processes on 2 cores
        sct_path          = 'C:\Users\ojala\spinalcordtoolbox';
        spm_path          = 'C:\Data\Toolboxes\spm12';
%     case 'motown'
%         base_dir          = 'c:\Users\buechel\Data\cpm\mri\data\';
%         l_string          = '-c "c:\Users\buechel\Documents\license.lic"';
%         n_proc            = 6;
    otherwise
        error('Only host isnb05cda5ba721 (Karita work laptop) accepted');
end

addpath(genpath(spm_path))
addpath(sct_path)

parallel       = 0; % run several processes (matlabs/subjects) in parallel on different cores

do_sp_slicetime  = 0;
do_sp_sct        = 1;

do_shift         = 0;
do_slicetime     = 0;
do_realign       = 0;
do_nonlincoreg   = 0;
do_seg           = 0;
do_skull         = 0;

do_norm          = 0;
do_back          = 0;
do_comb_dar_nlin = 0;
do_nlin_reverse  = 0;
do_warp          = 0;

do_sm_skull      = 0; % can only be done after all of the above steps

do_avg_norm      = 0; % can only be done after all subjects done
spinal = 1;

all_subs     = 1;%[1 2 4:13 15:18 20:27 29:34 37:40 42:49];
% all_subs     = all_subs;

%DEBUG
% all_subs    = 1;


TR           = 1.991;
st_brain     = [1065.0 1007.5 952.5 895.0 840.0 785.0 727.5 672.5 615.0 560.0 505.0 447.5 392.5 335.0 280.0 225.0 167.5 112.5 55.0 0.0 1065.0 1007.5 952.5 895.0 840.0 785.0 727.5 672.5 615.0 560.0 505.0 447.5 392.5 335.0 280.0 225.0 167.5 112.5 55.0 0.0 1065.0 1007.5 952.5 895.0 840.0 785.0 727.5 672.5 615.0 560.0 505.0 447.5 392.5 335.0 280.0 225.0 167.5 112.5 55.0 0.0];
st_spinal    = [797.5 725.0 652.5 580.0 507.5 435.0 362.5 290.0 217.5 145.0 72.5 0.0];
transM       = [1 0 0 0;0 1 0 0;0 0 1 -100;0 0 0 1]; % shift T1 and all brain EPIs

skullstrip_name   = 'skull_strip.nii';
mean_func_name    = 'tmeanasub001-epi-run1-brain.nii';

all_wskull_files = [];
all_wmean_files  = [];
all_wc1_files    = [];
all_t2norm_files = [];
            
if size(all_subs) < n_proc
    n_proc = size(all_subs,2);
end

subs     = splitvect(all_subs, n_proc);
% spm_path = fileparts(which('spm')); %get spm path
% template_path = [spm_path filesep 'toolbox\cat12\templates_MNI152NLin2009cAsym' filesep];
template_path = [spm_path filesep 'toolbox\cat12\templates_MNI152_IXI555' filesep];
tpm_path = [spm_path filesep 'tpm' filesep];


for np = 1:size(subs,2)
    matlabbatch = [];
    gi   = 1;
    
    for g = 1:size(subs{np},2)
        %-------------------------------
        %House keeping stuff
        
        name          = sprintf('sub%0.3d',subs{np}(g));
        fprintf(['Doing volunteer ' name '\n']);
        st_dir        = [base_dir name filesep 't1_corrected' filesep];
        struc_file    = sprintf('%s-t1_corrected.nii',name);
        struc_file    = [st_dir struc_file];
 
        % check files and gunzip if necessary
        z = check_file(struc_file);
        if ~z
            fprintf('problem with %s\n',struc_file);
        end
        
        if do_shift
            check = nifti(struc_file);
            if sum(sum((check.mat-check.mat0).^2)) > 1e-3 %it seems the combined niftis have a diff of about1e-6
                fprintf('nifti.mat0 and niti.mat are very different, %s has already been processed - SKIP\n',struc_file);
            else
                MM = spm_get_space(struc_file);
                spm_get_space(struc_file,transM*MM);
            end
            
        end
        
        a    = dir([base_dir name filesep 'epi-run*']);
        epi_folders = cellstr(strvcat(a.name));
        
        for l=1:numel(epi_folders)
            func_name = sprintf('%s-epi-run%s-brain.nii',name,num2str(l));
            z = check_file([base_dir name filesep epi_folders{l} filesep func_name]);
            if ~z
                fprintf('problem with %s\n',[base_dir name filesep epi_folders{l} filesep func_name]);
            end
            epi_brain_files{l} = cellstr(spm_select('ExtFPListRec',[base_dir name filesep epi_folders{l}],['^' func_name '$'],Inf));
            
            % check and correct shift
            if do_shift
                [p n e] = fileparts(epi_brain_files{l}{1});
                check = nifti([p filesep n '.nii']);
                if isfield(check.extras,'mat')
                    fprintf('nifti.extras has .mat entry, %s has already been processed - SKIP\n',[p filesep n '.nii']);
                elseif sum(sum((check.mat-check.mat0).^2)) > 1e-3 %it seems the combined niftis have a diff of about1e-6
                    fprintf('nifti.mat0 and niti.mat are very different, %s has already been processed - SKIP\n',[p filesep n '.nii']);
                else
                    check.mat = transM*check.mat; % shift
                    create(check); % and write
                end
                
                %                 if exist([p filesep n '.mat'],'file')
                %                     fprintf('detected .mat file, %s has already been processed - SKIP\n',[p filesep n '.nii']);
                %                 else
                %                     MM = spm_get_space([p filesep n '.nii']);
                %                     spm_get_space([p filesep n '.nii'],transM*MM);
                %                 end
            end
            
            
            func_name = sprintf('%s-epi-run%s-spinal.nii',name,num2str(l));
            z = check_file([base_dir name filesep epi_folders{l} filesep func_name]);
            if ~z
                fprintf('problem with %s\n',[base_dir name filesep epi_folders{l} filesep func_name]);
            end
            epi_spinal_files{l} = cellstr(spm_select('ExtFPListRec',[base_dir name filesep epi_folders{l}],['^' func_name '$'],Inf));
            
        end
        
        
        m_dir           = [base_dir name filesep epi_folders{1}] ;
        mean_file       = sprintf('%smeana%s-epi-run%s-brain.nii',[m_dir filesep],name,'1');
        nlin_coreg_file = sprintf('%sy_meana%s-epi-run%s-brain.nii',[m_dir filesep],name,'1');
        c1_file         = ins_letter(struc_file,'c1');
        c2_file         = ins_letter(struc_file,'c2');
        c3_file         = ins_letter(struc_file,'c3');
        rc1_file        = ins_letter(struc_file,'rc1');
        rc2_file        = ins_letter(struc_file,'rc2');
        u_rc1_file      = ins_letter(struc_file,'u_rc1');
        strip_file      = [base_dir name filesep 't1_corrected' filesep skullstrip_name];
        
        
        %-------------------------------
        %Do Slice time correction spinal cord
        if do_sp_slicetime
            matlabbatch{gi}.spm.temporal.st.scans = epi_spinal_files';
            %%
            matlabbatch{gi}.spm.temporal.st.nslices = numel(st_spinal);
            matlabbatch{gi}.spm.temporal.st.tr = TR;
            matlabbatch{gi}.spm.temporal.st.ta = 0;
            matlabbatch{gi}.spm.temporal.st.so = st_spinal+max(st_brain)+100; %100 to account for the jump to spinal
            matlabbatch{gi}.spm.temporal.st.refslice = max(st_brain)+50; % right between spinal and brain
            matlabbatch{gi}.spm.temporal.st.prefix = 'a';
            gi = gi + 1;
            for l=1:numel(epi_folders)
                func_name = sprintf('%sa%s-epi-run%s-spinal.nii',[base_dir name filesep epi_folders{l} filesep],name,num2str(l));
                matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = func_name;
                matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.outputs = {};
                matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.fun = 'gzip'; %easier for SCT to have everything gzipped
                gi = gi + 1;
            end
        end
        %Do full preproc using SCT
        if do_sp_sct
            matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = base_dir;
            matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.inputs{2}.string = name;
            matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.outputs = {};
            matlabbatch{gi}.cfg_basicio.run_ops.call_matlab.fun = 'sct_fmri_T2'; %e
            gi = gi + 1;
        end
        
             
        %-------------------------------
        %Do Slice time correction
        if do_slicetime
            matlabbatch{gi}.spm.temporal.st.scans = epi_brain_files;
            %%
            matlabbatch{gi}.spm.temporal.st.nslices = numel(st_brain);
            matlabbatch{gi}.spm.temporal.st.tr = TR;
            matlabbatch{gi}.spm.temporal.st.ta = 0;
            matlabbatch{gi}.spm.temporal.st.so = st_brain;
            matlabbatch{gi}.spm.temporal.st.refslice = max(st_brain)+50; % is the last brain slice
            matlabbatch{gi}.spm.temporal.st.prefix = 'a';
            gi = gi + 1;
        end
        
        %-------------------------------
        %Do Realignment
        if do_realign
            for l=1:numel(epi_folders)
                a_epi_brain_files{l} = strrep(epi_brain_files{l},sprintf('%s-epi-run%s-brain.nii',name,num2str(l)),sprintf('a%s-epi-run%s-brain.nii',name,num2str(l)));
            end
            matlabbatch{gi}.spm.spatial.realign.estwrite.data             = a_epi_brain_files;
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.sep     = 4;
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.fwhm    = 5;
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.rtm     = 1;
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.interp  = 2;
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.wrap    = [0 0 0];
            matlabbatch{gi}.spm.spatial.realign.estwrite.eoptions.weight  = '';
            matlabbatch{gi}.spm.spatial.realign.estwrite.roptions.which   = [2 1];
            matlabbatch{gi}.spm.spatial.realign.estwrite.roptions.interp  = 4;
            matlabbatch{gi}.spm.spatial.realign.estwrite.roptions.wrap    = [0 0 0];
            matlabbatch{gi}.spm.spatial.realign.estwrite.roptions.mask    = 1;
            matlabbatch{gi}.spm.spatial.realign.estwrite.roptions.prefix  = 'r';
            gi = gi + 1;
        end
        %save('realign.mat','matlabbatch');
        
        %-------------------------------
        %Do nonlin Coregistration mean rfMRI to T1
        if do_nonlincoreg
            matlabbatch{gi}.spm.tools.cat.tools.nonlin_coreg.ref = cellstr(struc_file);
            matlabbatch{gi}.spm.tools.cat.tools.nonlin_coreg.source = cellstr(mean_file);
            matlabbatch{gi}.spm.tools.cat.tools.nonlin_coreg.other = cellstr(mean_file);
            matlabbatch{gi}.spm.tools.cat.tools.nonlin_coreg.reg = 1;
            matlabbatch{gi}.spm.tools.cat.tools.nonlin_coreg.bb = [NaN NaN NaN
                NaN NaN NaN];
            matlabbatch{gi}.spm.tools.cat.tools.nonlin_coreg.vox = [1.5 1.5 1.5];
            gi = gi + 1;
        end
        %-------------------------------
        %Do Segmentation
        if do_seg
            matlabbatch{gi}.spm.spatial.preproc.channel.vols     = cellstr(struc_file);
            matlabbatch{gi}.spm.spatial.preproc.channel.biasreg  = 0.001;
            matlabbatch{gi}.spm.spatial.preproc.channel.biasfwhm = 60;
            matlabbatch{gi}.spm.spatial.preproc.channel.write    = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(1).tpm    = {[tpm_path 'enhanced_TPM.nii,1']};
            matlabbatch{gi}.spm.spatial.preproc.tissue(1).ngaus  = 2; %LOrio ... Draganski et al. NI2016
            matlabbatch{gi}.spm.spatial.preproc.tissue(1).native = [1 1];
            matlabbatch{gi}.spm.spatial.preproc.tissue(1).warped = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(2).tpm    = {[tpm_path 'enhanced_TPM.nii,2']};
            matlabbatch{gi}.spm.spatial.preproc.tissue(2).ngaus  = 1;
            matlabbatch{gi}.spm.spatial.preproc.tissue(2).native = [1 1];
            matlabbatch{gi}.spm.spatial.preproc.tissue(2).warped = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(3).tpm    = {[tpm_path 'enhanced_TPM.nii,3']};
            matlabbatch{gi}.spm.spatial.preproc.tissue(3).ngaus  = 2;
            matlabbatch{gi}.spm.spatial.preproc.tissue(3).native = [1 1];
            matlabbatch{gi}.spm.spatial.preproc.tissue(3).warped = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(4).tpm    = {[tpm_path 'enhanced_TPM.nii,4']};
            matlabbatch{gi}.spm.spatial.preproc.tissue(4).ngaus  = 3;
            matlabbatch{gi}.spm.spatial.preproc.tissue(4).native = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(4).warped = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(5).tpm    = {[tpm_path 'enhanced_TPM.nii,5']};
            matlabbatch{gi}.spm.spatial.preproc.tissue(5).ngaus  = 4;
            matlabbatch{gi}.spm.spatial.preproc.tissue(5).native = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(5).warped = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(6).tpm    = {[tpm_path 'enhanced_TPM.nii,6']};
            matlabbatch{gi}.spm.spatial.preproc.tissue(6).ngaus  = 2;
            matlabbatch{gi}.spm.spatial.preproc.tissue(6).native = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.tissue(6).warped = [0 0];
            matlabbatch{gi}.spm.spatial.preproc.warp.mrf         = 1;
            matlabbatch{gi}.spm.spatial.preproc.warp.cleanup     = 1;
            matlabbatch{gi}.spm.spatial.preproc.warp.reg         = [0 0.001 0.5 0.05 0.2];
            matlabbatch{gi}.spm.spatial.preproc.warp.affreg      = 'mni';
            matlabbatch{gi}.spm.spatial.preproc.warp.fwhm        = 0;
            matlabbatch{gi}.spm.spatial.preproc.warp.samp        = 3;
            matlabbatch{gi}.spm.spatial.preproc.warp.write       = [0 0];
            gi = gi + 1;
        end
        
        %-------------------------------
        %Do skull strip
        if do_skull
            Vfnames      = strvcat(struc_file,c1_file,c2_file);
            matlabbatch{gi}.spm.util.imcalc.input            = cellstr(Vfnames);
            matlabbatch{gi}.spm.util.imcalc.output           = skullstrip_name;
            matlabbatch{gi}.spm.util.imcalc.outdir           = {st_dir};
            matlabbatch{gi}.spm.util.imcalc.expression       = 'i1.*((i2+i3)>0.2)';
            matlabbatch{gi}.spm.util.imcalc.options.dmtx     = 0;
            matlabbatch{gi}.spm.util.imcalc.options.mask     = 0;
            matlabbatch{gi}.spm.util.imcalc.options.interp   = 1;
            matlabbatch{gi}.spm.util.imcalc.options.dtype    = 4;
            gi = gi + 1;
        end
        %-------------------------------
        %Dartel norm to template
        if do_norm
            matlabbatch{gi}.spm.tools.dartel.warp1.images = {cellstr(rc1_file),cellstr(rc2_file)};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.rform = 0;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(1).its = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(1).rparam = [4 2 1e-06];
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(1).K = 0;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(1).template = {[template_path 'Template_1_IXI555_MNI152.nii']};
%             matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(1).template = {[template_path 'Template_1_Dartel.nii']};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(2).its = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(2).rparam = [2 1 1e-06];
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(2).K = 0;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(2).template = {[template_path 'Template_2_IXI555_MNI152.nii']};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(3).its = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(3).rparam = [1 0.5 1e-06];
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(3).K = 1;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(3).template = {[template_path 'Template_3_IXI555_MNI152.nii']};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(4).its = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(4).rparam = [0.5 0.25 1e-06];
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(4).K = 2;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(4).template = {[template_path 'Template_4_IXI555_MNI152.nii']};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(5).its = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(5).rparam = [0.25 0.125 1e-06];
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(5).K = 4;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(5).template = {[template_path 'Template_5_IXI555_MNI152.nii']};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(6).its = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(6).rparam = [0.25 0.125 1e-06];
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(6).K = 6;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.param(6).template = {[template_path 'Template_6_IXI555_MNI152.nii']};
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.optim.lmreg = 0.01;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.optim.cyc = 3;
            matlabbatch{gi}.spm.tools.dartel.warp1.settings.optim.its = 3;
            gi = gi + 1;
        end
        %-------------------------------
        %Get backwards deformations
        if do_back
            matlabbatch{gi}.spm.util.defs.comp{1}.dartel.flowfield = {u_rc1_file};
            matlabbatch{gi}.spm.util.defs.comp{1}.dartel.times     = [1 0];
            matlabbatch{gi}.spm.util.defs.comp{1}.dartel.K         = 6;
            matlabbatch{gi}.spm.util.defs.comp{1}.dartel.template  = {''};
            matlabbatch{gi}.spm.util.defs.out{1}.savedef.ofname    = 'backwards';
            matlabbatch{gi}.spm.util.defs.out{1}.savedef.savedir.saveusr = {st_dir};
            gi = gi + 1;
        end
        
        %-------------------------------
        %Combine nonlinear coreg with dartel flow field
        if do_comb_dar_nlin
            %combine nonlin coreg with Dartel (EPI --> T1 --> Template): FORWARD
            matlabbatch{gi}.spm.util.defs.comp{1}.def = cellstr(nlin_coreg_file);
            matlabbatch{gi}.spm.util.defs.comp{2}.dartel.flowfield = cellstr(u_rc1_file);
            matlabbatch{gi}.spm.util.defs.comp{2}.dartel.times = [1 0];
            matlabbatch{gi}.spm.util.defs.comp{2}.dartel.K = 6;
            matlabbatch{gi}.spm.util.defs.comp{2}.dartel.template = {''};
            matlabbatch{gi}.spm.util.defs.out{1}.savedef.ofname = 'epi_2_template';
            matlabbatch{gi}.spm.util.defs.out{1}.savedef.savedir.saveusr = cellstr(m_dir);
            gi = gi + 1;
            % and back
            %get the backwards transformation (Template --> EPI)
            matlabbatch{gi}.spm.util.defs.comp{1}.inv.comp{1}.def = {[m_dir filesep 'y_epi_2_template.nii']};
            matlabbatch{gi}.spm.util.defs.comp{1}.inv.space = {[template_path 'Template_T1_IXI555_MNI152_GS.nii']};
%             matlabbatch{gi}.spm.util.defs.comp{1}.inv.space = {[template_path 'Template_T1.nii']}; % checked the correspondence to the new names from the CAT12 manual
            matlabbatch{gi}.spm.util.defs.out{1}.savedef.ofname = 'inv_epi_2_template';
            matlabbatch{gi}.spm.util.defs.out{1}.savedef.savedir.saveusr = cellstr(m_dir);
            gi = gi + 1;
        end
        
        %-------------------------------
        %Get reverse transformed T1 to mean EPI
        if do_nlin_reverse
            matlabbatch{gi}.spm.util.defs.comp{1}.def = cellstr(nlin_coreg_file);
            matlabbatch{gi}.spm.util.defs.out{1}.push.fnames = {c1_file}';
%             matlabbatch{gi}.spm.util.defs.out{1}.push.fnames = {c1_file c2_file c3_file}';
            matlabbatch{gi}.spm.util.defs.out{1}.push.weight = {''};
            matlabbatch{gi}.spm.util.defs.out{1}.push.savedir.savesrc = 1;
            matlabbatch{gi}.spm.util.defs.out{1}.push.fov.file = cellstr(mean_file);
            matlabbatch{gi}.spm.util.defs.out{1}.push.preserve = 0;
            matlabbatch{gi}.spm.util.defs.out{1}.push.fwhm = [0 0 0];
            matlabbatch{gi}.spm.util.defs.out{1}.push.prefix = 'inv_nlin_';
            gi = gi + 1;
        end
        %-------------------------------
        %Create warped T1 and mean EPI
        if do_warp
            matlabbatch{gi}.spm.tools.dartel.crt_warped.flowfields = cellstr(strvcat(u_rc1_file,u_rc1_file,u_rc1_file));
            matlabbatch{gi}.spm.tools.dartel.crt_warped.images = {cellstr(strvcat(strip_file,c1_file,c2_file))};
            matlabbatch{gi}.spm.tools.dartel.crt_warped.jactransf = 0;
            matlabbatch{gi}.spm.tools.dartel.crt_warped.K = 6;
            matlabbatch{gi}.spm.tools.dartel.crt_warped.interp = 1;
            gi = gi + 1;
            matlabbatch{gi}.spm.util.defs.comp{1}.def = {[m_dir filesep 'y_epi_2_template.nii']};
            matlabbatch{gi}.spm.util.defs.out{1}.pull.fnames = cellstr(mean_file);
            matlabbatch{gi}.spm.util.defs.out{1}.pull.savedir.savesrc = 1;
            matlabbatch{gi}.spm.util.defs.out{1}.pull.interp = 4;
            matlabbatch{gi}.spm.util.defs.out{1}.pull.mask = 1;
            matlabbatch{gi}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
            matlabbatch{gi}.spm.util.defs.out{1}.pull.prefix = 'wt';
            gi = gi + 1;
        end
        %-------------------------------
        %Create smoothed skullstrip
        if do_sm_skull
            skern = 3;
            matlabbatch{gi}.spm.spatial.smooth.data   = cellstr(strip_file);
            matlabbatch{gi}.spm.spatial.smooth.fwhm   = repmat(skern,1,3);
            matlabbatch{gi}.spm.spatial.smooth.prefix = ['s' num2str(skern)];
            gi = gi + 1;
        end
        
        if do_avg_norm
            
            wskull_file     = ins_letter(strip_file,'w');
            wmean_file      = ins_letter(mean_file,'wt');
            wc1_file        = ins_letter(struc_file,'wc1');
            
            all_wskull_files  = strvcat(all_wskull_files,wskull_file);
            all_wmean_files   = strvcat(all_wmean_files,wmean_file);
            all_wc1_files     = strvcat(all_wc1_files,wc1_file);
            
        end
        
    end
    
    if ~isempty(matlabbatch)
        if parallel
            run_matlab(np, matlabbatch, l_string);
        else
            spm_jobman('initcfg');
            spm('defaults', 'FMRI');
            spm_jobman('run',matlabbatch);
        end
    end
end

if do_avg_norm
  
    clear matlabbatch
    
    if spinal
        
        for s = 1:numel(all_subs)
            name           = sprintf('sub%0.3d',all_subs(s));
            t2_dir         = [base_dir name filesep 't2_spinalcord' filesep];
            t2norm_file    = 't2_norm_cropped.nii';%sprintf('%s-t2_norm_cropped.nii',name);
            t2norm_file    = [t2_dir t2norm_file];
            all_t2norm_files  = strvcat(all_t2norm_files,t2norm_file);
        end
        
        input_files = all_t2norm_files;
        output_file = 'mean_t2norm';
    else
        input_files = all_wskull_files;
        output_file = 'mean_wskull';
    end
    matlabbatch{1}.spm.util.imcalc.input = cellstr(input_files);
    matlabbatch{1}.spm.util.imcalc.output = output_file;
    matlabbatch{1}.spm.util.imcalc.outdir = cellstr(fullfile(base_dir,'2ndlevel','meanmasks'));
    matlabbatch{1}.spm.util.imcalc.expression = 'mean(X)';
    matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
    matlabbatch{1}.spm.util.imcalc.options.mask = 0;
    matlabbatch{1}.spm.util.imcalc.options.interp = 1;
    matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

%     matlabbatch{2} = matlabbatch{1};
%     matlabbatch{2}.spm.util.imcalc.input = cellstr(all_wmean_files);
%     matlabbatch{2}.spm.util.imcalc.output = 'mean_wmean';
%     
%     matlabbatch{3} = matlabbatch{1};
%     matlabbatch{3}.spm.util.imcalc.input = cellstr(all_wc1_files);
%     matlabbatch{3}.spm.util.imcalc.output = 'mean_wc1';
    
    spm_jobman('initcfg');
    spm_jobman('run',matlabbatch);
    
end

function chuckCell = splitvect(v, n)
% Splits a vector into number of n chunks of  the same size (if possible).
% In not possible the chunks are almost of equal size.
%
% based on http://code.activestate.com/recipes/425044/
chuckCell  = {};
vectLength = numel(v);
splitsize  = 1/n*vectLength;
for i = 1:n
    idxs = [floor(round((i-1)*splitsize)):floor(round((i)*splitsize))-1]+1;
    chuckCell{end + 1} = v(idxs);
end

function out = exist_mat(fname) %see whether .mat file exists
[p n e] = fileparts(fname)
new = [p filesep n '.mat'];
if exist(new,'file')
    out = 1;
else
    out = 0;
end


function res = check_file(fname)
if ~exist(fname,'file')
    if exist([fname '.gz'],'file')
        gunzip([fname '.gz']);
        res = 2;
    else
        res = 0; %neither gzip nor plain exist
    end
else
    res = 1;
end


function f_files = create_func_files(s_dir,f_templ,n_files)
for i=1:n_files
    f_files{i} = [s_dir filesep f_templ ',' num2str(i)];
end


function out = ins_letter(pscan,letter_start,letter_end)
if nargin <3
    letter_end = [];
end
for a=1:size(pscan,1)
    [p , f, e] = fileparts(pscan(a,:));
    out(a,:) = [p filesep letter_start f letter_end e];
end

function run_matlab(np, matlabbatch, l_string)

spm_path          = fileparts(which('spm')); %get spm path
mat_name          = which(mfilename);
[~,mat_name,~]    = fileparts(mat_name);

hostname          = char(getHostName(java.net.InetAddress.getLocalHost));
mat_name          = [mat_name '_' hostname];

fname = [num2str(np) '_' mat_name '.mat'];

save([num2str(np) '_' mat_name],'matlabbatch');
lo_cmd  = ['clear matlabbatch;load(''' fname ''');'];
ex_cmd = ['addpath(''' spm_path ''');addpath(''c:\Users\ojala\Documents\MATLAB\'');spm(''defaults'',''FMRI'');spm_jobman(''initcfg'');spm_jobman(''run'',matlabbatch);'];
end_cmd = [' delete(''' fname ''');exit'];
system(['start matlab.exe ' l_string ' -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r "' lo_cmd ex_cmd end_cmd]);


% FIX this!!!!
% function run_matlab(np, matlabbatch, check)
%
% spm_path          = fileparts(which('spm')); %get spm path
% mat_name          = which(mfilename);
% [~,mat_name,~]    = fileparts(mat_name);
%
% fname = [num2str(np) '_' mat_name '.mat'];
%
% save([num2str(np) '_' mat_name],'matlabbatch');
% lo_cmd  = sprintf('clear matlabbatch;load(''''%s'''');',fname);
% ex_cmd  = sprintf('addpath(''''%s'''');spm(''defaults'',''FMRI'');spm_jobman(''initcfg'');spm_jobman(''run'',matlabbatch);',spm_path);
% end_cmd = sprintf('delete(''''%s'''');',fname);
% if ~check
%     if ispc
%     system(['start matlab.exe -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r "' lo_cmd ex_cmd end_cmd 'exit"']);
%     else %unix
%     system(['gnome-terminal -e ''' fullfile(matlabroot) '/bin/matlab -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r "' lo_cmd ex_cmd end_cmd 'exit"' '&']);
%     system(['gnome-terminal -e ''' fullfile(matlabroot) '/bin/matlab -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r ""']);
%     end
% end
%