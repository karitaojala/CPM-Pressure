function extract_TFCE_thresholded(options,analysis_version,model,contrasts)

tails = options.stats.secondlvl.tfce.tails;

for con = contrasts
    
    tfce_results_dir = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'TFCE');
    conname = options.stats.firstlvl.contrasts.names.tonic_concat{con};
    tfce_results_file_mat = fullfile(tfce_results_dir,[conname '.mat']);
    tfce_results_file_nii = fullfile(tfce_results_dir,[conname '.nii']);
    tfce_results_file_nii_n = fullfile(tfce_results_dir,[conname '-1.nii']); % negative contrast
    
    data = load(tfce_results_file_mat);
    if tails == 1 % 1-tailed test
        Y = data.pcorr;
    else % 2-tailed test
        Y = data.pcorr_pos;
        Yn = data.pcorr_neg;
    end
    
    % Find those coordinates with p < 0.05
    pcorr_05 = Y;
    pcorr_05(Y < 0.0001) = 0.0001;
    pcorr_05(Y>0.05) = NaN;
    
    % Get Z-values from p-values
    Zval = norminv(Y);
    Zval = abs(Zval);
    Zval_p05 = Zval;
    Zval_p05(Y < 0.0001) = abs(norminv(0.0001));
    Zval_p05(Y>0.05) = NaN;
    
    % Get SPM volume information for NIFTI
    V = spm_vol(tfce_results_file_nii);
    
    % Save as NIFTI with only subthreshold p-values
    tfce_thrsh_file_nii = fullfile(tfce_results_dir,[conname '_p05.nii']);
    V1 = V;
    V1.fname = tfce_thrsh_file_nii;
    spm_write_vol(V1,pcorr_05);
    
    % Save as NIFTI Z-values
    tfce_zval_file_nii = fullfile(tfce_results_dir,[conname '_Z.nii']);
    V2 = V;
    V2.fname = tfce_zval_file_nii;
    spm_write_vol(V2,Zval);
    
    % Save as NIFTI Z-values thresholded at p < 0.05
    tfce_zthrsh_file_nii = fullfile(tfce_results_dir,[conname '_Z_p05.nii']);
    V3 = V;
    V3.fname = tfce_zthrsh_file_nii;
    spm_write_vol(V3,Zval_p05);
    
    if tails == 2 % Negative contrast for 2-tailed test
        
        % Find those coordinates with p < 0.05
        pcorr_05n = Yn;
        pcorr_05n(Yn < 0.0001) = 0.0001;
        pcorr_05n(Yn>0.05) = NaN;
        
        % Get Z-values from p-values
        Zvaln = norminv(Yn);
        Zvaln = abs(Zvaln);
        Zval_p05n = Zvaln;
        Zval_p05n(Yn < 0.0001) = abs(norminv(0.0001));
        Zval_p05n(Yn>0.05) = NaN;
        
        % Get SPM volume information for NIFTI
        Vn = spm_vol(tfce_results_file_nii_n);
        
        % Save as NIFTI with only subthreshold p-values
        tfce_thrsh_file_nii_n = fullfile(tfce_results_dir,[conname '_p05-1.nii']);
        V1n = Vn;
        V1n.fname = tfce_thrsh_file_nii_n;
        spm_write_vol(V1n,pcorr_05n);
        
        % Save as NIFTI Z-values
        tfce_zval_file_nii_n = fullfile(tfce_results_dir,[conname '_Z-1.nii']);
        V2n = Vn;
        V2n.fname = tfce_zval_file_nii_n;
        spm_write_vol(V2n,Zvaln);
        
        % Save as NIFTI Z-values
        tfce_zthrsh_file_nii_n = fullfile(tfce_results_dir,[conname '_Z_p05-1.nii']);
        V3n = Vn;
        V3n.fname = tfce_zthrsh_file_nii_n;
        spm_write_vol(V3n,Zval_p05n);
        
    end
    
end

end