function [abort,initSuccess,dev] = InitCPAR()

abort = 0;
initSuccess = 0;

try % test if CPAR initialized already
    CPARid = cparList; % get CPAR device id
catch
    cparInitialize; % initialize CPAR if it wasn't done yet
    CPARid = cparList;
end

dev = cparGetDevice(CPARid); % attempt to establish connection to CPAR

% Wait until a connection has been established
fprintf('Waiting to connect CPAR... ');
tic
while cparError(dev)
    pause(0.2);%
    if toc > 10
        me = MException('CPAR:TimeOut', 'No connection');
        throw(me);
    end
end
fprintf(' connected.\n');

% Check if the device is ready
if ~cparIsReady(dev)
    me = MException('CPAR:Ready', sprintf('Device is not ready: %s', cparGetAdvice(dev)));
    throw(me)
end
        
if isempty(dev); abort = 1; else; initSuccess = 1; end

end