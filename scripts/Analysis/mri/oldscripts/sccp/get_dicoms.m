function dicom_import

subjects = [6]; %1 2

UIDs = [ 21217];

loc = 0; T1 = 1;T2 = 1; GRE = 1; DWI = 1;
d = dicom_query(UIDs,loc,T1,T2,DWI,GRE);

jobs = '/home/tinnermann/SPM/templates/dicom_import.m';
sdir = '/projects/crunchie/sccp';


for g=1:numel(subjects)
    subdir = fullfile(sdir,sprintf('Sub%02.0f',subjects(g)));
    mkdir(subdir);
    cd(sdir);
    
    if loc
        in = d(g).loc.dir{1};
        copyfile(in,subdir);
    end
    
    if T1
        for j = 1:length(d(g).t1w.dir)
            in = d(g).t1w.dir{j};
            copyfile(in,subdir);
        end
    end
    
    if T2
        for j = 1:length(d(g).t2w.dir)
            in = d(g).t2w.dir{j};
            copyfile(in,subdir);
        end
    end
    
    if DWI
        for j = 1:length(d(g).dwi.dir)
            in = d(g).dwi.dir{j};
            copyfile(in,subdir);
        end
    end
    
    if GRE
        for j = 1:length(d(g).gre.dir)
            in = d(g).gre.dir{j};
            copyfile(in,subdir);
        end
    end
    
    %     if sort
    %         %move dummies and sort brain and spinal images
    %         cd(hdir);
    %         sort_images(subjects(g),sdir,8);
    %         cd(sdir);
    %     end
end



