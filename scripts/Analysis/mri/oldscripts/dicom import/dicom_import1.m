function dicom_import(basedir,sub,UID,EPI,T1,fieldmap,blip,localizer)

d = dicom_query(UID,EPI,T1,fieldmap,blip,localizer);

subdir = fullfile(basedir,sprintf('Sub%02.0f',sub));
mkdir(subdir);
cd(basedir);

if EPI
    for j=1:length(d.epi.dir)
        
        rundir = fullfile(subdir,sprintf('Run%d',j));
        mkdir(rundir);
        dicomdir = d.epi.dir{j};
        dicoms = spm_select('FPList',dicomdir,'MR.*');
        
        matlabbatch{j}.spm.util.import.dicom.data = cellstr(dicoms);
        matlabbatch{j}.spm.util.import.dicom.root = 'flat';
        matlabbatch{j}.spm.util.import.dicom.outdir = {rundir};
        matlabbatch{j}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{j}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{j}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{j}.spm.util.import.dicom.convopts.icedims = 0;
        
    end
    spm_jobman('run',matlabbatch);
    clear matlabbatch
    cd(basedir)
end

if T1
    hrdir = fullfile(subdir,'T1');
    mkdir(hrdir);
    for j=1:length(d.hr.dir)
        
        dicomdir = d.hr.dir{j};
        dicoms = spm_select('FPList',dicomdir,'MR.*');
        
        matlabbatch{j}.spm.util.import.dicom.data = cellstr(dicoms);
        matlabbatch{j}.spm.util.import.dicom.root = 'flat';
        matlabbatch{j}.spm.util.import.dicom.outdir = {hrdir};
        matlabbatch{j}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{j}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{j}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{j}.spm.util.import.dicom.convopts.icedims = 0;
    end
    spm_jobman('run',matlabbatch);
    clear matlabbatch
    cd(basedir)
end

if fieldmap
    fmdir = fullfile(subdir,'FM');
    mkdir(fmdir);
    for j=1:length(d(g).fm.dir)
        
        dicomdir = d.fm.dir{j};
        dicoms = spm_select('FPList',dicomdir,'MR.*');
        
        matlabbatch{j}.spm.util.import.dicom.data = cellstr(dicoms);
        matlabbatch{j}.spm.util.import.dicom.root = 'flat';
        matlabbatch{j}.spm.util.import.dicom.outdir = {fmdir};
        matlabbatch{j}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{j}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{j}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{j}.spm.util.import.dicom.convopts.icedims = 0;
    end
    spm_jobman('run',matlabbatch);
    clear matlabbatch
    cd(basedir)
end

if blip
    for j=1:length(d.blip.dir)
        if j == 1
            blipdir = fullfile(subdir,'Blip_std');
        elseif j == 2
            blipdir = fullfile(subdir,'Blip_inv');
        end
        mkdir(blipdir);
        
        dicomdir = d.blip.dir{j};
        dicoms = spm_select('FPList',dicomdir,'MR.*');
        
        matlabbatch{j}.spm.util.import.dicom.data = cellstr(dicoms);
        matlabbatch{j}.spm.util.import.dicom.root = 'flat';
        matlabbatch{j}.spm.util.import.dicom.outdir = {blipdir};
        matlabbatch{j}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{j}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{j}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{j}.spm.util.import.dicom.convopts.icedims = 0;
        
    end
    spm_jobman('run',matlabbatch);
    clear matlabbatch
    cd(basedir)
     
end

if localizer
    locdir = fullfile(subdir,'Localizer');
    mkdir(locdir);
    for j=1:length(d.loc.dir)
        
        dicomdir = d.loc.dir{j};
        dicoms = spm_select('FPList',dicomdir,'MR.*');
        
        matlabbatch{j}.spm.util.import.dicom.data = cellstr(dicoms);
        matlabbatch{j}.spm.util.import.dicom.root = 'flat';
        matlabbatch{j}.spm.util.import.dicom.outdir = {locdir};
        matlabbatch{j}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{j}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{j}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{j}.spm.util.import.dicom.convopts.icedims = 0;
    end
    spm_jobman('run',matlabbatch);
    clear matlabbatch
    cd(basedir)
end

end


