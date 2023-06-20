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
    badVols = badVols';
    
    % Add some volumes for certain subjects based on visual inspection
    if contains(motion_file,'sub018') && contains(motion_file,'run5')
        badVols(badVols == 222) = 221;
        badVols(badVols == 224) = 225;
    elseif contains(motion_file,'sub021') && contains(motion_file,'run2')
        badVols = [badVols 159 173 212];
    elseif contains(motion_file,'sub021') && contains(motion_file,'run3')
        badVols = [badVols 175];
        badVols(badVols == 53) = 54;
    elseif contains(motion_file,'sub021') && contains(motion_file,'run4')
        badVols = 151;
    elseif contains(motion_file,'sub021') && contains(motion_file,'run5')
        badVols = [badVols 70];
        badVols(badVols == 220) = 221;
    elseif contains(motion_file,'sub032') && contains(motion_file,'run3')
        badVols(badVols == 46) = 47;
    elseif contains(motion_file,'sub032') && contains(motion_file,'run4')
        badVols = [badVols 88 177];
    elseif contains(motion_file,'sub032') && contains(motion_file,'run5')
        badVols = [badVols 98 99];
    elseif contains(motion_file,'sub034') && contains(motion_file,'run3')
        badVols = [badVols 62];
    elseif contains(motion_file,'sub039') && contains(motion_file,'run2')
        badVols = [badVols 17];
    elseif contains(motion_file,'sub039') && contains(motion_file,'run3')
        badVols = [badVols 63];
    elseif contains(motion_file,'sub042') && contains(motion_file,'run2')
        badVols = [badVols 176];
    elseif contains(motion_file,'sub042') && contains(motion_file,'run4')
        badVols = [badVols 17 225];
    elseif contains(motion_file,'sub044') && contains(motion_file,'run2')
        badVols = [badVols 211];
    elseif contains(motion_file,'sub044') && contains(motion_file,'run3')
        badVols = [badVols 69];
        badVols(badVols == 71) = 70;
    end
    badVols = sort(badVols,'ascend');
    
    % Create motion censoring regressors
    motionCens = zeros(size(physiodata,1),size(badVols,2));
    
    if ~isempty(badVols)
        
        warning(['Detected ' num2str(size(badVols,2)) ' volumes to censor due to > 2 mm motion'])
        for vol = 1:size(badVols,2)
            motionCens(badVols(vol),vol) = 1;
        end
        
    end
        
    % Append motion censoring regressors
    physio_data_new = [physiodata motionCens];
    
    % Save physio data
    writematrix(physio_data_new,physio_file,'Delimiter','tab');

end