clear all

trough = 40;
peak = 60;

jitter = 0:0.5:2; % jitter for onset of phasic stimuli in seconds
cycles       = 3;
stimPerCycle = 3;
ramp         = 10; 
stimInterval = 15;
fullCycleDuration = 60;

phasicOnsets = ramp + [5:stimInterval:(fullCycleDuration*cycles-ramp)];
phasicOnsets = reshape(phasicOnsets,[],cycles)';

for cond = 1:2

    for cycle = 1:cycles

    % Cycle timings jittered relative to above onsets
    randomJitter = jitter(randperm(length(jitter)));
    randomJitter_all(cond,cycle,:) = randomJitter(1:stimPerCycle)./10;
    rand_phasicOnsets = datasample(phasicOnsets(cycle,:), stimPerCycle, 'Replace', false) + randomJitter(1:stimPerCycle);
    clear randomJitter
    
    % Sort timings ascending
    rand_phasicOnsets = sort(rand_phasicOnsets);
    
    % Save onsets
    onsets(cond,cycle,:) = rand_phasicOnsets./10 + 1;
    
    end

end
  
x = 1:9;

exp_tonic = [0 trough trough+20/3 peak-20/3 peak peak-20/3 trough+20/3 trough trough+20/3 peak-20/3 peak peak-20/3 ...
    trough+20/3 trough trough+20/3 peak-20/3 peak peak-20/3 trough+20/3 trough 0];
con_tonic = [0 2 3 4 5 4 3 2 3 4 5 4 3 2 3 4 5 4 3 2 0];

onsets = round(onsets);

exp_randomJitter = squeeze(randomJitter_all(1,:,:));
exp_randomJitter = exp_randomJitter';
exp_randomJitter = exp_randomJitter(:);

exp_test_x = sort(reshape(onsets(1,:,:),1,cycles*stimPerCycle));
exp_test_y = exp_tonic(exp_test_x);%+exp_randomJitter';
exp_test_x = exp_test_x + exp_randomJitter';
%exp_test_y = ones(1,numel(exp_test_x))*(peak-10);

con_randomJitter = squeeze(randomJitter_all(1,:,:));
con_randomJitter = con_randomJitter';
con_randomJitter = con_randomJitter(:);

con_test_x = sort(reshape(onsets(2,:,:),1,cycles*stimPerCycle));
con_test_y = con_tonic(con_test_x);%+con_randomJitter';
con_test_x = con_test_x + con_randomJitter';
%con_test_y = ones(1,numel(con_test_x))*3;

%exp_tonic_ip = interp1(x,exp_tonic,xq);
%con_tonic_ip = interp1(x,con_tonic,xq);

colors = [252, 192, 24; ... % Conditioning CON color
    58, 119, 242; ... % Conditioning EXP color
    140, 177, 107; ... % Test stimulus color
    118, 113, 113]./255; % Line color

figure('Position',[50 50 600 250])
plot(exp_tonic,'LineWidth',1.5,'Color',colors(2,:))
hold on
plot(con_tonic,'LineWidth',1.5,'Color',colors(1,:))

scatter(exp_test_x,exp_test_y,60,'MarkerFaceColor',colors(3,:),'MarkerEdgeColor',colors(4,:),'LineWidth',1.5);
scatter(con_test_x,con_test_y,60,'MarkerFaceColor',colors(3,:),'MarkerEdgeColor',colors(4,:),'LineWidth',1.5);


xlim([1 21])
% xticks(1:2:21)
set(gca,'XTick',1:2:21,'FontSize',12)
xticklabels(0:20:200)
xlabel('Time (s)', 'FontSize',14)

ylim([0 100])
ylabel('Pressure (kPa)','FontSize',14)
set(gca,'YTick',[])

title('Within-trial stimulus shape','FontSize',14)
legend('Painful conditioning','Non-painful conditioning','Test stimuli','Location','southeast')
legend boxoff

box off