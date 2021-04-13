function cparPing(dev, enable)
% cparPing Ping a CPAR device.
%   cparPing(dev, enable) enables ping of the cpar device if [enable] is
%   set to 1. If ping is enabled the connection is also checked and the
%   current ping count is displayed.
%
% See also, cparGetDevice

if enable
    try    
        kicks = dev.Ping();
        dev.PingEnabled = true;
        fprintf('Ping: %d\n', kicks);
    catch
       fprintf('Ping failed\n'); 
    end
else
   dev.PingEnabled = false; 
end