function change_physio_parameters(change_action,physio_file,psysio_file_source,physio_file_new,param2change,param2take)

% Load physio data
physio_data = load(physio_file);

% Remove the specified parameter columns
physio_data_new = physio_data;
if change_action == 1 % append
    physio_data_source = load(psysio_file_source);
    physio_data_new = [physio_data_new(:,1:param2change-1) physio_data_source(:,param2take) physio_data_new(:,param2change:end)];
else % remove
    physio_data_new(:,param2change) = [];
end

% Save new data
writematrix(physio_data_new,physio_file_new,'Delimiter','tab');

end