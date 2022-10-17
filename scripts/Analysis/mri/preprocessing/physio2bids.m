function physio2bids(physiodir,all_subs,n_runs)

for sub = 1:numel(all_subs)
    
    sub_id = sprintf('sub%03d',all_subs(sub));
    
    for run = 1:n_runs
        
        run_id = sprintf('run%d',run);
        
        physiofile = fullfile(physiodir,sub_id,[sub_id '-' run_id '-physio.mat']);
        jsonfile = fullfile(physiodir,sub_id,[sub_id '-' run_id '-physio-bids.JSON']);
        physio_orig = load(physiofile);
        physio_orig = physio_orig.physio;
        
        clear physio
        physio(:,1) = physio_orig.pulse;
        physio(:,2) = physio_orig.resp;
        scanner_triggers = physio_orig.scansRunStart;
        % scr not included as they are not used for noise correction
        
        cardiac = physio(:,1); 
        respiratory = physio(:,2); 
        trigger = zeros(numel(cardiac),1);
        trigger(scanner_triggers) = 1;
        physio(:,3) = trigger;
        physiotable = table(cardiac,respiratory,trigger);
        
        save(fullfile(physiodir,sub_id,[sub_id '-' run_id '-physio-bids.mat']),'physio');
        textfile = fullfile(physiodir,sub_id,[sub_id '-' run_id '-physio-bids.txt']);
        tsvfile = fullfile(physiodir,sub_id,[sub_id '-' run_id '-physio-bids.tsv']);
        writetable(physiotable,textfile,'Delimiter','\t',...
            'WriteVariableNames',false)
        movefile(textfile,tsvfile);
        gzip(tsvfile)
        
        % JSON file
        s.SamplingFrequency = 100;
        s.StartTime = 0;
        s.Columns = {'cardiac','respiratory','trigger'};
        fid = fopen(jsonfile,'w'); 
        sjson = jsonencode(s);
        fprintf(fid, sjson); 
        
    end
    
end

end