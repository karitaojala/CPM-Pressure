function add_ppi_contrast(SPMfile)

clear matlabbatch

SPM4con = load(SPMfile);
existingCons = {SPM4con.SPM.xCon.name};

if ~any(strcmp(existingCons,'PPI')) % check if contrast already exists
    
    no_cond = numel([SPM4con.SPM.Sess.Fc.p]);
    
    matlabbatch{1}.spm.stats.con.spmmat = {SPMfile};
    matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'PPI';
    matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = eye(no_cond);
    matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.delete = 0;
    
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    
end

end