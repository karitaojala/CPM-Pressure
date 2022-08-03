function out = dicom_query(UID,loc,t1w,t2w,dwi,gre)

% read output from dicq and return a cell array with dicom infos. 
% UID can be a vector of multiple exams (without 'PRISMA_', e.g. [8888 9999 2222..]). 
% By default dwi and MPRAGE Images are both read in. Set dwi/higt1wes = 0, 
% to exclude any image type. However dwi identification is currently 
% limited to 'nin_ep2d*' sequences. If you use any Siemens (e.g. non-NIN) sequences, 
% please adjust the regexp. Higt1wes Images are any MPRAGE sequences. 
% The output struct array has 1 x Number of Subjects cells. All PRISMA_1234
% sessions of one subject are collapsed into the cell of that subject.
% Field map images are any sequences named 'gre_field_map'. 'Logstop' dwi
% series are not read in. 
%
% input format
% UID = vector of PRISMA_IDs
% dwi/higt1wes       = [0 | 1];  default = 1;
% fieldmap/localizer= [0 | 1];  default = 0;
%
% Output format:
% out.sub                : subject ID (e.g. V1234[5])
% out.[dwi/t1w/fm].seq    : sequence title
% out.[dwi/t1w/fm].scans  : # of scans
% out.[dwi/t1w/fm].dir    : directory containing the images
% out.[dwi/t1w/fm].series : series within exam as returned by dicq
% out.[dwi/t1w/fm].PRISMA   : PRISMA UID
%

% 2010/11/12     s.geuter@uke.de
% 2011/08/25     adjusted to use the new dicq -5 option. sg.
% 2012/06/08     added field map query- l.schenk@uke.de
% 2012/10/10     improved regexp, added localizer. s.geuter@uke.de


% specify index of image # within strings
img_pos = 88:90;  % replace with regexp

% init minimal output structure
out.sub = [];
UID = UID(:);

