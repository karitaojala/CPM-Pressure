function remove_physio_parameters(physio_file,physio_file_new,param2remove)

% Load physio data
physio_data = load(physio_file);

% Remove the specified parameter columns
physio_data_new = physio_data;
physio_data_new(:,param2remove) = [];

% Save new data
writematrix(physio_data_new,physio_file_new,'Delimiter','tab');

end