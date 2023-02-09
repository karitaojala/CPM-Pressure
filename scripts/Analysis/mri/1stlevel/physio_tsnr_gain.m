clear all

mpath = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\';
sub = '001';

physio = fullfile(mpath,'physio',['sub' sub ],'HRVRVT_noiseROI_6comp_6motion',['sub' sub '-run1-physio-brain-HRVRVT_noiseROI_6comp_6motion.mat']);
SPMfile = fullfile(mpath,'mri','data',['sub' sub ],'1stlevel','Version_18Jan23','HRF_phasic_tonic_HRVRVT_noiseROI','SPM.mat');

SPM = load(SPMfile);
SPM = SPM.SPM;

% phasic_reg_ind = find(contains(SPM.xX.name,'PhasicStim*bf(1)'));

conweights = eye(21);
conweights(:,1:3) = 0;

% matlabbatch{1}.spm.stats.con.spmmat = {SPMfile};
% matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'RETROICOR';
% matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = conweights;
% matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'replsc';
% matlabbatch{1}.spm.stats.con.delete = 0;
% 
% spm_jobman('run', matlabbatch);

indexContrastForSnrRatio = 44;

for c = 1:18
    namesPhysContrasts{c} = sprintf('NoiseReg%02d - All Sessions',c);
end

% tapas_physio_compute_tsnr_gains(physio, SPM, indexContrastForSnrRatio, namesPhysContrasts)
% tapas_physio_compute_tsnr_gains(physio, SPM, indexContrastForSnrRatio)

iC = 44;
iCForRatio = 0;
doInvert = true;
doSaveNewContrasts = false;

tapas_physio_compute_tsnr_spm(SPM, iC, iCForRatio, doInvert, doSaveNewContrasts)