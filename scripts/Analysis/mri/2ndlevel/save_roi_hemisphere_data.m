function save_roi_hemisphere_data(options,analysis_version,model,rois)

roiresultpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'ROI');

roiInd = 1;

for roi = rois % Loop over ROIs
    
    roi_name = options.stats.secondlvl.roi.names{roi}; % ROI name
    
    contrast_names = options.stats.firstlvl.contrasts.names.tonic_concat;
    
    roifile_TC = fullfile(roiresultpath,['MeanBetas_' contrast_names{1} '_' roi_name '.mat']); % Tonic Control
    roifile_TE = fullfile(roiresultpath,['MeanBetas_' contrast_names{2} '_' roi_name '.mat']); % Tonic EroiNoperimental
    roifile_PC = fullfile(roiresultpath,['MeanBetas_' contrast_names{13} '_' roi_name '.mat']); % Phasic Control
    roifile_PE = fullfile(roiresultpath,['MeanBetas_' contrast_names{14} '_' roi_name '.mat']); % Phasic EroiNoperimental
    roifile_PiC = fullfile(roiresultpath,['MeanBetas_' contrast_names{17} '_' roi_name '.mat']); % Phasic InderoiNo Control
    roifile_PiE = fullfile(roiresultpath,['MeanBetas_' contrast_names{18} '_' roi_name '.mat']); % Phasic InderoiNo EroiNoperimental
   
    contrast_files = {roifile_TC roifile_TE roifile_PC roifile_PE roifile_PiC roifile_PiE};
    
    for con = 1:numel(contrast_files)
        
        data = load(contrast_files{con});
        data = data.data;
        
        allbetas(roiInd,con,:) = data.betas;
        roinames{roiInd} = roi_name; % EroiNotract ROI names for the current ROIs
        
    end
    
    roiInd = roiInd + 1;
    
end

if options.spinal
    
    % Dorsal horn spinal level 5
    roiNo = find(strcmp(roinames,'DorsalHorn_level_5_L'));
    TonicCON_DH5_L = squeeze(allbetas(roiNo,1,:));
    TonicEXP_DH5_L = squeeze(allbetas(roiNo,2,:));
    PhasicCON_DH5_L = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_DH5_L = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_DH5_L = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_DH5_L = squeeze(allbetas(roiNo,6,:));
    
    roiNo = find(strcmp(roinames,'DorsalHorn_level_5_R'));
    TonicCON_DH5_R = squeeze(allbetas(roiNo,1,:));
    TonicEXP_DH5_R = squeeze(allbetas(roiNo,2,:));
    PhasicCON_DH5_R = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_DH5_R = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_DH5_R = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_DH5_R = squeeze(allbetas(roiNo,6,:));
    
    % Dorsal horn spinal level 6
    roiNo = find(strcmp(roinames,'DorsalHorn_level_6_L'));
    TonicCON_DH6_L = squeeze(allbetas(roiNo,1,:));
    TonicEXP_DH6_L = squeeze(allbetas(roiNo,2,:));
    PhasicCON_DH6_L = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_DH6_L = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_DH6_L = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_DH6_L = squeeze(allbetas(roiNo,6,:));
    
    roiNo = find(strcmp(roinames,'DorsalHorn_level_6_R'));
    TonicCON_DH6_R = squeeze(allbetas(roiNo,1,:));
    TonicEXP_DH6_R = squeeze(allbetas(roiNo,2,:));
    PhasicCON_DH6_R = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_DH6_R = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_DH6_R = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_DH6_R = squeeze(allbetas(roiNo,6,:));
    
    % Dorsal horn spinal level 7
    roiNo = find(strcmp(roinames,'DorsalHorn_level_7_L'));
    TonicCON_DH7_L = squeeze(allbetas(roiNo,1,:));
    TonicEXP_DH7_L = squeeze(allbetas(roiNo,2,:));
    PhasicCON_DH7_L = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_DH7_L = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_DH7_L = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_DH7_L = squeeze(allbetas(roiNo,6,:));
    
    roiNo = find(strcmp(roinames,'DorsalHorn_level_7_R'));
    TonicCON_DH7_R = squeeze(allbetas(roiNo,1,:));
    TonicEXP_DH7_R = squeeze(allbetas(roiNo,2,:));
    PhasicCON_DH7_R = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_DH7_R = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_DH7_R = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_DH7_R = squeeze(allbetas(roiNo,6,:));
    
    % Save data by contrast group
    TonicOnset = table(TonicCON_DH5_L,TonicEXP_DH5_L,TonicCON_DH5_R,TonicEXP_DH5_R,...
        TonicCON_DH6_L,TonicEXP_DH6_L,TonicCON_DH6_R,TonicEXP_DH6_R,...
        TonicCON_DH7_L,TonicEXP_DH7_L,TonicCON_DH7_R,TonicEXP_DH7_R);
    
    PhasicOnset = table(PhasicCON_DH5_L,PhasicEXP_DH5_L,PhasicCON_DH5_R,PhasicEXP_DH5_R,...
        PhasicCON_DH6_L,PhasicEXP_DH6_L,PhasicCON_DH6_R,PhasicEXP_DH6_R,...
        PhasicCON_DH7_L,PhasicEXP_DH7_L,PhasicCON_DH7_R,PhasicEXP_DH7_R);
    
    PhasicIndex = table(PhasicIndCON_DH5_L,PhasicIndEXP_DH5_L,PhasicIndCON_DH5_R,PhasicIndEXP_DH5_R,...
        PhasicIndCON_DH6_L,PhasicIndEXP_DH6_L,PhasicIndCON_DH6_R,PhasicIndEXP_DH6_R,...
        PhasicIndCON_DH7_L,PhasicIndEXP_DH7_L,PhasicIndCON_DH7_R,PhasicIndEXP_DH7_R);
    
    tonic_table_file = fullfile(roiresultpath,'TonicOnset-CON-EXP_DH5-6-7_hemispheres.csv');
    phasic_table_file = fullfile(roiresultpath,'PhasicOnset-CON-EXP_DH5-6-7_hemispheres.csv');
    phasicind_table_file = fullfile(roiresultpath,'PhasicIndex-CON-EXP_DH5-6-7_hemispheres.csv');
    
