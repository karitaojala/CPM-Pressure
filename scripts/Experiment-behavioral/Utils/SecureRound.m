%% Make sure round works across MATLAB versions
function [y]=SecureRound(X, N)
try
    y=round(X,N);
catch EXC
    %disp('Round function  pre 2014 !');
    y=round(X*10^N)/10^N;
end
end