function create_extra_motion_parameters(motion_file)

% Load 6 motion parameters
motionparam = load(motion_file);
[fp,name,ext] = fileparts(motion_file);

% Derivatives of motion parameters (total 12 regressors)
motionparam_deriv = [zeros(1,6); diff(motionparam)];
% [~,motionparam_deriv] = gradient(motionparam);
% figure;plot(motionparam_deriv);
% figure;plot(motionparam_deriv2)

motionparam_with_deriv = [motionparam motionparam_deriv];
% motionfile_12 = fullfile(fp,[name '-12param-gradient' ext]);
motionfile_12 = fullfile(fp,[name '-12param' ext]);
motionparam_with_deriv_zscored = zscore(motionparam_with_deriv);
writematrix(motionparam_with_deriv_zscored,motionfile_12,'Delimiter','tab');

% Squares of motion parameters on top of derivatives (total 24 regressors)
motionparam_square = motionparam_with_deriv_zscored.^2;
motionparam_square_zscored = zscore(motionparam_square);
%figure;plot(motionparam_square);
motionparam_with_deriv_square = [motionparam_with_deriv_zscored motionparam_square_zscored];
% motionfile_24 = fullfile(fp,[name '-24param-gradient' ext]);
motionfile_24 = fullfile(fp,[name '-24param' ext]);
writematrix(motionparam_with_deriv_square,motionfile_24,'Delimiter','tab');

end