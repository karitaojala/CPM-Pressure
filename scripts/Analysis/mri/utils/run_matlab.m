function run_matlab(np, matlabbatch, l_string)

spm_path          = fileparts(which('spm')); %get spm path
mat_name          = which(mfilename);
[~,mat_name,~]    = fileparts(mat_name);

hostname          = char(getHostName(java.net.InetAddress.getLocalHost));
mat_name          = [mat_name '_' hostname];

fname = [num2str(np) '_' mat_name '.mat'];

save([num2str(np) '_' mat_name],'matlabbatch');
lo_cmd  = ['clear matlabbatch;load(''' fname ''');'];
ex_cmd = ['addpath(''' spm_path ''');addpath(''c:\Users\ojala\Documents\MATLAB\'');spm(''defaults'',''FMRI'');spm_jobman(''initcfg'');spm_jobman(''run'',matlabbatch);'];
end_cmd = [' delete(''' fname ''');exit'];
system(['start matlab.exe ' l_string ' -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r "' lo_cmd ex_cmd end_cmd]);

end