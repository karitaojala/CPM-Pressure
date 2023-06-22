function ppi_wrapper(options,analysis_version,model,rois,subj)

ppipath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'PPI');
if ~exist(ppipath,'dir'); mkdir(ppipath); end

for sub = subj
    
    clear matlabbatch

    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    if options.spinal
        firstlvlpath = [firstlvlpath '_32motion']; %#ok<AGROW> % add to 1st level name
    end
    SPMfile = fullfile(firstlvlpath,'SPM.mat');
    
    add_ppi_contrast(SPMfile) % Add F-contrast over all effects of interest for PPI
    SPM = load(SPMfile);
    
    roipath = fullfile(options.path.mridir,'2ndlevel','roimasks','final','PPI');
    
    for roi = 1:numel(rois)
        
        if options.spinal % spinal ROI seeds for brain analysis
            
            roi_name = options.stats.firstlevel.ppi.brain.roi_names{rois(roi)};
            xY(roi).def  = 'sphere';
            xY(roi).xyz  = options.stats.firstlevel.ppi.brain.roi_coords(rois(roi),:)';
            xY(roi).spec = options.stats.firstlevel.ppi.brain.roi_sphere_radius;
            xY(roi).rad  = options.stats.firstlevel.ppi.brain.roi_search_radius;
            xY(roi).str  = roi_name;
            xY(roi).Ic   = numel(SPM.SPM.xCon); % F-contrast number -> last one
            xY(roi).T    = options.stats.firstlevel.ppi.brain.roi_Tcons(rois(roi)); % Contrast number for effect of interest
            
        else % brain ROI seeds for spinal analysis
            
            roi_name = options.stats.firstlevel.ppi.spinal.roi_names{rois(roi)};
            roi_file = fullfile(roipath,[roi_name '.nii']);
            
            xY(roi).name = strrep(roi_name,'_',' ');
            xY(roi).str  = roi_name;
            %xY(roi).ind  = ;
            xY(roi).spec = roi_file;
            xY(roi).def  = 'mask';
            xY(roi).xyz  = Inf;
            xY(roi).Ic   = numel(SPM.SPM.xCon); % F-contrast number -> last one
            
        end
        
    end
    
    Uu = [];
    no_cond = 5; % Tonic CON, Tonic EXP, Phasic CON, Phasic EXP, VAS
    cond2excl = 1;
    temp = eye(no_cond-cond2excl);
    for tt = 1:size(temp,1)
        Uu{tt} = [[1:no_cond]' ones(no_cond,1) [temp(tt,:)'; zeros(cond2excl,1)]];
    end
    % But how does this work when each PPI should have 2 conditions: CON
    % and EXP? OR extracted separately but then put together in the 1st
    % level SPM?
    
    if options.spinal
        meanepi = fullfile(options.path.mridir,name,'epi-run2',['a' name '-epi-run2-spinal_moco_norm_cropped.nii']);
        epi2template = '';
        %meanepi = fullfile(epipath,'spinal_moco_mean_norm.nii'); 
        %epi2template = fullfile(epipath,'warp_t22epi.nii'); %??? warp epi to template
    else
        meanepi = fullfile(options.path.mridir,name,'epi-run1',['wtmeana' name '-epi-run1-brain.nii']);
        epi2template = fullfile(options.path.mridir,name,'epi-run1','y_epi_2_template.nii');
    end
    
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{1}.string    = SPMfile;
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{2}.string    = meanepi;
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{3}.string    = epi2template;
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{4}.evaluated = options.stats.firstlevel.ppi.smooth_kernel;
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{5}.evaluated = xY;
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{6}.evaluated = Uu;
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{7}.evaluated = fullfile(ppipath,[name '-' options.volume_name '_ppi_roi_']);
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.outputs = {};
    matlabbatch{1}.cfg_basicio.run_ops.call_matlab.fun = 'get_roi_ts';
    
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    
end


end