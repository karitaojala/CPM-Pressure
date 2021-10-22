function [abort]=ShowInstruction(P,O,section,displayDuration)

if ~O.debug.toggleVisual
    Screen('Preference', 'TextRenderer', 0);
    Screen('TextFont', P.display.w, 'Arial', 1);
end

if strcmp(P.env.hostname,'stimpc1')
    if strcmp(P.language,'de')
        keyNotPainful = '[linke Taste]';
        keyPainful = '[rechte Taste]';
    elseif strcmp(P.language,'en')
        keyNotPainful = '[left button]';
        keyPainful = '[right button]';
    end
else
    if strcmp(P.language,'de')
        keyNotPainful = 'LINKE PFEILTASTE';
        keyPainful =  'RECHTE PFEILTASTE';
    elseif strcmp(P.language,'en')
        keyNotPainful = ['the key [' upper(char(P.keys.keyList(P.keys.notPainful))) ']'];
        keyPainful =  ['the key [' upper(char(P.keys.keyList(P.keys.painful))) ']'];
    end
end

abort = 0;
upperEight = P.display.screenRes.height*P.display.Ytext;

CPM_BLOCK_NO = num2str(P.presentation.CPM.blocks);

if ~O.debug.toggleVisual
    
    if section == 1
        
        fprintf('Ready PREEXPOSURE protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie werden nun eine Reihe von Druckreizen erhalten,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'die Sie als schmerzhaft oder nicht schmerzhaft empfinden k�nnten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die Reize werden Sie jeweils an einem Arm oder Bein erhalten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Mit welchem Gliesma�en begonnen wird, wird zuf�llig entschieden. ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Die Reize am ' P.presentation.armname_long_de ' sind langanhaltend'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und die Reize am ' P.presentation.armname_short_de ' sind kurz.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die ersten zwei Reize sind von geringer Intensit�t, damit Sie sich an das Gef�hl gew�hnen k�nnen.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nach jedem weiteren Reiz werden Sie gebeten, eine Taste zu dr�cken,', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'um zu bewerten, ob der Reiz schmerzhaft oder nicht schmerzhaft war.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Haben Sie noch Fragen?', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Wenn nicht, beginnt nun die Messung!', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a number of pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The stimuli will be on an arm or leg at a time but', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'the starting limb is different for each participant.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The stimuli on your ' P.presentation.armname_long_en ' will be long'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['and the the stimuli on your ' P.presentation.armname_short_en ' will be short.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First two stimuli are low intensity to let you get used to the feeling.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each further stimulus, you will be asked to press a button', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'to indicate whether the stimulus was painful or not', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Do you have any remaining questions?', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'If not, the measurement will start!', 'center', upperEight+P.style.lineheight, P.style.white);
        end
    
    elseif section == 2
        
        fprintf('Ready VAS TRAINING protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie �ben nun, die Druckreize anhand einer visuellen Skala auf dem Bildschirm', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'zu bewerten, wobei noch kein Druck ausge�bt wird.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '0 bedeutet kein Schmerz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '100 bedeutet unertr�glicher Schmerz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['die ' keyNotPainful ' verringert die Bewertung und'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['die ' keyPainful ' erh�ht die Bewertung auf der Skala.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Im weiteren Verlauf des Experiments sollen Sie bitte jeden Reiz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'auf diese Weise in seiner Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now train in rating the pressure stimuli with', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'a visual scale on the screen but with no pressure.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '0 is no pain, 100 is intolerable pain.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The' keyNotPainful ' decreases the pain rating, ' keyPainful ' increases rating.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Later during the experiment, you should rate each stimulus on their painfulness in this way.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 3
        
        fprintf('Ready PSYCHOMETRIC SCALING protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie erhalten nun weitere Druckreize, die in ihrer Intensit�t', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'von geringem Schmerz bis zu hohem Schmerz reichen.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Zuerst werden alle Reize auf eine Gliedma�e angewendet', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'und dann auf die andere Gliedma�e.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Wie bereits bekannt, wird ' P.presentation.armname_long_de_s ' langanhaltende Reize'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und ' P.presentation.armname_short_de_s ' kurze Reize erhalten.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Sie sollen die Reize, wie zuvor, auf einer Skala nach ihrer Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive a few more stimuli, which range', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'in their intensity from low to high pain.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'First, all stimuli will be applied on one arm, and then on the other.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Again, the ' P.presentation.armname_long_en ' will get long stimuli and the ' P.presentation.armname_short_en ' short stimuli.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as instructed before.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 4
        
        fprintf('Ready VAS TARGET REGRESSSION protocol.\n');
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie erhalten nun weitere verschiedene Druckreize, ', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'die f�r Sie schmerzhaft oder nicht schmerzhaft sein k�nnen.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Wie bereits bekannt, wird ' P.presentation.armname_long_de_s ' langanhaltende Reize'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['und ' P.presentation.armname_short_de_s ' kurze Reize erhalten.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie sollen die Reize, wie zuvor, auf einer', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Skala nach ihrer Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will now receive more different pressure stimuli,', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'which may or may not be painful for you.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Again, the ' P.presentation.armname_long_en ' will get long stimuli and the ' P.presentation.armname_short_en ' short stimuli.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'You should rate these stimuli on their painfulness on a scale, as before.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 5 % continuous rating of tonic stimulus

        if strcmp(P.language,'de')
            upperEight = 0.5*upperEight;
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Das Experiment wird in wenigen Augenblicken starten...', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Es werden jeweils langanhaltende Druckreize auf ' P.presentation.armname_long_de_s '.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['W�hrend dieses Teils werden keine kurzen Druckreize auf ' P.presentation.armname_short_de_s ' ausge�bt.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie sollen dann bitte die Schmerzhaftigkeit des langanhaltenden Reizes', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'kontinuierlich w�hrend seiner gesamten Dauer bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, '�ndern Sie bitte die Bewertung in eine der beiden Richtungen', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'wenn Sie das Gef�hl haben, dass sich Ihr Schmerzempfinden.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Wenn Sie keine Ver�nderung der Schmerzhaftigkeit feststellen, ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ' behalten Sie die Bewertung bei. ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);         
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Das Experiment wird in wenigen Augenblicken starten...', 'center', upperEight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Es werden jeweils einige Minuten langanhaltende Druckreize', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['auf ' P.presentation.armname_long_de_s ' ausge�bt und'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'gleichzeitig erhalten Sie mit dem langanhaltenden Reiz', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['alle paar Sekunden kurze Druckreize auf ' P.presentation.armname_short_de_s '.'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die langanhaltenden Reize k�nnen zu verschiedenen', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Zeitpunkten schmerzhaft oder nicht schmerzhaft sein.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die kurzen Reize werden immer schmerzhaft sein.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nachdem ein kurzer Reiz beendet ist, sollen Sie jeden Reiz bitte', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'so schnell wie m�glich in seiner Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Denken Sie bitte daran, dass Sie nur 5 Sekunden Zeit haben f�r die Bewertung!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Das Experiment ist in ' CPM_BLOCK_NO ' Teile unterteilt, mit einer kurzen Pause dazwischen.'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'In jedem Teil gibt es einen langanhaltenden Reiz, ohne kurzen, darauffolgenden Reiz.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie sollen dann bitte die Schmerzhaftigkeit des letzten, langanhaltenden Reizes', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'kontinuierlich w�hrend seiner gesamten Dauer bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Es ist sehr wichtig, dass Sie bitte jeden einzelnen Reiz bewerten!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Bitte sagen Sie Bescheid, wenn Sie die Anweisungen durchgelesen haben.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'In a moment, the experiment will start.', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['First, you will feel a long pressure stimulus on the ' P.presentation.armname_long_en '.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['There will be no pressure stimuli on the ' P.presentation.armname_short_en ' during this part.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You should rate the painfulness of the pressure CONTINUOUSLY throughout the stimulus.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'When you feel any change in the painfulness, change your rating.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'If you feel no change in painfulness, keep the rating the same.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'In a moment, the experiment will start.', 'center', upperEight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['There will be long pressure stimuli on the ' P.presentation.armname_long_en ' for some minutes at a time,'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['and at the same time with the long stimulus, you will get short pressure stimuli on the ' P.presentation.armname_short_en ' every few seconds.'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The long stimuli may be painful or not painful at different times. The short stimuli will always be painful.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'After each short stimulus ends, you should rate its painfulness as quickly as possible.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Remember that you have only 5 seconds to rate the stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The experiment is divided into ' CPM_BLOCK_NO ' parts with a short break in between.'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'For each part, there will be one long stimulus without any short stimuli at the end.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You will be then instructed to rate the painfulness of the', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'last long stimulus continuously throughout its entire duration.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'It is very important that you rate each and every stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Please confirm verbally when you have read these instructions.', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 6 % CPM experiment
        fprintf('Ready CONDITIONED PAIN MODULATION protocol.\n');
        Screen('TextSize', P.display.w, P.style.fontsize);
        if strcmp(P.language,'de')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Der n�chste Teil des Experiments wird bald beginnen.', 'center', upperEight-100, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Das Experiment ist in ' CPM_BLOCK_NO ' Teile unterteilt, mit einer kurzen Pause dazwischen.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Es werden jeweils einige Minuten langanhaltende Druckreize', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['auf ' P.presentation.armname_long_de_s ' ausge�bt und'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'gleichzeitig erhalten Sie mit dem langanhaltenden Reiz', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['alle paar Sekunden kurze Druckreize auf ' P.presentation.armname_short_de_s '.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die langanhaltenden Reize k�nnen zu verschiedenen', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Zeitpunkten schmerzhaft oder nicht schmerzhaft sein.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Die kurzen Reize werden immer schmerzhaft sein.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nachdem ein kurzer Reiz beendet ist, sollen Sie jeden Reiz bitte', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'so schnell wie m�glich in seiner Schmerzhaftigkeit bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Sie brauchen den langen Stimulus zu diesem Zeitpunkt nicht zu bewerten.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Denken Sie bitte daran, dass Sie nur 5 Sekunden Zeit haben f�r die Bewertung!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Es ist sehr wichtig, dass Sie bitte jeden einzelnen kurzen Reiz bewerten!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Nun sollen Sie bitte die Schmerzhaftigkeit des', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['langanhaltenden Reizes am ' P.presentation.armname_long_de], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'auf der gleichen Skala wie zuvor bewerten, aber', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'kontinuierlich w�hrend der gesamten Dauer des Reizes.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Wichtig: �ndern Sie bitte die Bewertung in eine der beiden Richtungen,', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'wenn Sie das Gef�hl haben, dass sich Ihr Schmerzempfinden', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'auch nur ein wenig ver�ndert hat.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Wenn Sie keinen Schmerz empfinden, denken Sie bitte daran', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'die Bewertung auf Null zu setzen.', 'center', upperEight+P.style.lineheight, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The next part of the experiment will start soon.', 'center', upperEight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The experiment is divided into ' CPM_BLOCK_NO ' parts with a short break in between.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['There will be long pressure stimuli on the ' P.presentation.armname_long_en ' arm for some minutes at a time,'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['and at the same time, there are short pressure stimuli on the ' P.presentation.armname_short_en ' arm every few seconds.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The long stimuli may be painful or not painful at different times.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The short stimuli will always be painful.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You should rate the painfulness of each SHORT stimulus quickly after it ends.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You do not need to rate the long stimulus this time.', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Remember that you have only 5 seconds to rate the stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'It is very important that you rate each and every short stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The next part of the experiment will start soon.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['The experiment is divided into ' CPM_BLOCK_NO ' parts with a short break in between.'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['There will be long pressure stimuli on the ' P.presentation.armname_long_en ' arm for some minutes at a time,'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['and at the same time, there are short pressure stimuli on the ' P.presentation.armname_short_en ' arm every few seconds.'], 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The long stimuli may be painful or not painful at different times.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'The short stimuli will always be painful.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You should rate the painfulness of each SHORT stimulus quickly after it ends.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'You do not need to rate the long stimulus this time.', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Remember that you have only 5 seconds to rate the stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
%             [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'It is very important that you rate each and every short stimulus!', 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif section == 7 % end of the test
        
        if strcmp(P.language,'de')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Das Experiment ist beendet. Vielen Dank f�r Ihre Zeit!', 'center', upperEight, P.style.white);
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

if abort; return; end

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