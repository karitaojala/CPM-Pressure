% these settings are supposed to override those from InstantiateParameters; use is mainly for troubleshooting

function O = InstantiateOverrides

[~, tmp]                  = system('hostname');
hostname                  = deblank(tmp);

O = struct;
O.startingSession       = 1; % 1 is default; using 2 skips first session
O.startingTrial         = 1; % use for interrupted protocols
O.preserveETCalib       = 0; % 1 to preserve existing eyetracker calibration
O.debug.toggle          = 0; % 0 is default (full protocol - ports etc. toggled on)
O.debug.toggleVisual    = 0; % 0 is default (full protocol - visual interface toggled on)
O.language              = 'de';
O.path.experiment       = [];
if O.debug.toggleVisual
    O.display.screen    = []; % to avoid PTB error when debugging without visuals on one screen setup
else
    if strcmp(hostname,'isnb05cda5ba721') % own laptop
        O.display.screen    = 1;
    else % other computers
        O.display.screen    = 2; % 2 is default; use [] for one screen setup...
    end
end
O.sound.deviceId        = [];
O.sound.step2Range      = [];
O.pain.step2Range       = [];
if strcmp(hostname,'isnb05cda5ba721')
    O.devices.trigger       = 0;
else
    O.devices.trigger       = 1;
end
O.devices.arduino       = 0; % if no override is desired, comment out or rmfield in project-specific scripts (isfield query); ANY entry in this variable will suppress arduino initialization
% O.devices.trigger  = 0;
O.devices.eyetracker    = 0; % if no override is desired, comment out or rmfield in project-specific scripts (isfield query); ANY entry in this variable will suppress eyetracker initialization
