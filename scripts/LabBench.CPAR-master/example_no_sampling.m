% Initialize the LabBench Instrument Database
%
% If the script is called multiple times, then this will produce a warning
% that the instrument database is allready initialized. This has no bad
% consequences.
cparInitialize;

try
    % Next step is to retrieve the cpar device. We do this by assuming that
    % there is only one cpar device installed on the system, by retrieving all
    % the IDs of cpar devices from LabBench, and the getting the first device
    % on the list.
    %
    % If there is more than one cpar device on the machine this code needs to
    % be rewritten and the device ID must be known and inserted into the
    % script.
    IDs = cparList;
    dev = cparGetDevice(IDs(1));

    % The first time the script is run it will take some time for the LabBench
    % Instrument Database to open a connection to the cpar device after the
    % cparGetDevice is called. We therefore wait until the error is cleared on
    % the device, which signals that a connection has been established and it
    % is ready to use.
    fprintf('Waiting to connect .');
    tic
    while cparError(dev)
        fprintf('.');
        pause(0.2);

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
    
    % Create the pressure waveforms one for each pressure outlet 1 and 2.
    %
    % An empty waveform is first created with the cparCreateWaveform
    % function, which as argument takes which pressure outlet to use (1 or
    % 2) and how many times the waveform shall be repeated.
    %
    % Afterwards the waveform is populated with instructions that are used
    % by the waveform interpreter in the cpar device to generate the
    % pressure waveform. There are three instructions; step, dec, and inc.
    waveform01 = cparCreateWaveform(1, 1);
    
    % This creates a immediate change (step) in the pressure. In this case
    % the pressure is set to 20kPa. The second argument is the number of
    % seconds that the pressure is held for before the next instruction is
    % executed. In this case the time is zero, which means that the next
    % instruction is executed immediately in the execution cycle as this
    % step instruction.
    cparWaveform_Step(waveform01, 20, 0);
    
    % This creates a linearly increasing pressure with a slope of 30kPa/s
    % for onle second. It is possible to set its duration to 0s, but
    % then the instruction would have no effect.
    cparWaveform_Inc(waveform01, 30, 1);
    
    % This creates a linearly decreasing pressure with a slope of 20kPa/s
    % for one second.
    cparWaveform_Dec(waveform01, 20, 1);
   
    % We create an empty waveform for the second pressure outlet of the
    % CPAR device. This is to ensure that there is no waveform configured
    % for that pressure outlet, and hence, no stimulation is given on the
    % cuff connected to pressure outlet 2.
    waveform02 = cparCreateWaveform(2, 1);   
    
    % This sets the pressure waveforms for pressure outlet 1 and 2. Both
    % waveforms must be set at the same time to ensure that there is not an
    % old waveform stored in one outlet, thereby, leading to an unintended
    % pressure stimulation.
    cparSetWaveform(dev, waveform01, waveform02);

    fprintf('Running pressure stimulation ');

    % Start the stimulation    
    % This will start the stimulation even if the VAS score is not set to
    % zero. The stimulation is stopped when either the pressure waveform
    % programs is completed or the subject presses the button.
    %
    % This also implicitly starts the collection of data, which can be
    % retrived with the cparGetData function.
    cparStart(dev, 'bp', true);    
    cparStopSampling(dev);
   
    % Wait until stimulation has completed
    while (cparIsRunning(dev))
        fprintf('.');
        pause(0.2);        
    end
    fprintf(' completed\n'); 

catch me
    me
end
