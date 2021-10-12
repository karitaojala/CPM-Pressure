%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conditioned pain modulation (CPM) experiment with cuff algometry
% - Find rough ballpark of pain threshold
% - Tonic fluctuating pain on right/left LEG
% - Phasic pain on left/right ARM
% - Rating of stimulus intensity (VAS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Changelog
%
% Version: 2.0
% Author: Karita Ojala, k.ojala@uke.de, University Medical Center Hamburg-Eppendorf
%   Original script for calibrating thermal pain (some parts used here):
%   Bjoern Horing, University Medical Center Hamburg-Eppendorf
% Date: 2021-10-06
%
% Version notes
% 1.0

function Experiment_CPM_Pressure_Fluct

clear all %#ok<CLALL>
restoredefaultpath
global dev

addpath(cd);

% clear mex global functions;         %#ok<CLMEX,CLFUNC>
P = InstantiateParameters; % load default parameters for comparable projects (should not ever be changed)
O = InstantiateOverrides; % load overrides used for testing (e.g., deactivating PTB output or other troubleshooting)

addpath(genpath(P.path.scriptBase))
addpath(P.path.experiment)
addpath(genpath(P.path.PTB))
addpath(fullfile(P.path.PTB,'PsychBasic','MatlabWindowsFilesR2007a'))

% if ~O.debug.toggleVisual
% %     Screen('Preference', 'TextRenderer', 0);
%     %Screen('Preference', 'SkipSyncTests', 1);
% end

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
if exist(P.out.file.param,'file')
    loadParams = load(P.out.file.param);
    P = loadParams.P;
else
    save(P.out.file.param,'P','O');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Section selection (skip sections if desired)
[abort,P]=StartExperimentAt(P,'Start experiment? ');
if abort;QuickCleanup(P);return;end

% Initialize CPAR
if P.devices.arduino
    [abort,initSuccess,dev] = InitCPAR; % initialize CPAR
    if initSuccess
        P.cpar.init = initSuccess;
        %P.cpar.dev = dev;
    else
        warning('\nCPAR initialization not successful, aborting!');
        abort = 1;
    end
    if abort;QuickCleanup(P);return;end
end

%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT START %
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREEXPOSURE & AWISZUS
if P.startSection == 1
    [abort]=ShowInstruction(P,O,1,1);
    if abort;return;end
    [abort]=PreExposureAwiszus(P,O);
end
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VAS TRAINING
if P.startSection == 2
    [abort]=ShowInstruction(P,O,2,1);
    if abort;return;end
    [abort]=VASTraining(P,O);
end
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALIBRATION / PSYCHOMETRIC SCALING
if P.startSection == 3
    [abort]=ShowInstruction(P,O,3,1);
    if abort;return;end
    load(P.out.file.param,'P');
    [abort]=PsychometricScaling(P,O);
end
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALIBRATION / VAS TARGET REGRESSION
if P.startSection == 4
    [abort]=ShowInstruction(P,O,4,1);
    if abort;return;end
    load(P.out.file.param,'P');
    [abort]=TargetRegressionVAS(P,O);
end
if abort;QuickCleanup(P);return;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONDITIONED PAIN MODULATION EXPERIMENT
if P.startSection == 5
    
    ListenChar(0); % activate keyboard input
    commandwindow;
    pressure_input=input('\nHow to define pressure levels for the experiment: ... 1 = From calibration, 2 = From input, 3 = From instantiated parameters file\n');
    ListenChar(2); % deactivate keyboard input
    
    load(P.out.file.param,'P');
    [abort]=ShowInstruction(P,O,5,1);
    if abort;return;end
    [abort]=CondPainMod(P,O,pressure_input);
    
end
if abort;QuickCleanup(P);return;end

if P.startSection == 6
    fprintf('\nExperiment ending.');
    [abort]=ShowInstruction(P,O,7); % intentional 7 (not 6), as instructions section 6 corresponds to CPM tonic ratings instruction
    if abort;return;end
end

if abort;QuickCleanup(P);return;end

sca;
ListenChar(0);

%%%%%%%
% END %
%%%%%%%

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        INITIALIZATION FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    P.keys.painful            = KbName('RightArrow');
    P.keys.notPainful         = KbName('LeftArrow');
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

if ~exist(P.out.dir,'dir')
    mkdir(P.out.dir);
end

fprintf('\n\nSaving parameters to %s.\n',P.out.file.param);
fprintf('Saving CPAR data to %s.\n',[P.out.dir '\' P.out.file.CPAR]);
fprintf('Saving VAS data to %s.\n\n',[P.out.dir '\' P.out.file.VAS]);

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

function [abort,P] = StartExperimentAt(P,query)

abort=0;

P.keys.n1                 = KbName('1!'); % | Preexposure & Awiszus
P.keys.n2                 = KbName('2@'); % | VAS rating training
P.keys.n3                 = KbName('3#'); % | Calibration/Psychometric Scaling
P.keys.n4                 = KbName('4$'); % | Calibration/VAS Target Regression
P.keys.n5                 = KbName('5%'); % | Conditioned Pain Modulation Experiment
keyN1Str = upper(char(P.keys.keyList(P.keys.n1)));
keyN2Str = upper(char(P.keys.keyList(P.keys.n2)));
keyN3Str = upper(char(P.keys.keyList(P.keys.n3)));
keyN4Str = upper(char(P.keys.keyList(P.keys.n4)));
keyN5Str = upper(char(P.keys.keyList(P.keys.n5)));
keyEscStr = upper(char(P.keys.keyList(P.keys.esc)));

fprintf('%s Indicate which step you want to start at for: \n%s) Pre-exposure & Awiszus => %s) VAS training => %s) Calibration/Psychometric Scaling => %s) Calibration/VAS Target Regression => %s) CPM experiment. \n[%s] to abort.\n\n',query,keyN1Str(1),keyN2Str(1),keyN3Str(1),keyN4Str(1),keyN5Str(1),keyEscStr);

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
        elseif find(keyCode) == P.keys.n5
            P.startSection=5;
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

%% Cleanup when aborting script
function QuickCleanup(P)

global dev

fprintf('\n\nAborting... ');

Screen('CloseAll');
close all

% load(P.out.file.param,'P');

if ~isempty(dev)
    cparStopSampling(dev);
    cparStop(dev);
    clear dev
    fprintf('CPAR device was stopped.\n');
else
    fprintf('CPAR already stopped or dev does not exist.\n');
end

sca; % close window; also closes io64
ListenChar(0); % use keys again
commandwindow;
end