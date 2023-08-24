function copy_contrasts_1stlevel(options,analysis_version,model,subj,contrasts,rois,targetfolder)

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    for roi = rois
        
        if any(rois) && options.spinal
            roi_name = options.stats.firstlvl.ppi.spinal.roi_names{roi};
        elseif any(rois) && ~options.spinal
            roi_name = options.stats.firstlvl.ppi.brain.roi_names{roi};
        else
            roi_name = [];
        end
        
        if options.spinal && strcmp(model.name,'HRF_phasic_tonic_pmod_time_concat_fullPhysio')
            firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],[model.name '_32motion'],roi_name);
        else
            firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name,roi_name);
        end
        
        for cong = 1:numel(model.congroups_1stlvl.names)
            
            if strcmp(model.congroups_1stlvl.names{cong},'TonicPhasicTimeConcat')
                connames = options.stats.firstlvl.contrasts.names.tonic_concat;
            elseif strcmp(model.congroups_1stlvl.names{cong},'TonicPhasicPPIConcat')
                connames = options.stats.firstlvl.contrasts.names.tonic_concat_ppi;
            end
            
            % Copy and rename 1st level con images
            for con = contrasts
                if options.spinal
                    con_file = char(fullfile(firstlvlpath, sprintf('s_con_00%02d.nii',con)));
                else
                    con_file = char(fullfile(firstlvlpath, sprintf('s_w_nlco_dartel_con_00%02d.nii',con)));
                end
                fprintf(['Copying contrast ... ' model.congroups_1stlvl.names{cong} ' - ' connames{con} '\n'])
                new_con_file = fullfile(targetfolder,['con_' name '.nii']);
                copyfile(con_file,new_con_file)

            end
            
        end
        
    end
    
end

end