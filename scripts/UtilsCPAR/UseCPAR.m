% Interface script for CPAR pressure cuff algometer, for use with Arduino software xx.
% 
% [varargout] = UseCPAR(action,varargin)
%
% Available actions: 
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
%       [data] = UseCPAR('Data',data); get CPAR pressure and VAS rating data
%
% Version: 2.0 to work with new CPAR software and firmware
% Author: Karita Ojala, University Medical Center Hamburg-Eppendorf
% Modified from UseThermoino script by Björn Horing
% Date: 2020-04-13

function [varargout] = UseCPAR(action,dev,varargin)

if ~nargin
    help UseCPAR;
    return;
end    

abort = 0;
varargout{1} = abort;
varargout{2} = [];

if strcmpi(action,'set')
    % varargin{1} = P, set parameters
    % varargin{2} = stimulus durations
    % varargin{3} = pressure in kPa
    
    if ~exist('dev','var') || ~strcmpi(class(dev),'LabBench.Instruments.CPAR.CPARDevice') % add: or not correct type
        warning('\nDev structure from cparInitialize and cparGetDevice required to start CPAR.');
        abort = 1; varargout{1} = abort; return;
    elseif isempty(varargin{3})
        error('Input pressure required.');
    elseif ~isnumeric(varargin{3})
        warning('\nInput pressure needs to be in numeric format. Attempting conversion.');
        try
            pressure_num = str2double(varargin{3});
            varargin{3} = pressure_num;
        catch
            warning('\nCould not convert input pressure into numeric, try again.');
            abort = 1; varargout{1} = abort; return;
        end
    elseif isempty(varargin{2})
        warning('\nPressure pain durations (ramp-up and plateau) required.');
        abort = 1; varargout{1} = abort; return;
    elseif isempty(varargin{1})
        warning('\nSettings structure (P) required.');
        abort = 1; varargout{1} = abort; return;
    end
    
    try
        [created_stim_cuff1, created_stim_cuff2] = CreateCPARStimulus(varargin);
    catch
        warning('Creating stimulus for CPAR failed - check stimulus parameters.');
        abort = 1; varargout{1} = abort; return;
    end
    
    try
        cparSetWaveform(dev,created_stim_cuff1,created_stim_cuff2); 
    catch
        warning('Setting stimulus for CPAR failed - check created stimulus.');
        abort = 1; varargout{1} = abort; return;
    end
    
elseif strcmpi(action,'trigger')
    % varargin{1} = stop mode; 'v' stops when certain VAS rating reached,
    % 'bp' only stops when a button pressed
    % varargin{2} = forced start; 'true' start even when VAS is not at 0,
    % 'false' VAS always has to be at 0 for CPAR to start
    if ~exist('dev','var') || ~strcmpi(class(dev),'LabBench.Instruments.CPAR.CPARDevice') % or not correct type
        warning('Dev structure containing COM port information from cparCreate required to start CPAR.');
        abort = 1; varargout{1} = abort; return;
    elseif ~strcmpi(varargin{1},'bp') && ~strcmpi(varargin{1},'v')
        warning('Invalid stopping option for CPAR: has to be either "bp" for stopping at button press only, or "v" for stopping also at maximum VAS (10 cm).');
        abort = 1; varargout{1} = abort; return;
    elseif ~islogical(varargin{2})
        warning('Forced start option for CPAR missing: has to be either TRUE or FALSE.');
        abort = 1; varargout{1} = abort; return;
    else
        try
            cparStart(dev,varargin{1},varargin{2});
            data = cparInitializeSampling;
        catch
            warning('Starting CPAR failed.');
            abort = 1; varargout{1} = abort; return;
        end
        
        varargout{2} = data;
    end
   
% elseif strcmpi(action,'data')
%     
%     data = varargin{1};
%     
%     try
%         data = cparGetData(data,dev);
%         varargout{2} = data;
%     catch
%         cparClose(dev);
%         warning('Getting CPAR data failed.');
%         abort = 1; varargout{1} = abort; return;
%     end
end

end