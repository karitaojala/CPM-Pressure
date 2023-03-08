function delete_folders(options,analysis_version,model,subj,folders_level2delete,delete_model_only)

warning('Attempting to delete folders!')
txt = input('Do you really want to delete everything? Y/N\n','s');
if strcmp(txt,'Y')
    fprintf('Deleting folders...\n')
elseif strcmp(txt,'N')
    return
end

if folders_level2delete == 1
    
    for sub = subj
        
        name = sprintf('sub%03d',sub);
        disp(name);
        
        if delete_model_only
            folder2delete = [analysis_version ' ' model.name];
            firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
        else
            folder2delete = analysis_version;
            firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version]);
        end
        
        try
            rmdir(firstlvlpath,'s')
            fprintf(['\nDeleted 1st level folder ' folder2delete '\n'])
        catch
            warning('Folder does not exist or cannot delete folder')
        end
    end
    
else % 2nd level folders
    
    if delete_model_only
        folder2delete = [analysis_version ' ' model.name];
        secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name);
    else
        folder2delete = analysis_version;
        secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version]);
    end
    
    try
        rmdir(secondlvlpath,'s')
        fprintf(['\nDeleted 2nd level folder ' folder2delete '\n'])
    catch
        warning('Folder does not exist or cannot delete folder')
    end
    
end

end