% loop over all examinations provided by the vector UID
for cprisma = 1:length(UID)

    % call dicq with the current exam
    [status t] = unix(sprintf('/common/apps/bin/dicq --prot=60 -f -5 --force PRISMA_%05.0f',UID(cprisma)));

    % check whether call was successful
    if status ~= 0
        error('error while calling UNIX(/common/apps/bin/dicq');
    end

    % extract Patient ID from t
    csubID = regexp(t,'V\d\d\d\d\d?','match','once');
    
    % check whether this subject has another session
    for cs = 1:length(out)
        if strcmp(out(cs).sub, csubID)
            cexam = cs;
            break
        else
            cexam = int8(~isempty(out(cs).sub) * length(out)) + 1;
            % if new subject, make new substruct
            if cs == length(out)
                % init dwi fields
                if dwi
                    out(cexam).dwi.seq    = [];
                    out(cexam).dwi.dir    = [];
                    out(cexam).dwi.scans  = [];
                    out(cexam).dwi.series = [];
                    out(cexam).dwi.prisma   = [];
                end
                % init t1w fields
                if t1w
                    out(cexam).t1w.seq    = [];
                    out(cexam).t1w.dir    = [];
                    out(cexam).t1w.scans  = [];
                    out(cexam).t1w.series = [];
                    out(cexam).t1w.prisma   = [];
                end
                if t2w
                    out(cexam).t2w.seq    = [];
                    out(cexam).t2w.dir    = [];
                    out(cexam).t2w.scans  = [];
                    out(cexam).t2w.series = [];
                    out(cexam).t2w.prisma   = [];
                end
                 % init gre fields
                if gre
                    out(cexam).gre.seq    = [];
                    out(cexam).gre.dir    = [];
                    out(cexam).gre.scans  = [];
                    out(cexam).gre.series = [];
                    out(cexam).gre.prisma   = [];
                end
                end
                % init localizer fields
                if loc 
                    out(cexam).loc.seq    = [];
                    out(cexam).loc.dir    = [];
                    out(cexam).loc.scans  = [];
                    out(cexam).loc.series = [];
                    out(cexam).loc.prisma   = [];
                end
            end
      
    
    % subject ID
    out(cexam).sub = csubID;
    
    % if dwi == 1, find dwi sequences
    if dwi == 1        
        
        % get lines from dicq output which contain dwi series
        dwiseries = regexp(t,'Series:\s*\d* \{DWI[\w\s,/_-]*\.*\}[\w\s\|\[\]]*\/common/mrt/prisma[\w\.\/\+]*','match');

        if isempty(dwiseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any dwi data...\n',out(cexam).sub, UID(cprisma));
        else
            
            % loop over all dwi series in the current examination
            for cs = 1:length(dwiseries)
                % exclude logstops
                if isempty(findstr(dwiseries{cs},'logstop'))
                    out(cexam).dwi.scans(end+1)  = str2double(dwiseries{cs}(img_pos));
                    out(cexam).dwi.series(end+1) = str2double(dwiseries{cs}(8:11));
                    out(cexam).dwi.seq{end+1}    = regexp(dwiseries{cs},'[\w\s,]*DWI[\w\s,/_-]*\.*[^\}^   ]','match','once');
                    out(cexam).dwi.dir{end+1}    = regexp(dwiseries{cs},'/common/mrt\d*/prisma[\w\.\/\+]*','match','once');
                    out(cexam).dwi.prisma(end+1)   = UID(cprisma);
                end
            end
        end

    end

    % if higt1wes ==1, find MPRAGE sequences
    if t1w == 1
        
        % get lines from dicq output which contain MPRAGE series
        t1wseries = regexp(t,'Series:\s*\d* \{T1w[\w\s,/_-]*\.*\}[\w\s\|\[\]]*\/common/mrt/prisma[\w\.\/\+]*','match');
        
        if isempty(t1wseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any t1w data...\n',out(cexam).sub, UID(cprisma));
        else
            
            % loop over all MPRAGE series in the current examination
            for cs = 1:length(t1wseries)
                out(cexam).t1w.scans(end+1)  = str2double(t1wseries{cs}(img_pos));
                out(cexam).t1w.series(end+1) = str2double(t1wseries{cs}(8:11));
                out(cexam).t1w.seq{end+1}    = regexp(t1wseries{cs},'T1w[\w\s,/_-]*[^\}^   ]','match','once');
                out(cexam).t1w.dir{end+1}    = regexp(t1wseries{cs},'/common/mrt\d*/prisma[\w\.\/\+]*','match','once');
                out(cexam).t1w.prisma(end+1)   = UID(cprisma);
            end
        end

    end
    
    % if higt1wes ==1, find MPRAGE sequences
    if t2w == 1
        
        % get lines from dicq output which contain MPRAGE series
        t2wseries = regexp(t,'Series:\s*\d* \{T2w[\w\s,/_-]*\.*\}[\w\s\|\[\]]*\/common/mrt/prisma[\w\.\/\+]*','match');
        
        if isempty(t1wseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any t1w data...\n',out(cexam).sub, UID(cprisma));
        else
            
            % loop over all MPRAGE series in the current examination
            for cs = 1:length(t2wseries)
                out(cexam).t2w.scans(end+1)  = str2double(t2wseries{cs}(img_pos));
                out(cexam).t2w.series(end+1) = str2double(t2wseries{cs}(8:11));
                out(cexam).t2w.seq{end+1}    = regexp(t2wseries{cs},'T2w[\w\s,/_-]*[^\}^   ]','match','once');
                out(cexam).t2w.dir{end+1}    = regexp(t2wseries{cs},'/common/mrt\d*/prisma[\w\.\/\+]*','match','once');
                out(cexam).t2w.prisma(end+1)   = UID(cprisma);
            end
        end

    end
    
    % if gre ==1, find gre sequences
    if gre == 1
        
        % get lines from dicq output which contain gre series
        greseries = regexp(t,'Series:\s*\d* \{GRE-[\w\s,/_-]*\.*\}[\w\s\|\[\]]*\/common/mrt/prisma[\w\.\/\+]*','match');
        
        if isempty(greseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any gre data...\n',out(cexam).sub, UID(cprisma));
        else
            
            % loop over all gre series in the current examination
            for cs = 1:length(greseries)
                out(cexam).gre.scans(end+1)  = str2double(greseries{cs}(img_pos));
                out(cexam).gre.series(end+1) = str2double(greseries{cs}(8:11));
                out(cexam).gre.seq{end+1}    = regexp(greseries{cs},'GRE[\w\s,/_-]*[^\}^   ]','match','once');
                out(cexam).gre.dir{end+1}    = regexp(greseries{cs},'/common/mrt/prisma[\w\.\/\+]*','match','once');
                out(cexam).gre.prisma(end+1)   = UID(cprisma);
            end
        end

    end

    
    % if localizer ==1, find field map sequences
    if loc == 1
        
        % get lines from dicq output which contain field map series
        locseries = regexp(t,'Series:\s*\d* \{Localizer[\w\s(),-._]*\}[\w\s\|\[\]]*\/common/mrt\d*/prisma[\w\s\.\/\+]*','match');
        
        if isempty(locseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any localizer data...\n',out(cexam).sub, UID(cprisma));
        else
            
            % loop over all field map series in the current examination
            for cs = 1:length(locseries)
                out(cexam).loc.scans(end+1)  = str2double(locseries{cs}(img_pos));
                out(cexam).loc.series(end+1) = str2double(locseries{cs}(8:11));
                out(cexam).loc.seq{end+1}    = regexp(locseries{cs},'[\w\s,]*localizer[\w\s(),-._]*[^\}^   ]','match','once');
                out(cexam).loc.dir{end+1}    = regexp(locseries{cs},'/common/mrt\d*/prisma[\w\.\/\+]*','match','once');
                out(cexam).loc.prisma(end+1)   = UID(cprisma);
            end
        end
        
    end



    end
end


