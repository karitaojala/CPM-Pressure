%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conditioned pain modulation (CPM) experiment with cuff algometry
% - Find rough ballpark of pain threshold
% - Tonic fluctuating pain on left arm
% - Phasic pain on right arm
% - Rating of stimulus intensity (VAS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Changelog
%
% Version: 1.0
% Author: Karita Ojala, k.ojala@uke.de, University Medical Center Hamburg-Eppendorf
%   Original script for calibrating thermal pain (some parts used here):
%   Bjoern Horing, University Medical Center Hamburg-Eppendorf
% Date: 2021-02-18
%
% Version notes
% 1.0

function Experiment_CPM_Pressure_Fluct

clear all %#ok<CLALL>
% clear mex global functions;         %#ok<CLMEX,CLFUNC>
P = InstantiateParameters; % load default parameters for comparable projects (should not ever be changed)
O = InstantiateOverrides; % load overrides used for testing (e.g., deactivating PTB output or other troubleshooting)

addpath(cd);
addpath(P.path.experiment)
addpath(genpath(P.path.PTB))
if ~O.debug.toggleVisual
    Screen('Preference', 'TextRenderer', 0);
    %Screen('Preference', 'SkipSyncTests', 1);
end

P.time.stamp = datestr(now,30);
P.time.scriptStart = GetSecs;

if ~isempty(O.language)
    P.language = O.language;
end

if ~any(strcmp(P.language,{'de','en'}))
    fprintf('Instruction language "%s" not recognized. Aborting...',P.language);
    QuickCleanup(P);
    return;
end

if ~P.protocol.sbId % this shouldn't ever be the case since InstantiateParameters provides an sbId (99)
    ListenChar(0); % activate keyboard input
    commandwindow;
    P.protocol.sbId=input('Please enter subject ID.\n');
    ListenChar(2); % deactivate keyboard input
else
    ListenChar(2); % deactivate keyboard input
end

if P.protocol.sbId==99
    O.debug.toggle = 1; % sbId 99 triggers debug mode to reduce number of trials and trial length for faster testing
end

if ~O.debug.toggle
    clear functions; %#ok<CLFUNC>
end

[P,O] = SetInput(P,O);
[P,O] = SetPTB(P,O);
[P,O] = SetParameters(P,O);
[P,O] = SetPaths(P,O);

% Save instantiated parameters and overrides
paramFile = fullfile(P.out.dir,['parameters_sub' sprintf('%03d',P.protocol.sbId) '.mat']);
if exist(paramFile,'file')
    loadParams = load(paramFile);
    P = loadParams.P;
    O = loadParams.O;
else
    save(paramFile,'P','O');
end

%%%%%%%%%%%%%%%%%%%%%%%
% Section selection (skip sections if desired)
[abort,P]=StartExperimentAt(P,'Start experiment? ');
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT START
%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%
% PREEXPOSURE
if P.startSection == 1
    [abort]=ShowInstruction(P,O,1,1);
    if abort;return;end
    [abort]=Preexposure(P,O);
end
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%
% CALIBRATION
if P.startSection == 2
    [abort]=ShowInstruction(P,O,2,1);
    if abort;return;end
    [abort]=CalibrationPressure(P,O);
end
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%
% CONDITIONED PAIN MODULATION EXPERIMENT
if P.startSection == 3
    
    ListenChar(0); % activate keyboard input
    commandwindow;
    pressure_input=input('\nHow to define pressure levels for the experiment: 1 = From calibration, 2 = From input, 3 = From instantiated parameters file\n');
    ListenChar(2); % deactivate keyboard input
    
    [abort]=ShowInstruction(P,O,3,1);
    if abort;return;end
    [abort] = CondPainMod(P,O,pressure_input);
    
end
if abort;QuickCleanup(P);return;end

if P.startSection == 4
    fprintf('\nExperiment ending.');
    [abort]=ShowInstruction(P,O,4);
    if abort;return;end
end

if abort;QuickCleanup(P);return;end

sca;
ListenChar(0);

%%%%%%%%%%%%%%%%%%%%%%%
% END
%%%%%%%%%%%%%%%%%%%%%%%

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        FUNCTIONS COLLECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZATION FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%

function [P,O] = SetInput(P,O)

%===================================
% input
P.keys = [];
P.keys.keyList                 = KbName('KeyNames');

if strcmp(P.env.hostname,'stimpc1') % curdes button box single diamond (HID NAR 12345)
    %KbName('UnifyKeyNames');
    P.keys.painful            = KbName('4$');
    P.keys.notPainful         = KbName('2@');
    P.keys.pause              = KbName('space');
    P.keys.resume             = KbName('return');
    P.keys.left               = KbName('2@'); % yellow button
    P.keys.right              = KbName('4$'); % red button
    P.keys.confirm            = KbName('3#'); % green button
    try
        P.keys.abort              = KbName('esc'); % alias of P.keys.esc
        P.keys.esc                = KbName('esc'); % alias of P.keys.abort
    catch
        P.keys.abort              = KbName('Escape');
        P.keys.esc                = KbName('Escape');
    end
else
    KbName('UnifyKeyNames');
    P.keys.painful            = KbName('y');
    P.keys.notPainful         = KbName('n');
    P.keys.pause              = KbName('Space');
    P.keys.resume             = KbName('Return');
    P.keys.confirm            = KbName('Return');
    P.keys.right              = KbName('RightArrow');
    P.keys.left               = KbName('LeftArrow');
    try
        P.keys.abort              = KbName('Escape'); % alias of P.keys.esc
        P.keys.esc                = KbName('Escape'); % alias of P.keys.abort
    catch
        P.keys.abort              = KbName('esc');
        P.keys.esc                = KbName('esc');
    end
end

end

function [P,O] = SetPaths(P,O)
%===================================
% output

if ~isempty(O.path.experiment)
    P.path.experiment = O.path.experiment;
end
P.out.dir = fullfile(P.path.experiment,P.project.part,'logs',['sub' sprintf('%03d',P.protocol.sbId)],'pain');
if ~exist(P.out.dir,'dir')
    mkdir(P.out.dir);
end

P.out.file.CPAR = ['sub' sprintf('%03d',P.protocol.sbId) '_CPAR'];
P.out.file.VAS = ['sub' sprintf('%03d',P.protocol.sbId) '_VAS'];
fprintf('Saving data to %s%s.\n',P.out.dir,P.out.file.CPAR);
fprintf('Saving data to %s%s.\n',P.out.dir,P.out.file.VAS);

end

%% Set Up the PTB with parameters and initialize drivers (based on function by Selim Onat/Alex Tinnermann)
function [P,O] = SetPTB(P,O)

% Graphical interface vars
screens                     =  Screen('Screens');                  % Find the number of the screen to be opened
if isempty(O.display.screen)
    P.display.screenNumber  =  max(screens);                       % The maximum is the second monitor
else
    P.display.screenNumber  =  O.display.screen;
end
P.display.screenRes = Screen('resolution',P.display.screenNumber);

P.style.fontname                = 'Arial';
P.style.fontsize                = 30;
P.style.linespace               = 10;
P.style.white                   = [255 255 255];
P.style.red                     = [255 0 0];
P.style.backgr                  = [70 70 70];
P.style.widthCross              = 3;
P.style.sizeCross               = 20;

%%%%%%%%%%%%%%%%%%%%%%%%%%% Default parameters
%         Screen('Preference', 'SkipSyncTests', O.debug.toggle);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'DefaultFontSize', P.style.fontsize);
Screen('Preference', 'DefaultFontName', P.style.fontname);
%Screen('Preference', 'TextAntiAliasing',2);                       % Enable textantialiasing high quality
Screen('Preference', 'VisualDebuglevel', 0);                       % 0 disable all visual alerts
Screen('Preference', 'SuppressAllWarnings', 0);
beep off;

