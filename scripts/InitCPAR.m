function [abort,dev] = InitCPAR()

abort = 0;

cparInitialize; % initialize CPAR
CPARid = cparList; % get CPAR device id

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
fprintf(' connected\n');

% Check if the device is ready
if ~cparIsReady(dev)
    me = MException('CPAR:Ready', sprintf('Device is not ready: %s', cparGetAdvice(dev)));
    throw(me)
end
        
if isempty(dev); abort = 1; end

end