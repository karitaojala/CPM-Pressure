function append_motion_parameters(physio_file,motion_file,motion_file2,region,no_physio_reg,no_orig_motion_param,no_new_motion_param)

% Load physio data that contains 6 motion regressors
physio_data = load(physio_file);
motion_data = load(motion_file);
% if strcmp(region,'spinal') % for spinal, also include brain motion files
%     motion_data2 = load(motion_file2); 
% end

% Find out if there are motion censoring regressors at the end
if strcmp(region,'spinal')
    no_orig_motion_param = 0; % spinal physIO file does not actually include original motion parameters
end

physio_motion_censoring_reg = size(physio_data,2) - no_physio_reg - no_orig_motion_param; % substract physio and basic motion parameter

if physio_motion_censoring_reg > 0
    censoring_reg = physio_data(:,(end-physio_motion_censoring_reg+1):end);
end

% Remove the motion censoring regressors and 6 motion regressors and replace with new motion parameters
physio_data_only = physio_data(:,1:end-physio_motion_censoring_reg);
physio_data_only = physio_data_only(:,1:end-no_orig_motion_param); 

% if strcmp(region,'spinal')
%     physio_data_new = [physio_data_only motion_data motion_data2]; % add brain motion parameters as well
% else
    physio_data_new = [physio_data_only motion_data];
% end

% Put back motion censoring regressors at the end
if physio_motion_censoring_reg > 0
    physio_data_new = [physio_data_new censoring_reg];
end

% Save new data
[physio_fp,physio_name,physio_ext] = fileparts(physio_file);
if strcmp(region,'spinal')
    %physio_name_new = [physio_name '_32motion'];
    physio_name_new = [physio_name '_' num2str(no_new_motion_param) 'motion'];
else
    physio_name_new = replace(physio_name,[num2str(no_orig_motion_param) 'motion'],[num2str(no_new_motion_param) 'motion']);
end
% physio_name_new = replace(physio_name,'24motion','24motion-gradient');
physio_file_new = fullfile(physio_fp,[physio_name_new physio_ext]); 
writematrix(physio_data_new,physio_file_new,'Delimiter','tab');

end