function out = dicom_query(UID,epi,highres,fieldmap,blip,localizer)

% read output from dicq and return a cell array with dicom infos. 
% UID can be a vector of multiple exams (without 'TRIO_', e.g. [8888 9999 2222..]). 
% By default EPI and MPRAGE Images are both read in. Set epi/highres = 0, 
% to exclude any image type. However EPI identification is currently 
% limited to 'nin_ep2d*' sequences. If you use any Siemens (e.g. non-NIN) sequences, 
% please adjust the regexp. Highres Images are any MPRAGE sequences. 
% The output struct array has 1 x Number of Subjects cells. All TRIO_1234
% sessions of one subject are collapsed into the cell of that subject.
% Field map images are any sequences named 'gre_field_map'. 'Logstop' EPI
% series are not read in. 
%
% input format
% UID = vector of TRIO_IDs
% epi/highres       = [0 | 1];  default = 1;
% fieldmap/localizer= [0 | 1];  default = 0;
%
% Output format:
% out.sub                : subject ID (e.g. V1234[5])
% out.[epi/hr/fm].seq    : sequence title
% out.[epi/hr/fm].scans  : # of scans
% out.[epi/hr/fm].dir    : directory containing the images
% out.[epi/hr/fm].series : series within exam as returned by dicq
% out.[epi/hr/fm].trio   : TRIO UID
%

% 2010/11/12     s.geuter@uke.de
% 2011/08/25     adjusted to use the new dicq -5 option. sg.
% 2012/06/08     added field map query- l.schenk@uke.de
% 2012/10/10     improved regexp, added localizer. s.geuter@uke.de


if nargin==0, error('please enter TRIO ID'); end;
if nargin<5, localizer = 0; end;
if nargin<4, fieldmap = 0; end;
if nargin<3, highres = 1; end;
if nargin<2, epi = 1; end;


% specify index of image # within strings
img_pos = 88:90;  % replace with regexp

% init minimal output structure
out.sub = [];
UID = UID(:);

% loop over all examinations provided by the vector UID
for ctrio = 1:length(UID)

    % call dicq with the current exam
    [status t] = unix(sprintf('/common/apps/bin/dicq --prot=60 -f -5 --force PRISMA_%05.0f',UID(ctrio)));

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
                % init EPI fields
                if epi
                    out(cexam).epi.seq    = [];
                    out(cexam).epi.dir    = [];
                    out(cexam).epi.scans  = [];
                    out(cexam).epi.series = [];
                    out(cexam).epi.trio   = [];
                end
                % init HR fields
                if highres
                    out(cexam).hr.seq    = [];
                    out(cexam).hr.dir    = [];
                    out(cexam).hr.scans  = [];
                    out(cexam).hr.series = [];
                    out(cexam).hr.trio   = [];
                end
                 % init fieldmap fields
                if fieldmap
                    out(cexam).fm.seq    = [];
                    out(cexam).fm.dir    = [];
                    out(cexam).fm.scans  = [];
                    out(cexam).fm.series = [];
                    out(cexam).fm.trio   = [];
                end
                % init blip fields
                if fieldmap
                    out(cexam).blip.seq    = [];
                    out(cexam).blip.dir    = [];
                    out(cexam).blip.scans  = [];
                    out(cexam).blip.series = [];
                    out(cexam).blip.trio   = [];
                end
                
                % init localizer fields
                if localizer 
                    out(cexam).loc.seq    = [];
                    out(cexam).loc.dir    = [];
                    out(cexam).loc.scans  = [];
                    out(cexam).loc.series = [];
                    out(cexam).loc.trio   = [];
                end
            end
        end
    end
    
    % subject ID
    out(cexam).sub = csubID;
    
    % if epi == 1, find epi sequences
    if epi == 1        
        
        % get lines from dicq output which contain EPI series
