function csf_regressors_PAM50

subs = [4 5 7:10 12:20 22:24 28:33 35:43 45:48 51 52 54:62 65:68 70:72 74:88 90 91 93:99];

exclude = [30];

if ~isempty(exclude)
    subs = subs(~ismember(subs,exclude));
end

num_sess         = 8;

basedir          = '/projects/crunchie/remi3/';

logdir = fullfile(basedir,'logs');

timestamp = datestr(now,'yyyy_mm_dd_HHMMSS');
copyfile(which(mfilename),[logdir filesep mfilename '_' timestamp '.m']);

tmpldir = fullfile(basedir,'PAM50');
mask_file = spm_select('FPList',tmpldir,'PAM50_csf_crop_1vm.nii');
V = spm_vol(mask_file);
[mask XYZm] = spm_read_vols(V);

for g = 1:size(subs,2)
    name = sprintf('Sub%02.2d',subs(g));
    disp(name);
    subdir = fullfile(basedir,name);
    for j = 1:num_sess
        disp(j);
        rundir = fullfile(subdir,sprintf('Run%d',j),'sct');
        files = spm_select('ExtFPList',rundir,'^fmri_moco_norm.nii');
        
        % get variance image and threshold
        %---------------------------------
        scans_h = spm_vol(files);
        
        [Y,XYZe]     = spm_read_vols(scans_h);
        
        vsize         = size(Y);
        maskR         = reshape(mask,prod(vsize(1:3)),1);
        YR            = reshape(Y,prod(vsize(1:3)),vsize(4));
        csf           = YR(find(maskR==1),:);
        
        % Get eigenvectors that explain 90% of the variance
        %---------------------------------------------------
        var_cut = 0.90;
        var_diff = 0.005;
        csf     = meancor(csf');
        [m n]   = size(csf);
        if m > n
            [v s v]  = svd(csf'*csf);
            sd       = diag(s);
            u        = csf*v/sqrt(s);
        else
            [u s u]  = svd(csf*csf');
            sd       = diag(s);
            v        = csf'*u/sqrt(s);
        end
        exp_var   = cumsum(sd)./sum(sd);
        s_cut1    = find(exp_var>var_cut,1,'first');
        s_cut2    = find(diff(exp_var)<var_diff,1,'first');
        
        % either take all components that explain 90% variance or stop if
        % cumulative components do not add more than 0.5% variance
        if s_cut1 > s_cut2
            s_cut = s_cut2;
        else
            s_cut = s_cut1;
        end
        disp(s_cut);
        all(j,g) = s_cut;
        
        csf_reg   = u(:,1:s_cut); %scaling???
        
        save([rundir filesep sprintf('Sub%02.2d_csf_reg_spinal_run%d.mat',subs(g),j)],'csf_reg');
    end
end
save('csf_regs.mat','all');