function [abort]=LoopBreaker(P)
%% Use so the experiment can be aborted with proper key presses
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