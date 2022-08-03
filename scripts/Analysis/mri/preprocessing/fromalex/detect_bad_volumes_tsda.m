function detect_bad_volumes_tsda

subs = [4 5 7:10 12:20 22:24 28:33 35:43 45:48 51 52 54:62 65:68 70:72 74:88 90 91 93:99];
   
exclude = [];

if ~isempty(exclude)
    subs = subs(~ismember(subs,exclude));
end

basedir = '/projects/crunchie/remi3/';
nsess = 8;
nscans = 153;

logdir = fullfile(basedir,'logs');

timestamp = datestr(now,'yyyy_mm_dd_HHMMSS');
copyfile(which(mfilename),[logdir filesep mfilename '_' timestamp '.m']);

h = figure;

for g = 1:numel(subs)
    name = sprintf('Sub%02.0f',subs(g));
    disp(name);
    for r = 1:nsess
        rundir = fullfile(basedir,name,sprintf('Run%d',r),'realign_sess');
        cd(rundir);
        data = load('timediff.mat');
        %% detect bad volumes
        vvar = data.td/mean(data.globals);
        m = mean(vvar); s = std(vvar);       
        clf(h);
        outliers = find(vvar>m+s*3);
        figure(h); plot(vvar);hold on; plot(xlim,[m,m],'r-');plot(xlim,[m+s,m+s],'g-');plot(xlim,[m-s,m-s],'g-')
        %% disp difference image with previous
%         files = spm_select('FPList',rundir,'^rhfTRIO.*.nii$');
%         fprintf('sub%02.0f run%d: \n',subs(g),r);
%         try
%         check_images = files(outliers,:);
%         for j = 1:size(check_images,1)
%             inputs = [check_images(j,:),',1'; files(outliers(j)-1,:),',1'];
%             spm_imcalc(cellstr(inputs),'output.nii','i1-i2',{0,0,1,4});
%             disp(inputs);
%             spm_check_registration('output.nii');
%             keep = input('Keep volume?','s');
%             if strcmp(keep,'yes')
%                 outliers(j) = 0;
%             end
%             clear inputs
%         end
%         catch
%         end
%        outliers(outliers==0) = [];
%% create noise regressors for outlier volumes
        disp(numel(outliers));
        nui = zeros(nscans,length(outliers));
        for j = 1:length(outliers)           
            nui(outliers(j),j) = 1;
        end
        save(sprintf([rundir filesep 'Sub%02.0f_nui_reg_spinal_run%d'],subs(g),r),'nui');
% try
%         check_images = files(outliers,:);
%         fprintf('sub%02.0f run%d: \n',subs(g),r); disp(outliers)
%         spm_check_registration(check_images);
%         input('Continue?');
% catch
%     disp('no outliers');
% end
        
     
    end
end
