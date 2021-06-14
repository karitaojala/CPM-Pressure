function [abort]=ShowInstruction(P,O,section,displayDuration)

if ~O.debug.toggleVisual
    Screen('Preference', 'TextRenderer', 0);
end

abort = 0;
upperEight = P.display.screenRes.height*P.display.Ytext;

LEFTARM_DE = 'linken';
RIGHTARM_DE = 'rechten';
LEFTARM_EN = 'left';
RIGHTARM_EN = 'right';

if P.pain.CPM.tonicStim.cuff == P.pain.preExposure.cuff_left && P.pain.CPM.phasicStim.cuff == P.pain.preExposure.cuff_right % tonic left / phasic right

    ARMNAME_LONG_DE = LEFTARM_DE;
    ARMNAME_SHORT_DE = RIGHTARM_DE;
    
    ARMNAME_LONG_EN = LEFTARM_EN;
    ARMNAME_SHORT_EN = RIGHTARM_EN;
    
elseif P.pain.CPM.tonicStim.cuff == P.pain.preExposure.cuff_right && P.pain.CPM.phasicStim.cuff == P.pain.preExposure.cuff_left % tonic right / phasic left

    ARMNAME_LONG_DE = RIGHTARM_DE;
    ARMNAME_SHORT_DE = LEFTARM_DE;
    
    ARMNAME_LONG_EN = RIGHTARM_EN;
    ARMNAME_SHORT_EN = LEFTARM_EN;

end

CPM_BLOCK_NO = num2str(P.presentation.CPM.blocks);

