function roi_extract_timecourses(options,analysis_version,model,contrasts,rois,subj)

marsbar('on')

for con = contrasts
    
    contrast_name = options.stats.firstlvl.contrasts.names.tonic_concat{con};
    
    for sub = subj
        
        name = sprintf('sub%03d',sub);
        disp(name);
        
        SPMpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
        SPMfile = fullfile(SPMpath,'SPM.mat');
        
        roipath = fullfile(options.path.mridir,'2ndlevel','roimasks','final');
        
        for roi = rois
            
            roi_file = fullfile(roipath,[options.stats.secondlvl.roi.names{roi} '.nii']);
            
            roi_files = spm_get(Inf,'*roi.mat', 'Select ROI files');
            des_path = spm_get(1, 'SPM.mat', 'Select SPM.mat');
            rois = maroi('load_cell', roi_files); % make maroi ROI objects
            des = mardo(des_path);  % make mardo design object
            mY = get_marsy(rois{:}, des, 'mean'); % extract data into marsy data object
            y  = summary_data(mY);  % get summary time course(s)
            
        end
        
    end
    
end