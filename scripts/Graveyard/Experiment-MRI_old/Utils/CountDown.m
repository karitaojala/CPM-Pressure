function [abort,countedDown]=CountDown(P, secs, countedDown, countString)
%% display string during countdown
if secs>countedDown
    fprintf('%s', countString);
    countedDown=ceil(secs);
    WaitSecs(1);
end

[abort] = LoopBreakerStim(P);
if abort; return; end

end