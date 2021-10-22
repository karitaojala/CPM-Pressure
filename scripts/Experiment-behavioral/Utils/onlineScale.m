function [abort,startTime,conRating,conTime,keyId,response] = onlineScale(P)

%% key settings
abort = 0;

KbName('UnifyKeyNames');
keys        = P.keys;
lessKey     =  keys.left; % yellow button
moreKey     =  keys.right; % red button
escapeKey   = keys.esc;

window      = P.display.w;
windowRect  = P.display.rect;
durRating   = P.presentation.CPM.tonicStim.durationVAS;

if isempty(window); error('Please provide window pointer for likertScale!'); end
if isempty(windowRect); error('Please provide window rect for likertScale!'); end
if isempty(durRating); error('Duration length of rating has to be specified!'); end

%% Default values
nRatingSteps = 101;
scaleWidth = 700; 
textSize = 20; 
lineWidth = 6;
scaleColor = [255 255 255]; 
activeColor = [255 0 0]; 
defaultRating = 1;
backgroundColor = P.style.backgr; 
startY = P.style.startY;

% if length(ratingLabels) ~= nRatingSteps
%     error('Rating steps and label numbers do not match')
% end

%% Calculate rects
activeAddon_width = 1.5;
activeAddon_height = 20;
[xCenter, yCenter] = RectCenter(windowRect);
yCenter = startY;
axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
lowLabelRect = [axesRect(1),yCenter-20,axesRect(1)+6,yCenter+20];
highLabelRect = [axesRect(3)-6,yCenter-20,axesRect(3),yCenter+20];
midLabelRect = [xCenter-3,yCenter-20,xCenter+3,yCenter+20];
midlLabelRect = [xCenter-3-scaleWidth/4,yCenter-20,xCenter+3-scaleWidth/4,yCenter+20];
midhLabelRect = [xCenter-3+ scaleWidth/4,yCenter-20,xCenter+3+scaleWidth/4,yCenter+20];
ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];

Screen('TextSize',window,textSize);
Screen('TextColor',window,[255 255 255]);
Screen('TextFont', window, 'Arial');
currentRating = defaultRating;
finalRating = currentRating;
response = 0;

numberOfSecondsRemaining = durRating;
conRating = 0;
conTime = 0;
keyId = 0;


%%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
% tic; % control if timing is as long as durRating

startTime = GetSecs;
while numberOfSecondsRemaining  > 0
   
    Screen('FillRect',window,backgroundColor); 
    Screen('FillRect',window,activeColor,[activeTicRects(1,1)+3 activeTicRects(2,1)+ 5 activeTicRects(3,currentRating)-3 activeTicRects(4,1)-5]);   
    Screen('FillRect',window,scaleColor,lowLabelRect);   
    Screen('FillRect',window,scaleColor,highLabelRect);    
    Screen('FillRect',window,scaleColor,midLabelRect); 
    Screen('FillRect',window,scaleColor,midlLabelRect);  
    Screen('FillRect',window,scaleColor,midhLabelRect);
  
%     DrawFormattedText(window, 'Bitte bewerten Sie die Schmerzhaftigkeit', 'center',yCenter-100, scaleColor);  
%     DrawFormattedText(window, 'des Hitzereizes', 'center',yCenter-70, scaleColor);   
    
    Screen('DrawText',window,'kein',axesRect(1)-17,yCenter+25,scaleColor);
    Screen('DrawText',window,'Schmerz',axesRect(1)-40,yCenter+45,scaleColor);
      
    Screen('DrawText',window,'unerträglicher',axesRect(3)-55,yCenter+25,scaleColor); 
    Screen('DrawText',window,'Schmerz',axesRect(3)-40,yCenter+45,scaleColor);
    
    Screen('Flip', window);
    Screen('TextSize',window,textSize);
        
    [keyIsDown,secs,keyCode] = KbCheck; % this checks the keyboard very, very briefly.
        
        if keyIsDown % only if a key was pressed we check which key it was
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.buttonPress); % log key/button press as a marker          
            if keyCode(moreKey) % if it was the key we named key1 at the top then...
                currentRating = currentRating + 1;
                if currentRating > nRatingSteps
                    currentRating = nRatingSteps;
                end  
                finalRating = currentRating - 1;
                conRating(end+1) = finalRating;
                conTime(end+1) = GetSecs - startTime;
                keyId(end+1) = 1;
                response = 1;
            elseif keyCode(lessKey)
                currentRating = currentRating - 1;                
                if currentRating < 1
                    currentRating = 1;
                end
                finalRating = currentRating - 1;
                conRating(end+1) = finalRating;
                conTime(end+1) = GetSecs - startTime;
                keyId(end+1) = -1;
                response = 1;
            elseif keyCode(escapeKey)
                abort = 1;
                break;
            end
        end
      
        conRating(end+1) = finalRating;         
        conTime(end+1) = GetSecs - startTime;
        keyId(end+1) = 0;
   
        numberOfSecondsElapsed   = (GetSecs - startTime);
        numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
    
end

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