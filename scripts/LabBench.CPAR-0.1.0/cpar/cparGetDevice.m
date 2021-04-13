function [dev] = cparGetDevice(id)
% cparGetDevice Get a CPAR device from the Instrument database.
%   [dev] = cparGetDevice(id) retrive the cpar device with ID [id] from the
%   LabBench Instrument Database.
%
%   The function returns a handle to the device within the LabBench
%   Instrument Database. Consequently, the function can be called as many
%   times as needed for the same device without penalty.
%
%   The first time a device is retrived a connection is established to the
%   device by the LabBench Instrument Database. This takes some time,
%   consequently, the first time a device is retrived it is a good design
%   to check cparError and wait until the error is removed. Removal of the
%   error signals that the Instrument Database has succesfully estalished a
%   connection to the requested cpar device and that it is ready for use
%   (please see the Code example below).
%
% Note:
%   Before using this function, please read the documentation for the
%   cparList and cparInitialize functions, as these provide important
%   information on how cpar devices are handled by the LabBench Instrument
%   Database.
%
% Code example:
%   dev = cparGetDevice('CPAR:1');
%
%   % Wait until a connection has been established 
%   tic
%   while cparError(dev)
%      pause(0.2);%    
%      if toc > 10
%         me = MException('CPAR:TimeOut', 'No connection');
%         throw(me);
%      end
%   end
%
% See also, cparList, cparInitialize

if LabBench.Instruments.InstrumentDB.Exists(id)
    record = LabBench.Instruments.InstrumentDB.Get(id);
    record.Used = 1;
    dev = record.Instrument;
    dev.PingEnabled = 1;
else
   fprintf("Instrument with ID = %s does not exists!\n", id);
   dev = 0;
end