function tfce_wrapper(options,analysis_version,model,rois,contrasts)

%analysis = options.stats.secondlvl.tfce.analysis;
%tails = options.stats.secondlvl.tfce.tails;

for roi = rois
    
    if any(rois) && options.spinal
        roi_name = options.stats.firstlevel.ppi.spinal.roi_names{roi};
    elseif any(rois) && ~options.spinal
        roi_name = options.stats.firstlevel.ppi.brain.roi_names{roi};
    else
        roi_name = [];
    end
    
    if options.spinal
        volume_mask = fullfile(options.path.mridir,'2ndlevel','meanmasks','spinalmask_secondlevel_tfce.nii');
    else
        volume_mask = fullfile(options.path.mridir,'2ndlevel','meanmasks',options.stats.secondlvl.mask_name);
    end
    
    for con = contrasts
        
        %% Christian Gaser TFCE
        
        contrast_name = model.congroups_2ndlvl.names_cons{con};
        if model.PPI
            SPMpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,char(model.congroups_2ndlvl.names),roi_name,contrast_name);
        else
            SPMpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,char(model.congroups_2ndlvl.names),contrast_name);
        end
        SPMfile = fullfile(SPMpath,'SPM.mat');
        
        if options.spinal
            oldSPM = load(SPMfile);
            %old_fdir = oldSPM.SPM.swd;
            old_fdir = oldSPM.SPM.xY.P{1};
            new_fdir = options.path.mridir;
            if ~strncmp(old_fdir,new_fdir,length(new_fdir))
                change_spm_path(SPMfile, old_fdir, new_fdir)
            end
        end
        
        clear matlabbatch
        
        matlabbatch{1}.spm.tools.tfce_estimate.data = {SPMfile};
        matlabbatch{1}.spm.tools.tfce_estimate.nproc = 2;
        matlabbatch{1}.spm.tools.tfce_estimate.mask = {volume_mask};
        matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr = contrast_name;
        matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts = 1;
        matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm = options.stats.secondlvl.tfce.permutations;
        matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method = 2;
        matlabbatch{1}.spm.tools.tfce_estimate.tbss = 0;
        matlabbatch{1}.spm.tools.tfce_estimate.E_weight = 0.5;
        matlabbatch{1}.spm.tools.tfce_estimate.singlethreaded = 1;
        
        spm_jobman('run', matlabbatch);
        
        %% Other TFCE toolbox
        %     clear imgs Y pcorr
        
        %     subInd = 1;
        
        %     for sub = subj
        %
        %         name = sprintf('sub%03d',sub);
        %         disp(name);
        %
        %         firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
        %         if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
        %
        %         confile = char(fullfile(firstlvlpath, sprintf('s_w_nlco_dartel_con_00%02d.nii',con)));
        %
        %         V = spm_vol(confile);
        %         Y = spm_read_vols(V,1); % Y is 4D matrix of image data
        %         imgs(:,:,:,subInd) = Y;
        %
        %         subInd = subInd + 1;
        %
        % %     end
        %
        %     tfce_results_dir = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'TFCE_test');
        %     if ~exist(tfce_results_dir,'dir'); mkdir(tfce_results_dir); end
        %
        %     conname = options.stats.firstlvl.contrasts.names.tonic_concat{con};
        %     tfce_results_file_mat = fullfile(tfce_results_dir,[conname '.mat']);
        %     tfce_results_file_nii = fullfile(tfce_results_dir,[conname '.nii']);
        %
        %     if tails == 1 % 1-tailed
        %         [pcorr] = matlab_tfce(analysis,tails,imgs,[]);
        %         save(tfce_results_file_mat,'pcorr')
        %         V.fname = tfce_results_file_nii;
        %         spm_write_vol(V,pcorr);
        %     else % 2-tailed -> 2 images
        %         [pcorr_pos,pcorr_neg] = matlab_tfce(analysis,tails,imgs,[]);
        %         save(tfce_results_file_mat,'pcorr_pos','pcorr_neg')
        %         V.fname = tfce_results_file_nii;
        %         spm_write_vol(V,pcorr_pos);
        %         V.fname = [tfce_results_file_nii(1:end-4) '-1' tfce_results_file_nii(end-3:end)];
        %         spm_write_vol(V,pcorr_neg);
        %     end
        
    end
    
end

end