%         episeries = regexp(t,'Series:\s*\d* \{ep2d[_]*bold.\s[\.\d\w]*.\s[\w\s]*\s*\}\s[\d\s\|\[\]]*\s[\w\d\.\/]*','match');
        % for sub04 run1
        episeries = regexp(t,'Series:\s*\d* \{ep2d[_]*bold.\s[\.\d\w]*.\s[\w\s]*.\s[\d\s\w]*\s*\}\s[\d\s\|\[\]]*\s[\w\d\.\/]*','match');
        %{ep2d[_]*bold.\s\d.\d\w\d.\d\w\d.\d\w*\d.\s\w*\d\s*\}\s[\d\s\|\[\]]*\s/common/mrt/prisma/images/[\d\.\/]*','match');

        if isempty(episeries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any EPI data...\n',out(cexam).sub, UID(ctrio));
        else
            
            % loop over all EPI series in the current examination
            for cs = 1:length(episeries)
                % exclude logstops
                if isempty(findstr(episeries{cs},'logstop'))
                    out(cexam).epi.scans(end+1)  = str2double(episeries{cs}(img_pos));
                    out(cexam).epi.series(end+1) = str2double(episeries{cs}(8:11));
                    out(cexam).epi.seq{end+1}    = regexp(episeries{cs},'ep2d_bold, 1.5mm3, mb3','match','once');
                    out(cexam).epi.dir{end+1}    = regexp(episeries{cs},'/[\w\d\.\/]*','match','once');
                    out(cexam).epi.trio(end+1)   = UID(ctrio);
                end
            end
        end

    end

    % if highres ==1, find MPRAGE sequences
    if highres == 1
        
        % get lines from dicq output which contain MPRAGE series
        hrseries = regexp(t,'Series:\s*\d* \{[\w\s,]*mprage,\sHR64\s*}[\w\s\|\[\]]*\s[\w\d\.\/]*','match');
        
        if isempty(hrseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any HR data...\n',out(cexam).sub, UID(ctrio));
        else
            
            % loop over all MPRAGE series in the current examination
            for cs = 1:length(hrseries)
                out(cexam).hr.scans(end+1)  = str2double(hrseries{cs}(img_pos));
                out(cexam).hr.series(end+1) = str2double(hrseries{cs}(8:11));
                out(cexam).hr.seq{end+1}    = regexp(hrseries{cs},'[\w\s,]*mprage[\w\s,/_-]*[^\}^  ]','match','once');
                out(cexam).hr.dir{end+1}    = regexp(hrseries{cs},'/[\w\d\.\/\+]*','match','once');
                out(cexam).hr.trio(end+1)   = UID(ctrio);
            end
        end

    end
    
    % if fieldmap ==1, find field map sequences
    if fieldmap == 1
        
        % get lines from dicq output which contain field map series
        fmseries = regexp(t,'Series:\s*\d* \{[\w\s,]*gre_field_map,[\w\s,/_-]*\}[\w\s\|\[\]]*[\w\d\s\.\/]*','match');
        
        if isempty(fmseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any field map data...\n',out(cexam).sub, UID(ctrio));
        else
            
            % loop over all field map series in the current examination
            for cs = 1:length(fmseries)
                out(cexam).fm.scans(end+1)  = str2double(fmseries{cs}(img_pos));
                out(cexam).fm.series(end+1) = str2double(fmseries{cs}(8:11));
                out(cexam).fm.seq{end+1}    = regexp(fmseries{cs},'[\w\s,]*gre_field_map[\w\s,/_-]*[^\}^   ]','match','once');
                out(cexam).fm.dir{end+1}    = regexp(fmseries{cs},'/[\w\d\.\/\+]*','match','once');
                out(cexam).fm.trio(end+1)   = UID(ctrio);
            end
        end
        
    end

     if blip == 1
        
        % get lines from dicq output which contain field map series
        if UID == 19566
            blipseries = regexp(t,'Series:\s*\d* \{ep2d[_]*diff.\s[\.\d\w]*.\s[\w\s]*.\s*\}[\w\s\|\[\]]*[\w\d\s\.\/\+]*','match');
        else
            blipseries = regexp(t,'Series:\s*\d* \{ep2d[_]*diff.\s[\.\d\w]*.\s[\w\s]*.\sPE\s\w*\s*\}[\w\s\|\[\]]*[\w\d\s\.\/\+]*','match');
        end
        
        if isempty(blipseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any blip data...\n',out(cexam).sub, UID(ctrio));
        else
            
            % loop over all field map series in the current examination
            for cs = 1:length(blipseries)
                out(cexam).blip.scans(end+1)  = str2double(blipseries{cs}(img_pos));
                out(cexam).blip.series(end+1) = str2double(blipseries{cs}(8:11));
                out(cexam).blip.seq{end+1}    = regexp(blipseries{cs},'ep2d_diff, 1.5mm3, mb3.\sPE\s\w*','match','once'); 
                out(cexam).blip.dir{end+1}    = regexp(blipseries{cs},'/[\w\d\.\/\+]*','match','once');
                out(cexam).blip.trio(end+1)   = UID(ctrio);
            end
        end
        
     end
    
    % if localizer ==1, find field map sequences
    if localizer == 1
        
        % get lines from dicq output which contain field map series
        locseries = regexp(t,'Series:\s*\d* \{[\w\s,]*ninL[\w\s(),-._]*\}[\w\s\|\[\]]*\/common/mrt/prisma[\w\s\.\/\+]*','match');
        
        if isempty(locseries)
            fprintf('%s: exam PRISMA_%4.0f does not contain any localizer data...\n',out(cexam).sub, UID(ctrio));
        else
            
            % loop over all field map series in the current examination
            for cs = 1:length(locseries)
                out(cexam).loc.scans(end+1)  = str2double(locseries{cs}(img_pos));
                out(cexam).loc.series(end+1) = str2double(locseries{cs}(8:11));
                out(cexam).loc.seq{end+1}    = regexp(locseries{cs},'[\w\s,]*localizer[\w\s(),-._]*[^\}^   ]','match','once');
                out(cexam).loc.dir{end+1}    = regexp(locseries{cs},'/common/mrt/prisma[\w\.\/\+]*','match','once');
                out(cexam).loc.trio(end+1)   = UID(ctrio);
            end
        end
        
    end



end


end