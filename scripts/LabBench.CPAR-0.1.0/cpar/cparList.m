function [IDs] = cparList()
% cparList List installed CPAR devices on the system
%   [IDs] = cparList() this function retrives the IDs of all installed cpar
%   devices in the system.
%
% Note:
%   The cpar toolbox uses LabBench to manage cpar devices. CPAR devices are
%   in LabBench retreived and handled through their device ID, which for
%   CPAR devices has the form of 'CPAR:[Instance Number]', and example of
%   another device that LabBench uses if National Instruments DAQmx cards
%   that are used for electrophysiology, these have IDs 'DAQmx:[Instance
%   Number]'.
%   
%   This ID must be known before a cpar device can be retreived with the 
%   cparGetDevice and used from Matlab.
%
%   The cparList function provides a way to retrieve these IDs from
%   LabBench. Since in most cases there will only be one CPAR machine
%   installed on a lab computer, the first element in the list is usually
%   the one and only cpar device present, and can be passed to the
%   cparGetDevice function to retrieve the cpar device from LabBench 
%   (please see the code example below).
%
% Code example:
%      IDs = cparList;
%      dev = cparGetDevice(IDs(1));
%
% See also, cparGetDevice

    devices = LabBench.Instruments.InstrumentDB.Instruments;
    IDs = [];
    
    for n = 0:devices.Count - 1
        record = devices.Item(n);
       
        if record.EquipmentType == LabBench.Interface.InstrumentType.CPAR            
            IDs = [IDs; sprintf("%s", record.ID)]; %#ok<AGROW> It is acceptable as it will always be a very short list
        end
    end
end