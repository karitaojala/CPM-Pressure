function roi_extract_parameters(options,analysis_version,model,contrasts,roitype,rois,seeds,subj)

addpath(options.path.marsbardir)
marsbar('on')

roipath = fullfile(options.path.mridir,'2ndlevel','roimasks','final',roitype);

for seed = seeds % for PPI, to differentiate from anatomical ROIs
    
    if any(seeds) && options.spinal
        seed_name = options.stats.firstlvl.ppi.spinal.roi_names{seed};
    elseif any(seeds) && ~options.spinal
        seed_name = options.stats.firstlvl.ppi.brain.roi_names{seed};
    else
        seed_name = [];
    end
    
    for con = contrasts
        
        contrast_name = model.congroups_2ndlvl.names_cons{con};
        SPMpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,char(model.congroups_2ndlvl.names),seed_name,contrast_name);
        SPMfile = fullfile(SPMpath,'SPM.mat');
        
        roiresultpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'ROI');
        if ~exist(roiresultpath,'dir'); mkdir(roiresultpath); end
        
        for roi = rois
            
            clear data
            
            roi_name = options.stats.secondlvl.roi.names{roi};
            roi_file = fullfile(roipath,[roi_name '.nii']);
            if options.spinal
                oldSPM = load(SPMfile);
                %old_fdir = oldSPM.SPM.swd;
                old_fdir = oldSPM.SPM.xY.P{1};
                new_fdir = options.path.mridir;
                if ~strncmp(old_fdir,new_fdir,length(new_fdir))
                    change_spm_path(SPMfile, old_fdir, new_fdir)
                end
            end
            marsSPM = load(SPMfile);
            marsSPM = marsSPM.SPM;
            
            % Make marsbar design object
            D  = mardo(marsSPM);
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
            %marsS = compute_contrasts(E, 1:length(xCon));
            % get all betas
            marsSPM = des_struct(E);
            sY = summary_data(marsSPM.marsY); % should be the same as mean(b)
            SE_within = std(sY)/sqrt(2*numel(subj)*(2-1));
            SE_between = std(sY)/sqrt(numel(subj));
            
            data.betas = sY;
            data.meanbeta = b;
            data.meanerror_within = SE_within;
            data.meanerror_between = SE_between;
            
            if isempty(seed_name)
                roiresultfile = fullfile(roiresultpath,['MeanBetas_' contrast_name seed_name '_' roi_name '.mat']);
            else
                roiresultfile = fullfile(roiresultpath,['MeanBetas_' contrast_name '_' seed_name '_' roi_name '.mat']);
            end
            save(roiresultfile,'data')
            
        end
        
    end
    
end