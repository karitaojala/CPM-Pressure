function [P,abort] = TonicStimRating(P,O,trialPressure,noRating)

% Start trial
fprintf('\n=======TONIC STIMULUS RATING=======\n');

% Apply tonic stimulus
[abort,P]=ApplyTonicStimulus(P,O,trialPressure,noRating); % run stimulus
save(P.out.file.param,'P','O'); % Save instantiated parameters and overrides after each trial (includes timing information)
        
if abort; return; end

end