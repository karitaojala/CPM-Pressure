function cparInitialize()
% Initialize the LabBench instrument database.
%    cparInitialize() initialize the LabBench Instrument Database.
%
% Note:
%    LabBench is used to manage the connection to cpar devices. Consequently,  
%    the Matlab toolbox does not handle connection, communication and 
%    disconnection with cpar devices, but this is instead handled by the 
%    LabBench Instrument Database.
%
%    This has the advantage that any error or exception in Matlab will not 
%    cause the cpar device to be locked or similar, which could for example
%    occur if Matlab directly opened a connection to the cpar device, an
%    error occurred, and the connection was never closed again and the cpar
%    device variable was lost. If the cpar device could get locked it would 
%    only be possible to recover from this error by restarting Matlab.
%
%    However, before the toolbox can use cpar devices this instrument
%    database needs to be initialized, which is done with this function.
%    This initialization must be performed before any other functions in 
%    the toolbox is used.
%
%    Calling this function twice or several times will produce a warninng
%    that the instrument database is allready initialized, however, nothing
%    bad will result from this and it will not interfere with the operation
%    of the toolbox.
%
% See also, cparList, cparGetDevice
config = cparLibraryInfo;
AddLibrary(config, 'LabBench.Instruments.dll')
AddLibrary(config, 'LabBench.Instruments.CPAR.dll')

try
    LabBench.Instruments.InstrumentDB.Create();    
catch exception    
    fprintf("Warning: %s\n", exception.ExceptionObject.Message)
end

function AddLibrary(config, library)
    DriverPath = fullfile(config.library_path, library);   
    NET.addAssembly(DriverPath);
