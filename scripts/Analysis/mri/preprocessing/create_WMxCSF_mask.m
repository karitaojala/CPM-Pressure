options = get_options();
addpath(options.path.spmdir)
addpath(genpath(options.path.scriptdir))

subj = options.subj.all_subs;

for sub = 1:numel(subj)

    name = sprintf('sub%03d',subj(sub));
    disp(name);
    
    sub_dir = fullfile(options.path.mridir,name,'t1_corrected');
    
    matlabbatch{sub}.spm.util.imcalc.input = {
        fullfile(sub_dir,['inv_nlin_c2' name '-t1_corrected.nii'])
        fullfile(sub_dir,['inv_nlin_c3' name '-t1_corrected.nii'])
        };
    matlabbatch{sub}.spm.util.imcalc.output = ['inv_nlin_c2xc3' name '-t1_corrected'];
    matlabbatch{sub}.spm.util.imcalc.outdir = {sub_dir};
    matlabbatch{sub}.spm.util.imcalc.expression = 'i1.*i2';
    matlabbatch{sub}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{sub}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{sub}.spm.util.imcalc.options.mask = 0;
    matlabbatch{sub}.spm.util.imcalc.options.interp = 1;
    matlabbatch{sub}.spm.util.imcalc.options.dtype = 4;

end

spm_jobman('run', matlabbatch);