%%%%%%%%%%%%%%%%%%%%%%%%%%% Open a graphics window using PTB
if ~O.debug.toggleVisual
    P.display.w                     = Screen('OpenWindow', P.display.screenNumber, P.style.backgr);
    Screen('Flip',P.display.w);                                            % Make the bg
end

P.display.rect                  = [0 0 P.display.screenRes.width P.display.screenRes.height];
P.display.midpoint              = [P.display.screenRes.width./2 P.display.screenRes.height./2];   % Find the mid position on the screen.

P.style.startY                = P.display.screenRes.height*P.display.startY;
P.style.lineheight = P.style.fontsize + P.style.linespace;

P.style.whiteFix1 = [P.display.midpoint(1)-P.style.sizeCross P.style.startY-P.style.widthCross P.display.midpoint(1)+P.style.sizeCross P.style.startY+P.style.widthCross];
P.style.whiteFix2 = [P.display.midpoint(1)-P.style.widthCross P.style.startY-P.style.sizeCross P.display.midpoint(1)+P.style.widthCross P.style.startY+P.style.sizeCross];

end

function [P,O] = SetParameters(P,O)

% Apply some overrides
if isfield(O.devices,'arduino') % then no arduino use is desired
    P.devices.arduino = 0;
end

% Define outgoing port address
if strcmp(P.env.hostname,'stimpc1')
    %P.com.lpt.CEDAddressThermode = 888; % CHECK IF STILL ACCURATE
    P.com.lpt.CEDAddressSCR     = 36912; % as per new stimPC; used to be =P.com.lpt.CEDAddressThermode;
else
    P.com.lpt.CEDAddressSCR = 888;
end
P.com.lpt.CEDDuration           = 0.005; % wait time between triggers

if strcmp(P.env.hostname,'stimpc1')
    P.com.lpt.pressureOnsetTHE      = 36; % this covers both CHEPS trigger (4) and SCR/Spike (32)
    if P.devices.arduino
        P.com.lpt.pressureOnset      = 32;
    else % note: without arduino, this is NOT necessary on stimpc setup because there is no separate SCR recording device, just spike; therefore, do it with pressureOnsetTHE
        P.com.lpt.pressureOnset      = 0;
    end
    P.com.lpt.VASOnset          = 128; % we'll figure this out later
    P.com.lpt.ITIOnset          = 128; % we'll figure this out later
    P.com.lpt.cueOnset          = 128; % we'll figure this out later
else
    %     P.com.lpt.cueOnset      = 1; % bit 1; cue onset
    P.com.lpt.pressureOnset = 1; %4; % bit 3; pressure trigger for SCR
    P.com.lpt.VASOnset      = 2; %8; % bit 5;
    P.com.lpt.ITIOnset      = 3; %16; % bit 6; white fixation cross
    P.com.lpt.buttonPress   = 4; % button press
end

% Establish parallel port communication.
if P.devices.trigger
    config_io;
    WaitSecs(P.com.lpt.CEDDuration);
    outp(P.com.lpt.CEDAddressSCR,0);
    WaitSecs(P.com.lpt.CEDDuration);
end

if P.devices.arduino
    try
        addpath(genpath(P.path.cpar))
    catch
        warning('CPAR scripts not found in %s. Aborting.',P.path.cpar);
    end