else
    
    % Posterior insula
    roiNo = find(strcmp(roinames,'PosteriorInsula_L'));
    TonicCON_PIns_L = squeeze(allbetas(roiNo,1,:));
    TonicEXP_PIns_L = squeeze(allbetas(roiNo,2,:));
    PhasicCON_PIns_L = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_PIns_L = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_PIns_L = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_PIns_L = squeeze(allbetas(roiNo,6,:));
    
    roiNo = find(strcmp(roinames,'PosteriorInsula_R'));
    TonicCON_PIns_R = squeeze(allbetas(roiNo,1,:));
    TonicEXP_PIns_R = squeeze(allbetas(roiNo,2,:));
    PhasicCON_PIns_R = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_PIns_R = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_PIns_R = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_PIns_R = squeeze(allbetas(roiNo,6,:));
    
    % Anterior insula
    roiNo = find(strcmp(roinames,'AnteriorInsula_L'));
    TonicCON_AIns_L = squeeze(allbetas(roiNo,1,:));
    TonicEXP_AIns_L = squeeze(allbetas(roiNo,2,:));
    PhasicCON_AIns_L = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_AIns_L = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_AIns_L = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_AIns_L = squeeze(allbetas(roiNo,6,:));
    
    roiNo = find(strcmp(roinames,'AnteriorInsula_R'));
    TonicCON_AIns_R = squeeze(allbetas(roiNo,1,:));
    TonicEXP_AIns_R = squeeze(allbetas(roiNo,2,:));
    PhasicCON_AIns_R = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_AIns_R = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_AIns_R = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_AIns_R = squeeze(allbetas(roiNo,6,:));
    
    % Parietal operculum
    roiNo = find(strcmp(roinames,'ParietalOperculum_L'));
    TonicCON_POperc_L = squeeze(allbetas(roiNo,1,:));
    TonicEXP_POperc_L = squeeze(allbetas(roiNo,2,:));
    PhasicCON_POperc_L = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_POperc_L = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_POperc_L = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_POperc_L = squeeze(allbetas(roiNo,6,:));
    
    roiNo = find(strcmp(roinames,'ParietalOperculum_R'));
    TonicCON_POperc_R = squeeze(allbetas(roiNo,1,:));
    TonicEXP_POperc_R = squeeze(allbetas(roiNo,2,:));
    PhasicCON_POperc_R = squeeze(allbetas(roiNo,3,:));
    PhasicEXP_POperc_R = squeeze(allbetas(roiNo,4,:));
    PhasicIndCON_POperc_R = squeeze(allbetas(roiNo,5,:));
    PhasicIndEXP_POperc_R = squeeze(allbetas(roiNo,6,:));
    
    % Save data by contrast group
    TonicOnset = table(TonicCON_PIns_L,TonicEXP_PIns_L,TonicCON_PIns_R,TonicEXP_PIns_R,...
        TonicCON_AIns_L,TonicEXP_AIns_L,TonicCON_AIns_R,TonicEXP_AIns_R,...
        TonicCON_POperc_L,TonicEXP_POperc_L,TonicCON_POperc_R,TonicEXP_POperc_R);
    
    PhasicOnset = table(PhasicCON_PIns_L,PhasicEXP_PIns_L,PhasicCON_PIns_R,PhasicEXP_PIns_R,...
        PhasicCON_AIns_L,PhasicEXP_AIns_L,PhasicCON_AIns_R,PhasicEXP_AIns_R,...
        PhasicCON_POperc_L,PhasicEXP_POperc_L,PhasicCON_POperc_R,PhasicEXP_POperc_R);
    
    PhasicIndex = table(PhasicIndCON_PIns_L,PhasicIndEXP_PIns_L,PhasicIndCON_PIns_R,PhasicIndEXP_PIns_R,...
        PhasicIndCON_AIns_L,PhasicIndEXP_AIns_L,PhasicIndCON_AIns_R,PhasicIndEXP_AIns_R,...
        PhasicIndCON_POperc_L,PhasicIndEXP_POperc_L,PhasicIndCON_POperc_R,PhasicIndEXP_POperc_R);
    
    tonic_table_file = fullfile(roiresultpath,'TonicOnset-CON-EXP_PIns_AIns_POperc_hemispheres.csv');
    phasic_table_file = fullfile(roiresultpath,'PhasicOnset-CON-EXP_PIns_AIns_POperc_hemispheres.csv');
    phasicind_table_file = fullfile(roiresultpath,'PhasicIndex-CON-EXP_PIns_AIns_POperc_hemispheres.csv');
    
end

writetable(TonicOnset,tonic_table_file)
writetable(PhasicOnset,phasic_table_file)
writetable(PhasicIndex,phasicind_table_file)

end