function dicom_import

subjects = [1 2];

UIDs = [21199 21198];

loc = 1; T1 = 1;T2 = 1; GRE = 1; DWI = 1;
d = dicom_query(UIDs,loc,T1,T2,dwi,gre);

jobs = '/home/tinnermann/SPM/templates/dicom_import.m';
sdir = '/projects/crunchie/sccp';
dirs = {'Localizer','T1w','T2w','DWI','GRE',};

spm_jobman('initcfg');

for g=1:numel(subjects)
    subdir = fullfile(sdir,sprintf('Sub%02.0f',subjects(g)));
%     mkdir(subdir);
    cd(sdir);
    
    if loc
        % localizer
        mkdir(fullfile(subdir,dirs{1}));
        in{1} = cellstr(d(g).loc.dir{1});
        in{2} = cellstr(fullfile(subdir,dirs{1}));
        spm_jobman('serial',jobs, '', in{:});
        cd(sdir);
    end
    
    if T1
        % T1
        cdir = fullfile(subdir,dirs{2});
        mkdir(cdir);
        for j=1:length(d(g).t1w.dir)
            in{1} = cellstr(d(g).t1w.dir{j});
            in{2} = cellstr(cdir);
            spm_jobman('serial',jobs, '', in{:});
            cd(sdir);
        end
    end
    
    if T2
        % T1
        cdir = fullfile(subdir,dirs{3});
        mkdir(cdir);
        for j=1:length(d(g).t2w.dir)
            in{1} = cellstr(d(g).t2w.dir{j});
            in{2} = cellstr(cdir);
            spm_jobman('serial',jobs, '', in{:});
            cd(sdir);
        end
    end
    
    if DWI
        % T1
        cdir = fullfile(subdir,dirs{4});
        mkdir(cdir);
        for j=1:length(d(g).dwi.dir)
            in{1} = cellstr(d(g).dwi.dir{j});
            in{2} = cellstr(cdir);
            spm_jobman('serial',jobs, '', in{:});
            cd(sdir);
        end
    end
    
    if GRE
        %    Medic
        cdir = fullfile(subdir,dirs{5});
        mkdir(cdir);
        for j=1:length(d(g).gre.dir)                     
            in{1} = cellstr(d(g).gre.dir{j});
            in{2} = cellstr(cdir);
            spm_jobman('serial',jobs, '', in{:});
            cd(sdir);
        end
    end
    
%     if sort
%         %move dummies and sort brain and spinal images
%         cd(hdir);
%         sort_images(subjects(g),sdir,8);
%         cd(sdir);
%     end
end



