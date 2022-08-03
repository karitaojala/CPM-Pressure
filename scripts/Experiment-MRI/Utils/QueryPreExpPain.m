function preexPainful = QueryPreExpPain(P,O)

if strcmp(P.env.hostname,'stimpc1')
    if strcmp(P.language,'de')
        keyNotPainful = 'die LINKE Taste';
        keyPainful = 'die RECHTE Taste';
    elseif strcmp(P.language,'en')
        keyNotPainful = 'the left button';
        keyPainful = 'the right button';
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

fprintf('Was this stimulus painful [%s], or not painful [%s]?\n',upper(char(P.keys.keyList(P.keys.painful))),upper(char(P.keys.keyList(P.keys.notPainful))));
if ~O.debug.toggleVisual
    upperEight = P.display.screenRes.height/8;
    if strcmp(P.language,'de')
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'War dieser Reiz SCHMERZHAFT für Sie?', 'center', upperEight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Falls ja, drücken Sie bitte ' keyPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
        [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Falls nein, drücken Sie bitte ' keyNotPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
    elseif strcmp(P.language,'en')
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Was this stimulus PAINFUL for you?', 'center', upperEight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
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

if ~O.debug.toggleVisual
    upperEight = P.display.screenRes.height/8;
    if strcmp(P.language,'de')
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'War dieser Reiz SCHMERZHAFT für Sie?', 'center', upperEight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
        if preexPainful
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Falls ja, drücken Sie bitte *' keyPainful '*.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Falls nein, drücken Sie bitte ' keyNotPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
        else
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['Falls ja, drücken Sie bitte ' keyPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Falls nein, drücken Sie bitte *' keyNotPainful '*.'], 'center', upperEight+P.style.lineheight, P.style.white);
        end
        
    elseif strcmp(P.language,'en')
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, 'Was this stimulus PAINFUL for you?', 'center', upperEight, P.style.white);
        [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ' ', 'center', upperEight+P.style.lineheight, P.style.white);
        if preexPainful
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['If yes, please press *' keyPainful '*.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['If no, please press ' keyNotPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
        else
            [P.display.screenRes.width, upperEight]=DrawFormattedText(P.display.w, ['If yes, please press ' keyPainful '.'], 'center', upperEight+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['If no, please press *' keyNotPainful '*.'], 'center', upperEight+P.style.lineheight, P.style.white);
        end
    end
    Screen('Flip',P.display.w);
    WaitSecs(1);
    Screen('Flip',P.display.w);
end

end