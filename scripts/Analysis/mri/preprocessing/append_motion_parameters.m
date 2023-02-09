function append_motion_parameters(physio_file,motion_file,no_physio_reg,no_new_motion_param)

% Load physio data that contains 6 motion regressors
physio_data = load(physio_file);
motion_data = load(motion_file);

% Find out if there are motion censoring regressors at the end
physio_motion_censoring_reg = size(physio_data,2) - no_physio_reg - 6; % substract physio and basic motion parameter (6)
if physio_motion_censoring_reg > 0
    censoring_reg = physio_data(:,(end-physio_motion_censoring_reg+1):end);
end

% Remove the motion censoring regressors and 6 motion regressors and replace with new motion parameters
physio_data_only = physio_data(:,1:end-physio_motion_censoring_reg);
physio_data_only = physio_data_only(:,1:end-6); 

physio_data_new = [physio_data_only motion_data];

% Put back motion censoring regressors at the end
if physio_motion_censoring_reg > 0
    physio_data_new = [physio_data_new censoring_reg];
end

% Save new data
[physio_fp,physio_name,physio_ext] = fileparts(physio_file);
physio_name_new = replace(physio_name,'6motion',[num2str(no_new_motion_param) 'motion']);
% physio_name_new = replace(physio_name,'24motion','24motion-gradient');
physio_file_new = fullfile(physio_fp,[physio_name_new physio_ext]); 
writematrix(physio_data_new,physio_file_new,'Delimiter','tab');

end