end

end

function [abort,P]=StartExperimentAt(P,query)

abort=0;

P.keys.n1                 = KbName('1!'); % | Preexposure | Calibration | CPM experiment | Finish
P.keys.n2                 = KbName('2@'); % | Calibration | CPM experiment | Finish
P.keys.n3                 = KbName('3#'); % | CPM experiment | Finish
P.keys.n4                 = KbName('4$'); % | Finish
keyN1Str = upper(char(P.keys.keyList(P.keys.n1)));
keyN2Str = upper(char(P.keys.keyList(P.keys.n2)));
keyN3Str = upper(char(P.keys.keyList(P.keys.n3)));
keyN4Str = upper(char(P.keys.keyList(P.keys.n4)));
keyEscStr = upper(char(P.keys.keyList(P.keys.esc)));

fprintf('%sIndicate which step you want to start at for\n(%s Preexposure => %s Calibration => %s CPM experiment => %s Finish. [%s] to abort.\n',query,keyN1Str(1),keyN2Str(1),keyN3Str(1),keyN4Str(1),keyEscStr);

P.startSection = 0;
while 1
    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        if find(keyCode) == P.keys.n1
            P.startSection=1;
            break;
        elseif find(keyCode) == P.keys.n2
            P.startSection=2;
            break;
        elseif find(keyCode) == P.keys.n3
            P.startSection=3;
            break;
        elseif find(keyCode) == P.keys.n4
            P.startSection=4;
            break;
        elseif find(keyCode) == P.keys.esc
            P.startSection=0;
            abort=1;
            break;
        end
    end
end

WaitSecs(0.2); % wait in case of a second query immediately after this

end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORE FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%

function [abort]=ShowInstruction(P,O,section,displayDuration)

if ~O.debug.toggleVisual
    Screen('Preference', 'TextRenderer', 0);
end

if nargin<4
    displayDuration = 0; % toggle to display seconds that instructions are displayed in command line
end

abort = 0;
upperEight = P.display.screenRes.height*P.display.Ytext;

