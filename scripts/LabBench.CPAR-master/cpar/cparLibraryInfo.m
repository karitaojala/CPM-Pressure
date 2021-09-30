function [config] = cparLibraryInfo()
% Library information
%    [config] = cparLibraryInfo() returns information about the path to 
%    the LabBench installation on the current machine.
%
% Please note:
%    In order for the CPAR Matlab toolbox to work, you must setup a config.json
%    file with the path to the local LabBench installation, and the CPAR 
%    machine must be added to this installation.
%
% See also, cparInitialize

fname = 'config.json';
config  = jsondecode(fileread(fname));
    