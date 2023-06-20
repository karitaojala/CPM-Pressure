function roi_extract_parameters_beta(options,analysis_version,model,contrasts,rois)

for con = contrasts
    
    contrast_name = model.congroups_2ndlvl.names_cons{con};
    SPMpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,char(model.congroups_2ndlvl.names),contrast_name);
    SPMfile = fullfile(SPMpath,'SPM.mat');
    
    roipath = fullfile(options.path.mridir,'2ndlevel','roimasks','final');
    
    for roi = rois
        
        roi_file = fullfile(roipath,[options.stats.secondlvl.roi.names{roi} '.nii']);
        SPM = load(SPMfile);
        SPM = SPM.SPM;
        
        % Make marsbar design object
        D  = mardo(SPM);
        % Make marsbar ROI object
        R  = maroi_image(roi_file);
        %o = maroi('load', R);
        % Fetch data into marsbar data object
        Y  = get_marsy(R, D, 'mean');
        % Get contrasts from original design
        xCon = get_contrasts(D);
        % Estimate design on ROI data
        E = estimate(D, Y);
        % Put contrasts from original design back into design object
        E = set_contrasts(E, xCon);
        % get design betas
        b = betas(E);
        % get stats and stuff for all contrasts into statistics structure
        marsS = compute_contrasts(E, 1:length(xCon));
        
    end
    
end