if ~O.debug.toggleVisual
    
    if section == 1
        
        fprintf('Ready PREEXPOSURE protocol.\n');
        if strcmp(P.language,'de')
            if ~P.presentation.sStimPlateauPreexp; dstr = 'sehr kurzen '; else; dstr = ''; end
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Gleich erhalten Sie über die Manschette eine Reihe an', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, [dstr 'Druckereizen, die leicht schmerzhaft sein können.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Wir melden uns gleich, falls Sie noch Fragen haben,', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'danach geht es los!', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            if ~P.presentation.sStimPlateauPreexp; dstr = 'very brief '; else; dstr = ''; end
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['You will now receive a number of ' dstr 'pressure stimuli,'], 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First, the stimuli will be on the left arm, then on the right arm.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each stimulus, you will be asked to press a button', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'to indicate whether the stimulus was painful or not', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Do you have any remaining questions?', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'If not, the measurement will start!', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 2
        
        fprintf('Ready CALIBRATION protocol.\n');
        if strcmp(P.language,'de')
            
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a number of pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First, the stimuli will be long and on the left arm.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Then, the stimuli will be short and on the right arm. ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as instructed.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 3
        
        if strcmp(P.language,'de')
            %             if ~P.toggles.doScaleTransl
            %                 [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Gleich beginnt Teil 2 der Schmerzschwellenmessung.', 'center', upperEight, P.style.white);
            %                 [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            %                 [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie werden konstante Druckereize erhalten.', 'center', upperEight+P.style.lineheight, P.style.white);
            %             else
            %                 [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie werden nun weitere konstante Druckereize erhalten.', 'center', upperEight, P.style.white);
            %             end
            %             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Bitte bewerten Sie jeden Reiz mithilfe ' keyMoreLessPainful], 'center', upperEight+P.style.lineheight, P.style.white);
            %             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und bestätigen mit ' keyConfirm '.'], 'center', upperEight+P.style.lineheight, P.style.white);
            %             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            %             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Es ist SEHR WICHTIG, dass Sie JEDEN der Reize bewerten!', 'center', upperEight+P.style.lineheight, P.style.white);
            %             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            %             [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Gleich geht es los!', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'In a moment, the experiment will start.', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will receive long pressure stimuli on the left arm.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sometimes, a rating scale will appear and you should', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'rate the stimulus for its painfulness CONTINUOUSLY.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'There will sometimes be short pressure stimuli on the right arm.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each short stimulus ends, you should rate its painfulness', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each long stimulus ends, you should rate its pain intensity on the same scale', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'It is very important that you rate each and every stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Please confirm verbally when you have read these instructions.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 4 % end of the test
        
        if strcmp(P.language,'de')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'END', 'center', upperEight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'The test has ended. Thank you for your time!', 'center', upperEight, P.style.white);
        end
        
    end
    
    introTextTime = Screen('Flip',P.display.w);
    
else
    
    introTextTime = GetSecs;
    
end

if displayDuration==1 % then hold it!
    fprintf('Displaying instructions... ');
    countedDown=1;
end

fprintf('\nInput [%s] required to continue, [%s] to abort...\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));

while 1
    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        if find(keyCode) == P.keys.resume
            break;
        elseif find(keyCode) == P.keys.esc
            abort=1;
            break;
        end
    end
    
    if displayDuration==1
        tmp=num2str(SecureRound(GetSecs-introTextTime,0));
        [countedDown] = CountDown(P,GetSecs-introTextTime,countedDown,[tmp ' ']);
    end
end

if displayDuration==1; fprintf('\nInstructions were displayed for %d seconds.\n',SecureRound(GetSecs-introTextTime,0)); end

if ~O.debug.toggleVisual
    Screen('Flip',P.display.w);
end

end

%% Pre-exposure sequence
function [abort]=Preexposure(P,O,varargin)

if nargin<3
    preExpInts = P.pain.preExposure.pressureIntensity;
else % override (e.g. for validation sessions)
    preExpInts = varargin{1};
end

abort=0;
preexPainful = NaN;
P.data.preExposure.painThreshold = [];

fprintf('\n==========================\nRunning preexposure sequence.\n');

while ~abort
    
    for cuff = 1:2 % pre-exposure for both left (1) and right (2) cuffs
        
        if cuff == 1
            side = 'LEFT';
        elseif cuff == 2
            side = 'RIGHT';
        end
        
        fprintf(['Pre-exposure CUFF ' num2str(cuff) ' - ' side '\n']);
        
        for i = 1:length(preExpInts)
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);                      % gets timing of event for PutLog
            else
                tCrossOn = GetSecs;
            end
            
            if i == 1
                fprintf('[Initial trial, showing P.style.white cross for %1.1f seconds, red cross for %1.1f seconds]\n',P.presentation.sPreexpITI,P.presentation.sPreexpCue);
            end
            
            fprintf('Displaying fixation cross... ');
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.ITIOnset);
            
            while GetSecs < tCrossOn + P.presentation.sPreexpITI
                [abort]=LoopBreaker(P);
                if abort; break; end
            end
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            fprintf('%1.1f kPa stimulus initiated.',preExpInts(i));
            
            stimDuration=CalcStimDuration(P,preExpInts(i),P.presentation.sStimPlateauPreexp);
            
            countedDown = 1;
            tStimStart = GetSecs;
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
            
            if P.devices.arduino
                abort = UseCPAR('Init',P.com.arduino); % initialize arduino/CPAR
                abort = UseCPAR('Set','preExp',P,stimDuration,preExpInts(i),cuff); % set stimulus
                abort = UseCPAR('Trigger',P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
                
                while GetSecs < tStimStart+sum(stimDuration)
                    [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,'.');
                    if abort; break; end
                end
                
                abort = UseCPAR('Kill');
                
            else
                
                while GetSecs < tStimStart+sum(stimDuration)
                    [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,'.');
                    if abort; return; end
                end
                
            end
            
            fprintf(' concluded.\n');
            
            if ~O.debug.toggleVisual
                Screen('Flip',P.display.w);
            end
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
            
            if nargin < 3
                preexPainful = QueryPreexPain(P,O);
            end
            
            if preexPainful
                fprintf('Stimulus rated as painful. \n');
            else
                fprintf('Stimulus rated as not painful. \n');
            end
            P.data.preExposure.painRatings(cuff,i) = preexPainful;
            
        end
    
        P.data.preExposure.painThreshold(cuff) = preExpInts(find(P.data.preExposure.painRatings(cuff,:),1,'first'));
        save(fullfile(P.out.dir,['parameters_sub' sprintf('%03d',P.protocol.sbId) '.mat']),'P','O');
        fprintf(['Pre-exposure pain threshold CUFF ' num2str(cuff) ': ' num2str(P.data.preExposure.painThreshold(cuff)) ' kPa\n']);
        
    end
    
    break;

end

end

function preexPainful = QueryPreexPain(P,O)

if strcmp(P.env.hostname,'stimpc1')
    if strcmp(P.language,'de')
        keyNotPainful = 'den [linken Knopf]';
        keyPainful = 'den [rechten Knopf]';
    elseif strcmp(P.language,'en')
        keyNotPainful = 'the [left button]';
        keyPainful = 'the [right button]';
    end
else
    if strcmp(P.language,'de')
        keyNotPainful = ['die Taste [' upper(char(P.keys.keyList(P.keys.notPainful))) ']'];
        keyPainful =  ['die Taste [' upper(char(P.keys.keyList(P.keys.painful))) ']'];
    elseif strcmp(P.language,'en')
        keyNotPainful = ['the key [' upper(char(P.keys.keyList(P.keys.notPainful))) ']'];
        keyPainful =  ['the key [' upper(char(P.keys.keyList(P.keys.painful))) ']'];
    end
end

upperEight = P.display.screenRes.height/8;

fprintf('Was this stimulus painful [%s], or not painful [%s]?\n',upper(char(P.keys.keyList(P.keys.painful))),upper(char(P.keys.keyList(P.keys.notPainful))));
if ~O.debug.toggleVisual
    if strcmp(P.language,'de')
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'War dieser Reiz SCHMERZHAFT für Sie?', 'center', upperEight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Falls ja, drücken Sie bitte ' keyPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
        [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Falls nein, drücken Sie bitte ' keyNotPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
    elseif strcmp(P.language,'en')
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Was this stimulus PAINFUL for you?', 'center', upperEight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['If yes, please press ' keyPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
        [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['If no, please press ' keyNotPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
    end
    Screen('Flip',P.display.w);
end

while 1
    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        if find(keyCode) == P.keys.painful
            preexPainful=1;
            break;
        elseif find(keyCode) == P.keys.notPainful
            preexPainful=0;
            break;
        end
    end
end

WaitSecs(0.2);

if ~O.debug.toggleVisual
    Screen('Flip',P.display.w);
end

end

function [abort] = CalibrationPressure(P,O)

abort=0;

while ~abort
    
    if ~isempty(P.data.preExposure.painThreshold)
        painThresholdSaved = P.data.preExposure.painThreshold;
    else
        painThresholdSaved = [];
    end
    
    fprintf('\n==========================\nRunning calibration procedure.\n');
    
    % TONIC STIMULUS CALIBRATION
    % Loop over calibration trials
    
    for calib = 2 % tonic stimuli first, then phasic stimuli (?)
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            if calib == 1
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, 'Calibration long stimuli', 'center', upperHalf, P.style.white);
            else
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, 'Calibration short stimuli', 'center', upperHalf, P.style.white);
            end
            Screen('TextSize', P.display.w, 30);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Rate the pain intensity quickly after each stimulus ends!', 'center', upperHalf, P.style.white);
            introTextOn = Screen('Flip',P.display.w);
        else
            introTextOn = GetSecs;
        end
        
        while GetSecs < introTextOn + P.presentation.BlockStopDuration
            [abort]=LoopBreaker(P);
            if abort; break; end
        end
        
        % Wait for input from experiment to continue
        fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
        
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if find(keyCode) == P.keys.resume
                    break;
                elseif find(keyCode) == P.keys.esc
                    abort = 1;
                    break;
                end
            end
        end
        
        WaitSecs(0.2);
        
        if calib == 1
            trials = P.presentation.Calibration.tonicStim.trials;
            pressureOrder = P.pain.Calibration.tonicStim.pressureOrder;
            pressureChange = P.pain.Calibration.tonicStim.pressureChange;
            durationITI = P.presentation.Calibration.tonicStim.ITI;
        else
            trials = P.presentation.Calibration.phasicStim.trials;
            pressureOrder = P.pain.Calibration.phasicStim.pressureOrder;
            pressureChange = P.pain.Calibration.phasicStim.pressureChange;
            durationITI = P.presentation.Calibration.phasicStim.ITI;
        end
        
        for trial = 1:trials
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            
            if trial == 1 % first trial no intertrial interval
                
                fprintf('\nWaiting for the first stimulus to start... ');
                countedDown = 1;
                while GetSecs < tCrossOn + P.presentation.Calibration.firstTrialWait
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
            % Start trial
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,trials);
            
            % Red fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            clear index
            index = pressureOrder(trial);
            pressureChangeTrial = pressureChange(index);
            if ~isempty(painThresholdSaved)
                painThreshold = painThresholdSaved(calib); % take individual pain threshold from pre-exposure
            else
                painThreshold = P.pain.Calibration.painTresholdPreset(calib); % take preset pain threshold (40 kPa)
            end
            trialPressure = painThreshold+pressureChangeTrial; % Need to make sure that cuff 1 = left = tonic, cuff 2 = right = phasic OR switch if any change
            
            [abort,P]=ApplyStimulusCalibration(P,O,trialPressure,calib,trial); % run stimulus
            save(fullfile(P.out.dir,['parameters_sub' sprintf('%03d',P.protocol.sbId) '.mat']),'P','O'); % Save instantiated parameters and overrides after each trial
            if abort; break; end
            
            % White fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            
            % Intertrial interval if not the last stimulus in the block,
            % if last trial then end trial immediately
            if trial ~= trials
                
                fprintf('\nIntertrial interval... ');
                countedDown = 1;
                while GetSecs < tCrossOn + durationITI
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end
        
    end
    
    break;
    
end

if ~abort
    fprintf(' Calibration finished. \n');
else
    return;
end

end

function [abort,P]=ApplyStimulusCalibration(P,O,trialPressure,calib,trial)

abort = 0;

while ~abort
    
    fprintf(['Stimulus initiated at ' num2str(trialPressure) ' kPa... ']);
    
    if calib == 1
        stimDuration = P.pain.Calibration.tonicStim.stimDuration;
    else
        stimDuration = P.pain.Calibration.phasicStim.stimDuration;
    end
    
    P.time.calibStart(calib,trial) = GetSecs-P.time.scriptStart;
    
    if P.devices.arduino
        
        abort = UseCPAR('Init',P.com.arduino); % initialize arduino/CPAR
        abort = UseCPAR('Set','Calibration',P,trialPressure,calib,trial); % set stimulus
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
        abort = UseCPAR('Trigger',P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
        if abort; return; end
        P.time.calibStimStart(calib,trial) = GetSecs-P.time.scriptStart;
        
        tStimStart = GetSecs;
        while GetSecs < tStimStart+stimDuration+5
            [abort]=LoopBreakerStim(P);
            if abort; break; end
        end
                
        % VAS
        fprintf(' VAS... ');
        tVASStart = GetSecs;
        P.time.calibVASStart(calib,trial) = GetSecs-P.time.scriptStart;
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
        if ~O.debug.toggleVisual; [abort,P] = calibStimVASRating(P,O,calib,trial,trialPressure); end
        P.time.calibStimVASEnd(calib,trial) = GetSecs-P.time.scriptStart;
        if abort; return; end
        
        while GetSecs < tVASStart+P.presentation.Calibration.durationVAS
            [abort]=LoopBreakerStim(P);
            if abort; break; end
        end
        
%         [abort,calibData] = UseCPAR('Data'); % retrieve data
%         SaveData(P,calibData,calib,trial); % save data for this trial
%         fprintf(' Saving CPAR data... ')
        
        abort = UseCPAR('Kill');
        
        if abort; return; end
        
    else
        
        countedDown = 1;
        tStimStart = GetSecs;
        P.time.calibStart(calib,trial) = tStimStart-P.time.scriptStart;
        while GetSecs < tStimStart+stimDuration+5+P.presentation.Calibration.durationVAS
            tmp=num2str(SecureRound(GetSecs-tStimStart,0));
            [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,[tmp ' ']);
            if abort; break; end
            if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
        end
        
        if abort; return; end
        
    end
    
    break;
    
end

if ~abort
    fprintf(' Calibration trial concluded. \n');
else
    return;
end

end

function [abort,P]=calibStimVASRating(P,O,calib,trial,trialPressure)

abort = 0;

while ~abort
    
    [abort,finalRating,reactionTime,keyId,keyTime,response] = singleratingScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_calibration_cuff' num2str(calib) '.mat']);
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    clear calibData
    calibData.trialPressure = trialPressure;
    calibData.finalRating = finalRating;
    calibData.reactionTime = reactionTime;
    calibData.keyId = keyId;
    calibData.keyTime = keyTime;
    calibData.response = response;
    
    if calib == 1
        VAS.tonicStim(trial) = calibData;
    else
        VAS.phasicStim(trial) = calibData;
    end
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end

function [abort] = CondPainMod(P,O,pressure_input)

abort=0;

while ~abort
    
    fprintf('\n==========================\nRunning CPM procedure.\n');
    
    countTrial = 1;
    
    if pressure_input == 1
        
        % Tonic stimulus calibration
        calibFile1 = fullfile(P.out.dir, [P.out.file.VAS '_calibration_cuff1.mat']);
        if exist(calibFile1,'file')
            calibData1 = load(calibFile1);
            truePressureTonicCalib = [calibData1.VAS.tonicStim.trialPressure];
            ratedPainTonicCalib = [calibData1.VAS.tonicStim.finalRating];
        end
        
        % Phasic stimulus calibration
        calibFile2 = fullfile(P.out.dir, [P.out.file.VAS '_calibration_cuff2.mat']);
        if exist(calibFile2,'file')
            calibData2 = load(calibFile2);
            truePressurePhasicCalib = [calibData2.VAS.phasicStim.trialPressure];
            ratedPainPhasicCalib = [calibData2.VAS.phasicStim.finalRating];
        end
         
        % Find VAS 7 and VAS 9 for tonic pressure based on calibration
        format long
        slopePressureRatingTonic = ratedPainTonicCalib'\truePressureTonicCalib';
        TonicVAS7 = round(70*slopePressureRatingTonic);
        TonicVAS9 = round(90*slopePressureRatingTonic);
        tonicPressure_trough_Exp = TonicVAS7;
        tonicPressure_peak_Exp = TonicVAS9;
        
        % Find VAS 7 for phasic pressure
        slopePressureRatingPhasic = ratedPainPhasicCalib'\truePressurePhasicCalib';
        PhasicVAS7 = round(70*slopePressureRatingPhasic);
        phasicPressure = PhasicVAS7;
        
    elseif pressure_input == 2
        
        ListenChar(0); % activate keyboard input
        commandwindow;
        tonicPressure_trough_Exp=input('\nPlease enter tonic pain stimulus trough intensity (kPa) for the experiment.\n');
        ListenChar(2); % deactivate keyboard input
        
        ListenChar(0); % activate keyboard input
        commandwindow;
        tonicPressure_peak_Exp=input('Please enter tonic pain stimulus peak intensity (kPa) for the experiment.\n');
        ListenChar(2); % deactivate keyboard input
        
        ListenChar(0); % activate keyboard input
        commandwindow;
        phasicPressure=input('Please enter phasic pain stimulus intensity (kPa) for the experiment.\n');
        ListenChar(2); % deactivate keyboard input
        
    elseif pressure_input == 3
        
        tonicPressure_trough_Exp = P.pain.CPM.tonicStim.pressureTrough;
        tonicPressure_peak_Exp = P.pain.CPM.tonicStim.pressurePeak;
        phasicPressure = P.pain.CPM.phasicStim.pressure;
        
    end
    
    tonicPressure_trough_Control = P.pain.CPM.tonicStim.pressureTroughControl;
    tonicPressure_peak_Control = P.pain.CPM.tonicStim.pressurePeakControl;
        
    % Loop over blocks/runs
    for block = 1:P.presentation.CPM.blocks
        
        % Set tonic stimulus pressure
        if P.pain.CPM.tonicStim.condition(block) == 1 % experimental tonic stimulus
            tonicPressure_trough = tonicPressure_trough_Exp;
            tonicPressure_peak = tonicPressure_peak_Exp;
        
        elseif P.pain.CPM.tonicStim.condition(block) == 0 % control tonic stimulus
            tonicPressure_trough = tonicPressure_trough_Control;
            tonicPressure_peak = tonicPressure_peak_Control;
        end
        
        trialPressure = [tonicPressure_trough tonicPressure_peak phasicPressure]; % input to UseCPAR and CreateCPARStimulus
        
        % Start block
        fprintf('\n\n=======BLOCK %d of %d=======\n',block,P.presentation.CPM.blocks);
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ['Block ' num2str(block)], 'center', upperHalf, P.style.white);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
            introTextOn = Screen('Flip',P.display.w);
        else
            introTextOn = GetSecs;
        end
        
        while GetSecs < introTextOn + P.presentation.BlockStopDuration
            [abort]=LoopBreaker(P);
            if abort; break; end
        end
        
        % Wait for input from experiment to continue
        fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
        
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if find(keyCode) == P.keys.resume
                    break;
                elseif find(keyCode) == P.keys.esc
                    abort = 1;
                    break;
                end
            end
        end
        
        WaitSecs(0.2);
        
        if ~O.debug.toggleVisual
            Screen('Flip',P.display.w);
        end
        
        % Loop over trials
        for trial = 1:P.presentation.CPM.trialsPerBlock
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
                
            if trial == 1 % first trial no intertrial interval
               
                fprintf('\nWaiting for the first stimulus to start... ');
                countedDown = 1;
                while GetSecs < tCrossOn + P.presentation.CPM.tonicStim.firstTrialWait
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
%                     WaitSecs(1);
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
            % Start trial
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,P.presentation.CPM.trialsPerBlock);
            
            % Red fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            [abort,P]=ApplyStimulus(P,O,trialPressure,block,trial); % run stimulus
            save(fullfile(P.out.dir,['parameters_sub' sprintf('%03d',P.protocol.sbId) '.mat']),'P','O'); % Save instantiated parameters and overrides after each trial
            % (includes timing information)
            if abort; break; end
            
            countTrial = countTrial+1;
            
            % White fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            
            % Intertrial interval if not the last stimulus in the block,
            % if last trial then end trial immediately
            if trial ~= P.presentation.CPM.trialsPerBlock
                
                fprintf('\nIntertrial interval... ');
                countedDown = 1;
                while GetSecs < tCrossOn + P.presentation.CPM.tonicStim.totalITI
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                    if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
%                     WaitSecs(1);
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end

        % Interblock interval
        if block ~= P.presentation.CPM.blocks
            % Text for finishing a block
            if ~O.debug.toggleVisual
                [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Stimulus block finished. Wait for the next block.', 'center', upperHalf, P.style.white);
                outroTextOn = Screen('Flip',P.display.w);
            else
                outroTextOn = GetSecs;
            end
            
            while GetSecs < outroTextOn + P.presentation.CPM.blockBetweenText % wait the time between blocks
                tmp=num2str(SecureRound(GetSecs-outroTextOn,0));
                [abort,countedDown]=CountDown(P,GetSecs-outroTextOn,countedDown,[tmp ' ']);
                if abort; break; end
%                 WaitSecs(1);
            end
        
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            fprintf('\nInterblock interval... ');
            countedDown = 1;
            while GetSecs < tCrossOn + (P.presentation.CPM.blockBetweenTime - P.presentation.CPM.blockBetweenText) % wait the time between blocks
                tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                [abort,countedDown]=CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                if abort; break; end
                if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
%                 WaitSecs(1);
            end
            
            if abort; return; end
            
        elseif block == P.presentation.CPM.blocks % if last block, show end of the experiment screen
            
            if ~O.debug.toggleVisual
                [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'This part of the test has ended. Please wait for further instruction.', 'center', upperHalf, P.style.white);
                %             endTextOn = Screen('Flip',P.display.w);
            end
            
            fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
            
            while 1
                [keyIsDown, ~, keyCode] = KbCheck();
                if keyIsDown
                    if find(keyCode) == P.keys.resume
                        break;
                    elseif find(keyCode) == P.keys.esc
                        abort = 1;
                        break;
                    end
                end
            end
            
            fprintf('\n==========================\nCPM test has ended. ');
            
        end
        
    end
    
    break;
    
end

end

function [abort,P]=ApplyStimulus(P,O,trialPressure,block,trial)

abort = 0;

while ~abort
    
    fprintf(['Tonic stimulus initiated (' num2str(trialPressure(1)) ' to ' num2str(trialPressure(2)) ' kPa)... ']);
    
    phasic_on = P.pain.CPM.phasicStim.on(block);
    
    P.time.trialStart(block,trial) = GetSecs-P.time.scriptStart;
    
    if P.devices.arduino
        
        abort = UseCPAR('Init',P.com.arduino); % initialize arduino/CPAR
        abort = UseCPAR('Set','CPM',P,trialPressure,phasic_on,block,trial); % set stimulus
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
        abort = UseCPAR('Trigger',P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
        if abort; return; end
        P.time.tonicStimStart(block,trial) = GetSecs-P.time.scriptStart;
        tStimStart = GetSecs;
        
        % VAS
        if ~phasic_on
            
            fprintf(' VAS... ');
            P.time.tonicStimVASStart(block,trial) = GetSecs-P.time.scriptStart;
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
            if ~O.debug.toggleVisual; [abort,P] = tonicStimVASRating(P,O,block,trial); end
            P.time.tonicStimVASEnd(block,trial) = GetSecs-P.time.scriptStart;
            if abort; return; end
            
        else
            
            phasicOnsets = P.pain.CPM.phasicStim.onsets(block,trial,:,:);
            phasicOnsets = sort(phasicOnsets(:));
            
            for phasicStim = 1:P.pain.CPM.tonicStim.cycles*P.pain.CPM.phasicStim.stimPerCycle
                
                VASOnset = tStimStart + phasicOnsets(phasicStim) + P.pain.CPM.phasicStim.duration + P.presentation.CPM.phasicStim.waitforVAS;
                while GetSecs < VASOnset
                    % Wait until VAS onset for this cycle/phasic stimulus
                    [abort]=LoopBreakerStim(P);
                    if abort; break; end
                end
                fprintf([' VAS (' num2str(phasicStim) '/' num2str(P.pain.CPM.tonicStim.cycles*P.pain.CPM.phasicStim.stimPerCycle) ')... ']);
                P.time.phasiccStimVASStart(block,trial,phasicStim) = GetSecs-P.time.scriptStart;
                SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
                if ~O.debug.toggleVisual; [abort,P] = phasicStimVASRating(P,O,block,trial,phasicStim); end
                P.time.phasicStimVASEnd(block,trial,phasicStim) = GetSecs-P.time.scriptStart;
                
                if abort; return; end
                
                % Red fixation cross
                if ~O.debug.toggleVisual
                    Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                    Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                    Screen('Flip',P.display.w);
                end
            
                if abort; break; end
                
            end
            
        end
        
        if abort; return; end
        
        while GetSecs < tStimStart+P.presentation.CPM.tonicStim.durationVAS%+P.presentation.CPM.tonicStim.durationBuffer
            [abort]=LoopBreakerStim(P);
            if abort; break; end
        end
        
        [abort,trialData] = UseCPAR('Data'); % retrieve data
        SaveData(P,trialData,block,trial); % save data for this trial
        fprintf(' Saving CPAR data... ')
        
        abort = UseCPAR('Kill');
        
        if abort; return; end
        
    else
        
        countedDown = 1;
        tStimStart = GetSecs;
        P.time.tonicStimStart(block,trial) = tStimStart-P.time.scriptStart;
        while GetSecs < tStimStart+P.presentation.CPM.tonicStim.durationVAS%+P.presentation.CPM.tonicStim.durationBuffer
            tmp=num2str(SecureRound(GetSecs-tStimStart,0));
            [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,[tmp ' ']);
            if abort; break; end
            if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
        end
        
        if abort; return; end
        
    end
    
    break;
    
end

if ~abort
    fprintf(' Trial concluded. \n');
else
    return;
end

end

function [abort,P]=tonicStimVASRating(P,O,block,trial)

abort = 0;

while ~abort
    
    [abort,conRating,conTime,keyId,response] = onlineScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_rating_block' num2str(block) '.mat']);
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    tonicStim.conRating = conRating;
    tonicStim.conTime = conTime;
    tonicStim.keyId = keyId;
    tonicStim.response = response;
    
    VAS(trial).tonicStim = tonicStim;
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end

% Phasic stimulus pain rating with one-off VAS during interstimulus
% interval
function [abort,P]=phasicStimVASRating(P,O,block,trial,stim)

abort = 0;

while ~abort
    
    [abort,finalRating,reactionTime,keyId,keyTime,response] = singleratingScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_rating_block' num2str(block) '.mat']);
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    phasicStim.finalRating = finalRating;
    phasicStim.reactionTime = reactionTime;
    phasicStim.keyId = keyId;
    phasicStim.keyTime = keyTime;
    phasicStim.response = response;
    
    VAS(trial,stim).phasicStim = phasicStim;
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end

% Save CPAR data
function SaveData(P,trialData,block,trial)

try
    dataFile = fullfile(P.out.dir,[P.out.file.CPAR '_block' num2str(block) '.mat']);
    if exist(dataFile,'file')
        loadedData = load(dataFile);
        cparData = loadedData.cparData;
    end
    
    cparData(trial).data = trialData;
    
    if ~isempty(cparData) && ~isempty(trialData)
        save(dataFile,'cparData');
    end
catch
    fprintf(['Saving trial ' num2str(trial) 'data failed.\n']);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%
% AUXILIARY FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%

%% Returns a vector with riseTime, P.presentation.sStimPlateau and fallTime for the target stimulus
function [stimDuration] = CalcStimDuration(P,pressure,sStimPlateau)
%diff=abs(temp-P.pain.bT);
%riseTime=diff/P.pain.rS;
riseTime = pressure/P.pain.preExposure.riseSpeed;
%fallTime=diff/P.pain.fS;
%stimDuration=[riseTime sStimPlateau fallTime];
stimDuration = [riseTime sStimPlateau];% only rise time
end

%% Set Marker for CED and BrainVision Recorder
function SendTrigger(P,address,port)
% Send pulse to CED for SCR, thermode, digitimer
% [handle, errmsg] = IOPort('OpenSerialport',num2str(port)); % gives error
% msg on grahl laptop
if P.devices.trigger
    outp(address,port);
    WaitSecs(P.com.lpt.CEDDuration);
    outp(address,0);
    WaitSecs(P.com.lpt.CEDDuration);
end

end

%% display string during countdown
function [abort,countedDown]=CountDown(P, secs, countedDown, countString)

if secs>countedDown
    fprintf('%s', countString);
    countedDown=ceil(secs);
    WaitSecs(1);
end

[abort] = LoopBreakerStim(P);
if abort; return; end

end

%% Use so the experiment can be aborted with proper key presses
function [abort]=LoopBreaker(P)
abort=0;
[keyIsDown, ~, keyCode] = KbCheck();
if keyIsDown
    if find(keyCode) == P.keys.esc
        abort=1;
        return;
    elseif find(keyCode) == P.keys.pause
        fprintf('\nPaused, press [%s] to resume.\n',upper(char(P.keys.keyList(P.keys.resume))));
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if find(keyCode) == P.keys.resume
                    break;
                end
            end
        end
    end
end
end

function [abort]=LoopBreakerStim(P)
abort=0;
[keyIsDown, ~, keyCode] = KbCheck();
if keyIsDown
    if find(keyCode) == P.keys.esc
        abort=1;
    end
end
end

%% Make sure round works across MATLAB versions
function [y]=SecureRound(X, N)
try
    y=round(X,N);
catch EXC %#ok<NASGU>
    %disp('Round function  pre 2014 !');
    y=round(X*10^N)/10^N;
end
end

%% Cleanup when aborting script
function QuickCleanup(P)

fprintf('\nAborting...');

Screen('CloseAll');

if P.devices.arduino && exist('dev','var')
    UseCPAR('Kill');
end

sca; % close window; also closes io64
ListenChar(0); % use keys again
commandwindow;

end
