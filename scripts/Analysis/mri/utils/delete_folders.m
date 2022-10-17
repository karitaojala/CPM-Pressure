function delete_folders(options,analysis_version,modelname,subj,folders_level2delete)

if folders_level2delete == 1
    
    for sub = subj
        
        name = sprintf('sub%03d',sub);
        disp(name);
    
        firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
%         firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version]);
        rmdir(firstlvlpath,'s')
        
    end
        
else % 2nd level folders
    
    secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],modelname);
%     secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version]);
    rmdir(secondlvlpath,'s')
    
end

end