if ~O.debug.toggleVisual
    
    if section == 1
        
        fprintf('Ready PREEXPOSURE protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie werden nun eine Reihe von Druckreizen erhalten,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'die Sie als schmerzhaft oder nicht schmerzhaft empfinden könnten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die Reize werden Sie jeweils an einem Arm erhalten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Mit welchem Arm begonnen wird, wird zufällig entschieden. ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Die Reize am ' ARMNAME_LONG_DE ' Arm sind langanhaltend'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und die Reize am ' ARMNAME_SHORT_DE ' Arm sind kurz.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nach jedem Reiz werden Sie gebeten, eine Taste zu drücken,', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'um zu bewerten, ob der Reiz schmerzhaft oder nicht schmerzhaft war.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Haben Sie noch Fragen?', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Wenn nicht, beginnt nun die Messung!', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a number of pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The stimuli will be on one arm at a time but', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'the starting arm is different for each participant.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The stimuli on your ' ARMNAME_LONG_EN ' arm will be long'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['and the the stimuli on your ' ARMNAME_SHORT_EN ' arm will be short.'], 'center', upperEight+P.style.lineheight, P.style.white);
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
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie üben nun, die Druckreize anhand einer visuellen Skala auf dem Bildschirm', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'zu bewerten, wobei noch kein Druck auf Ihren Arm ausgeübt wird.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '0 bedeutet kein Schmerz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '1 bedeutet minimaler Schmerz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '100 bedeutet unerträglicher Schmerz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die linke Pfeiltaste verringert die Bewertung und', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'die rechte Pfeiltaste erhöht die Bewertung auf der Skala.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Im weiteren Verlauf des Experiments sollen Sie bitte jeden Reiz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'auf diese Weise in seiner Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now train in rating the pressure stimuli with', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'a visual scale on the screen but with no pressure applied to the arm.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '0 is no pain, 1 is minimal pain, 100 is intolerable pain.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Left arrow decreases the pain rating, right arrow increases rating.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Later during the experiment, you should rate each stimulus on their painfulness in this way.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 3
        
        fprintf('Ready PSYCHOMETRIC SCALING protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie erhalten nun weitere Druckreize, die in ihrer Intensität', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'von geringem Schmerz bis zu hohem Schmerz reichen.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Zuerst werden alle Reize auf einen Arm angewendet', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'und dann auf den anderen Arm.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Wie bereits bekannt, wird der ' ARMNAME_LONG_DE(1:end-1) ' Arm langanhaltende Reize'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und der ' ARMNAME_SHORT_DE(1:end-1) ' Arm kurze Reize erhalten.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Sie sollen die Reize, wie zuvor, auf einer Skala nach ihrer Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a few more stimuli, which range', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'in their intensity from low to high pain.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First, all stimuli will be applied on one arm, and then on the other.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Again, ' ARMNAME_LONG_EN ' arm will get long stimuli and ' ARMNAME_SHORT_EN ' arm short stimuli.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as instructed before.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 4
        
        fprintf('Ready VAS TARGET REGRESSSION protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie erhalten nun weitere verschiedene Druckreize, ', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'die für Sie schmerzhaft oder nicht schmerzhaft sein können.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Wie bereits bekannt, wird der  ' ARMNAME_LONG_DE(1:end-1) ' Arm langanhaltende Reize'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und der ' ARMNAME_SHORT_DE(1:end-1) ' Arm kurze Reize erhalten.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie sollen die Reize, wie zuvor, auf einer', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Skala nach ihrer Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive more different pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Again, ' ARMNAME_LONG_EN ' arm will get long stimuli and ' ARMNAME_SHORT_EN ' arm short stimuli.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as before.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 5
        
        fprintf('Ready CONDITIONED PAIN MODULATION protocol.\n');
        if strcmp(P.language,'de')
            upperEight = 0.5*upperEight;
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Das Experiment wird in wenigen Augenblicken starten...', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Es werden jeweils einige Minuten langanhaltende Druckreize auf', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['auf den ' ARMNAME_LONG_DE ' Arm ausgeübt und'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'gleichzeitig erhalten Sie mit dem langanhaltenden Reiz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['alle paar Sekunden kurze Druckreize auf den ' ARMNAME_SHORT_DE ' Arm.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die langanhaltenden Reize können zu verschiedenen', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Zeitpunkten schmerzhaft oder nicht schmerzhaft sein.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die kurzen Reize werden immer schmerzhaft sein.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nachdem ein kurzer Reiz beendet ist, sollen Sie jeden Reiz bitte', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'so schnell wie möglich in seiner Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Denken Sie bitte daran, dass Sie nur 5 Sekunden Zeit haben für die Bewertung!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Das Experiment ist in ' CPM_BLOCK_NO ' Teile unterteilt, mit einer kurzen Pause dazwischen.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'In jedem Teil gibt es einen langanhaltenden Reiz, ohne kurzen, darauffolgenden Reiz.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie sollen dann bitte die Schmerzhaftigkeit des letzten, langanhaltenden Reizes', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'kontinuierlich während seiner gesamten Dauer bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Es ist sehr wichtig, dass Sie bitte jeden einzelnen Reiz bewerten!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Bitte sagen Sie Bescheid, wenn Sie die Anweisungen durchgelesen haben.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'In a moment, the experiment will start.', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['There will be long pressure stimuli on the ' ARMNAME_LONG_EN ' arm for some minutes at a time,'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['and at the same time with the long stimulus, you will get short pressure stimuli on the ' ARMNAME_SHORT_EN ' arm every few seconds.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The long stimuli may be painful or not painful at different times. The short stimuli will always be painful.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each short stimulus ends, you should rate its painfulness as quickly as possible.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Remember that you have only 5 seconds to rate the stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The experiment is divided into ' CPM_BLOCK_NO ' parts with a short break in between.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'For each part, there will be one long stimulus without any short stimuli at the end.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will be then instructed to rate the painfulness of the', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'last long stimulus continuously throughout its entire duration.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'It is very important that you rate each and every stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Please confirm verbally when you have read these instructions.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 6 % continuous rating of a tonic stimulus within CPM experiment
        
        Screen('TextSize', P.display.w, P.style.fontsize);
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nun sollen Sie bitte die Schmerzhaftigkeit des', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['langanhaltenden Reizes am ' ARMNAME_LONG_DE ' Arm'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'auf der gleichen Skala wie zuvor bewerten, aber', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'kontinuierlich während der gesamten Dauer des Reizes.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Ändern Sie bitte die Bewertung in eine der beiden Richtungen,', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'wenn Sie das Gefühl haben, dass sich Ihr Schmerzempfinden', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'auch nur ein wenig verändert hat.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Wenn Sie keinen Schmerz empfinden, denken Sie bitte daran, die Bewertung auf Null zu setzen.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Now you should rate the pain intensity of the long stimulus on the ' ARMNAME_LONG_EN ' arm'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'on the same scale as before but continuously during the whole stimulus.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Change the rating in either direction whenever you feel that your sensation of pain has changed even a little.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'If you do not feel any pain, remember to set the rating to zero.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 7 % end of the test
        
        if strcmp(P.language,'de')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Das Experiment ist beendet. Vielen Dank für Ihre Zeit!', 'center', upperEight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'The experiment has ended. Thank you for your time!', 'center', upperEight, P.style.white);
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