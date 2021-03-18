% Interface script for CPAR pressure cuff algometer, for use with Arduino software xx.
% 
% [varargout] = UseCPAR(action,varargin)
%
% Available actions: 
%
%       UseCPAR('Init',comport); initialize CPAR, where comport is the COM
%       port (e.g., 'COM3')
%
%       UseCPAR('Set',createdstim); set stimulus for CPAR, where dev is
%       a structure created by cparCreate when initializing CPAR and
%       createdstim is the created stimulus from cparCreateStimulus
%
%       UseCPAR('Trigger',stopmode,forcedstart); start CPAR stimulus,
%       where dev is a structure created by cparCreate when initializing
%       CPAR, stopmode is the mode of stopping CPAR ('b' button press only,
%       'v' also at maximum VAS rating), and forcedstart defines whether
%       CPAR is also started when VAS is not at 0 or not (true/false)
%
%       [data] = UseCPAR('Data'); get CPAR pressure and VAS rating data
%
%       UseCPAR('Kill',dev); stop CPAR and close COM ports, where dev is a 
%       structure created by cparCreate when initializing CPAR
%
% Version: 1.0
% Author: Karita Ojala, University Medical Center Hamburg-Eppendorf
% Modified from UseThermoino script by Björn Horing
% Date: 2020-12-14

function [varargout] = UseCPAR(action,varargin)

if ~nargin
    help UseCPAR;
    return;
end    

global dev

abort = 0;
varargout{1} = abort;

if strcmpi(action,'init')
    % varargin{1} = COM port
    if isempty(varargin{1})
        warning('\nNeed COM port as input in the form: "COMx" where x is COM port number.');
        abort = 1; varargout{1} = abort; return;
    else
        try
            dev = cparCreate(varargin{1}); % COM port
        catch
            warning('\nCreating Dev structure failed - check that COM port is correct.');
            abort = 1; varargout{1} = abort; return;
        end
    end
    
    if exist('dev','var') && strcmpi(class(dev),'LabBench.CPAR.CPARDevice')
        try
            cparOpen(dev);
        catch
            warning('\nOpening CPAR failed. Check dev structure from cparCreate and the COM port. Probably COM port in use, reset (restart Matlab).');
            abort = 1; varargout{1} = abort; return;
        end
    else
        warning('\nOpening CPAR failed: empty or invalid Dev structure. ');
        abort = 1; varargout{1} = abort; return;
    end
   
elseif strcmpi(action,'kill')

    if ~exist('dev','var') || ~strcmpi(class(dev),'LabBench.CPAR.CPARDevice') % or not correct type
        error('Dev structure containing COM port information required to close COM port.');
    else
        try
            cparClose(dev);
        catch
            warning('\nClosing CPAR and COM port failed. Restart Matlab to close COM port.');
            abort = 1; varargout{1} = abort; return;
        end
    end
    
elseif strcmpi(action,'set')
    % varargin{1} = P, set parameters
    % varargin{2} = stimulus durations
    % varargin{3} = pressure in kPa
    
    if ~exist('dev','var') || ~strcmpi(class(dev),'LabBench.CPAR.CPARDevice') % add: or not correct type
        warning('\nDev structure containing COM port information from cparCreate required to start CPAR.');
        abort = 1; varargout{1} = abort; return;
    elseif isempty(varargin{3})
        cparClose(dev);
        error('Input pressure required.');
    elseif ~isnumeric(varargin{3})
        warning('\nInput pressure needs to be in numeric format. Attempting conversion.');
        try
            pressure_num = str2double(varargin{3});
            varargin{3} = pressure_num;
        catch
            cparClose(dev);
            warning('\nCould not convert input pressure into numeric, try again.');
            abort = 1; varargout{1} = abort; return;
        end
    elseif isempty(varargin{2})
        cparClose(dev);
        warning('\nPressure pain durations (ramp-up and plateau) required.');
        abort = 1; varargout{1} = abort; return;
    elseif isempty(varargin{1})
        cparClose(dev);
        warning('\nSettings structure (P) required.');
        abort = 1; varargout{1} = abort; return;
    end
    
    try
        [created_stim_cuff1, created_stim_cuff2] = CreateCPARStimulus(varargin);
    catch
        cparClose(dev);
        warning('Creating stimulus for CPAR failed - check stimulus parameters.');
        abort = 1; varargout{1} = abort; return;
    end
    
    try
        cparSetStimulus(dev,created_stim_cuff1); 
    catch
        cparClose(dev);
        warning('Setting stimulus for Cuff 1 for CPAR failed - check created stimulus.');
        abort = 1; varargout{1} = abort; return;
    end
    
    try
        cparSetStimulus(dev,created_stim_cuff2); 
    catch
        cparClose(dev);
        warning('Setting stimulus for Cuff 2 for CPAR failed - check created stimulus.');
        abort = 1; varargout{1} = abort; return;
    end
    
elseif strcmpi(action,'trigger')
    % varargin{1} = stop mode; 'v' stops when certain VAS rating reached,
    % 'b' only stops when a button pressed
    % varargin{2} = forced start; 'true' start even when VAS is not at 0,
    % 'false' VAS always has to be at 0 for CPAR to start
    if ~exist('dev','var') || ~strcmpi(class(dev),'LabBench.CPAR.CPARDevice') % or not correct type
        warning('Dev structure containing COM port information from cparCreate required to start CPAR.');
        abort = 1; varargout{1} = abort; return;
    elseif ~strcmpi(varargin{1},'b') && ~strcmpi(varargin{1},'v')
        cparClose(dev);
        warning('Invalid stopping option for CPAR: has to be either "b" for stopping at button press only, or "v" for stopping also at maximum VAS (10 cm).');
        abort = 1; varargout{1} = abort; return;
    elseif ~islogical(varargin{2})
        cparClose(dev);
        warning('Forced start option for CPAR missing: has to be either TRUE or FALSE.');
        abort = 1; varargout{1} = abort; return;
    else
        try
            cparStart(dev,varargin{1},varargin{2});
        catch
            cparClose(dev);
            warning('Starting CPAR failed.');
            abort = 1; varargout{1} = abort; return;
        end
    end
   
elseif strcmpi(action,'data')
    
    try
        data = cparGetData(dev);
        varargout{2} = data;
    catch
        cparClose(dev);
        warning('Getting CPAR data failed.');
        abort = 1; varargout{1} = abort; return;
    end
end

end