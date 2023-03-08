function create_motion_censoring_regressors(motion_file,physio_file,motion_threshold)

    motiondata = load(motion_file);
    physiodata = load(physio_file);
    
    % Detect volumes with too much motion
    %absTrans = sum(abs(motiondata(:,1:2)),2);
    %rmsdTrans = sqrt(sum(motiondata(:,1:2).^2,2));
    diffTrans_x = [0; diff(motiondata(:,1))];
    diffTrans_y = [0; diff(motiondata(:,2))];
    badVols_x = diffTrans_x > motion_threshold;
    badVols_y = diffTrans_y > motion_threshold;
    badVols = find(badVols_x | badVols_y);
    
    % Create motion censoring regressors
    motionCens = zeros(size(physiodata,1),size(badVols,1));
    
    if ~isempty(badVols)
        
        warning(['Detected ' num2str(size(badVols,1)) ' volumes to censor due to > 2 mm motion'])
        for vol = 1:size(badVols,1)
            motionCens(badVols(vol),vol) = 1;
        end
        
    end
        
    % Append motion censoring regressors
    physio_data_new = [physiodata motionCens];
    
    % Save physio data
    writematrix(physio_data_new,physio_file,'Delimiter','tab');

end