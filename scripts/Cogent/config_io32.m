function config_io32

global cogent;

%create IO64 interface object
cogent.io.ioObj = io32();

%install the inpoutx64.dll driver
%status = 0 if installation successful
cogent.io.status = io32(cogent.io.ioObj);
if(cogent.io.status ~= 0)
    disp('inp/outp installation failed!')
end
