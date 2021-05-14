function [abort]=ShowInstruction(P,O,section,displayDuration)

if ~O.debug.toggleVisual
    Screen('Preference', 'TextRenderer', 0);
end

% if nargin<4
%     displayDuration = 0; % toggle to display seconds that instructions are displayed in command line
% end

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
%             if ~P.presentation.sStimPlateauPreexp; dstr = 'very brief '; else; dstr = ''; end
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['You will now receive a number of pressure stimuli,'], 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The stimuli will be on one arm at a time but ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' the starting arm is different for each participant.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The stimuli on the left arm will be long and ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' the the stimuli on the right arm will be short.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each stimulus, you will be asked to press a button', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'to indicate whether the stimulus was painful or not', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Do you have any remaining questions?', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'If not, the measurement will start!', 'center', upperEight+P.style.lineheight, P.style.white);
        end
    
    elseif section == 2
        
        fprintf('Ready VAS TRAINING protocol.\n');
        if strcmp(P.language,'de')
            
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now train in rating the pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'with a visual scale on the screen, but with no pressure yet.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '0 is no pain, 1 is minimal pain, 100 is unbearable pain.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Left arrow decreases rating, right arrow increases rating.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'During the experiment, you should rate each stimulus on their painfulness.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 3
        
        fprintf('Ready PSYCHOMETRIC SCALING protocol.\n');
        if strcmp(P.language,'de')
            
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a few more stimuli on either arm,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which range in their intensity from low to high pain.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First, all stimuli will be applied on one arm, and then on the other.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Again, left arm will get long stimuli and right arm short stimuli.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as instructed.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 4
        
        fprintf('Ready VAS TARGET REGRESSSION protocol.\n');
        if strcmp(P.language,'de')
            
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a number of varying pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First, the stimuli will be long and on the left arm.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Then, the stimuli will be short and on the right arm. ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as before.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 5
        
        fprintf('Ready CONDITIONED PAIN MODULATION protocol.\n');
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
        
    elseif section == 6 % end of the test
        
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

function [y]=SecureRound(X, N)
try
    y=round(X,N);
catch EXC %#ok<NASGU>
    %disp('Round function  pre 2014 !');
    y=round(X*10^N)/10^N;
end
end