function roi_plot_parameters(options,analysis_version,model,roitype,rois,plot_con,compare_cond)
%Plot of averaged beta values extracted from each ROI, one value for each
%condition, including error bars (Figure 5 in the article)

roiresultpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'ROI');
plotpath = fullfile(roiresultpath,'Plots'); % Plot path

roiInd = 1;

for roi = rois % Loop over type of ROI
    
    roi_name = options.stats.secondlvl.roi.names{roi}; % ROI name
    
    contrast_names = options.stats.firstlvl.contrasts.names.tonic_concat;
    
    for con = 1:numel(plot_con)
        roifile_con = fullfile(roiresultpath,['MeanBetas_' contrast_names{plot_con(con)} '_' roi_name '.mat']); 
        contrast_files{con} = roifile_con;
    end
    
    for con = 1:numel(contrast_files)
        
        data = load(contrast_files{con});
        data = data.data;
        
        meanbeta(roiInd,con) = data.meanbeta; % Extract mean betas for the current ROI
        allbetas(roiInd,con,:) = data.betas;
        if compare_cond
            meanerror(roiInd,con) = data.meanerror_within;
        else
            meanerror(roiInd,con) = data.meanerror_between;
        end
        roinames{roiInd} = roi_name; % Extract ROI names for the current ROIs
        
    end
    
    roiInd = roiInd + 1;
    
end

roi_no = numel(rois); % Number of ROIs

% Figure dimensions for printing
figwidth = 17.6;
figheight = 17.6;

label_roi = numel(rois)-1; % Which ROI subplot has the labels

% Create figure
roifig = figure('DefaultAxesFontSize', 12, 'DefaultAxesFontName', 'Arial', 'DefaultTextFontName', 'Arial');
set(roifig, 'Units', 'Centimeters',...
    'PaperUnits', 'Centimeters', ...
    'PaperPositionMode','auto')
set(roifig,'Position', [0, 0, figwidth, figheight])

% Figure axes columns and rows
axcolumns = 3;
axrows = ceil(roi_no/axcolumns);
pos = axpos(axrows, axcolumns, 0.07, 0.01, 0.04, 0.08, 0.08); %rownum,colnum,leftmarg,rightmarg,upmarg,downmarg,inmarg

roi_ind = 1; % Counter for ROI index

% ROI plotting order
rois_to_plot = 1:roi_no;

for plottedroi = rois_to_plot
    
    % Retrieve beta coefficients and error bars for the ROI for each of
    % the 6 conditions
    roibetas = squeeze(allbetas(plottedroi,:,:))';
    roimeanbetas = meanbeta(plottedroi,:);
    roierrors = meanerror(plottedroi,:);

    % Set axes for the ROI subplot
    ax = axes('Position', pos(roi_ind,:));
    set(gca,'LineWidth',1) % Set overall line width to 1
    
    % Zero line on y-axis
    xmin = 0; % Markers between 0 and 1, leave a little bit of space outside to accommodate markers
    if compare_cond; xmax = 3; else; xmax = 2; end
    line([xmin xmax],[0 0],'Color',[128 128 128]./255,'HandleVisibility','off','LineWidth',1.5)
    hold on
    
    % Draw plot contents
    EXP_color = [220 50 32]./255; % Color for US+ markers (red)
    CON_color = [0 90 181]./255; % Color for US- markers (blue)
    EXP_vs_CON_color = [245 145 5]./255; % Color for US+ > US- comparison
    %nonsigcolor = [128 128 128]./255; % Color for non-significant test
    
    % T-tests
    % Tonic EXP vs. CON (1-sided)
    if compare_cond && sum(plot_con == [1 2]) == 2
        % Paired t-test Phasic EXP vs. CON (1-tailed)
        [~,p,~,stats] = ttest(roibetas(:,2),roibetas(:,1),'Tail','right'); % EXP > CON
    elseif compare_cond && sum(plot_con == [3 4] | plot_con == [5 6]) == 2
        % Paired t-test Phasic EXP vs. CON (2-tailed)
        [~,p,~,~] = ttest(roibetas(:,2),roibetas(:,1),'Tail','both'); % EXP =/ CON
    elseif ~compare_cond
        % One-sample t-test against zero (2-tailed)
        [~,p,~,stats] = ttest(mean(roibetas,2)); % EXP-CON avg =/ 0
    end

%     if c_pvalue2(roi,1) < 0.05 % If corrected p-value for axiom 2 test 1 is less than 0.05 (significant)
%         line(x_pos_2,y_pos1,'Color',EXP_color,'LineWidth',1.7); % Draw the comparison line
%         text(x_pos_2(1)+0.06,y_pos1(1)+0.3,'*','Color',EXP_color,'FontSize',14,'FontWeight','bold'); % Add a star/asterisk to denote significance
%     elseif roi_pvalue2(1) < 0.05 % If the uncorrected p-value is less than 0.05 (without multiple comparisons correction)
%         line(x_pos_2,y_pos1,'Color',EXP_color,'LineWidth',1.7);
%         text(x_pos_2(1)+0.06,y_pos1(1)+0.3,'\circ','Color',EXP_color,'FontSize',14,'FontWeight','bold'); % Add a circle to denote trend
    
    % Draw mean beta value markers and error bars for the different conditions
    if compare_cond
        bar(1:2,roimeanbetas,'FaceColor',CON_color)
        errorbar(1:2,roimeanbetas,roierrors,roierrors, ...
            'LineWidth',1.5, 'LineStyle','none', 'CapSize', 0);
    else
        bar(mean(roimeanbetas,2),'FaceColor',CON_color)
        errorbar(mean(roimeanbetas,2),mean(roierrors,2), ...
            'LineWidth',1.5, 'LineStyle','none', 'CapSize', 0);
    end

    % Set axis limits
    y_max = round(max(roimeanbetas)+max(roierrors)+0.1,1); % Suitable limit for the mean beta values across ROIs and conditions
    if min(roimeanbetas) < 0; y_min = -y_max; 
    else; y_min = -0.2; end
    xlim([xmin xmax])
    ylim([y_min y_max])
    
    % Define and set title for the figure: ROI name
    roititle = roinames{plottedroi};
    roititle = strrep(roititle,'_',' '); % Replace underscores with spaces
    title(roititle,'FontSize',12,'FontWeight','normal')
    
    % Figure axis properties
    if roi_ind == label_roi
        ylabel(ax,'BOLD estimate','FontSize',12);
        xlabel(ax,'Tonic Condition','FontSize',12);
    end
    
    if compare_cond
        set(gca,'XTick',[1 2]); 
        set(gca,'XTickLabel',{'CON' 'EXP','FontSize',12});
        p_x_pos = 1.25;
    else
        set(gca,'XTick',1);
        set(gca,'XTickLabel',{'CON-EXP average','FontSize',12})
        p_x_pos = 0.75;
    end
    set(gca, 'box', 'off') % Legend box off
    
    % Significance markers
    if strcmp(roitype,'Anatomical') % p-values only for a priori anatomical ROIs, not significant functional clusters (circular)
        text(p_x_pos,y_max-0.05,['p = ' num2str(p,2)],'FontSize',8,'FontWeight','bold');
    end
    
    roi_ind = roi_ind + 1;
    
end

%     % Set paper size
%     PAPER = get(roifig,'Position');
%     set(roifig,'PaperSize',[PAPER(3), PAPER(4)]);
%
%     % Save figure
%     if length(opts.roi_subj) == 21 % All subjects
%         savefig(fullfile(plotpath,['ROIplot_' roiname '_' num2str(roi_no) 'ROIs']))
%         saveas(gcf,fullfile(plotpath,['ROIplot_' roiname '_' num2str(roi_no) 'ROIs']),'png')
%         saveas(gcf,fullfile(plotpath,['ROIplot_' roiname '_' num2str(roi_no) 'ROIs']),'svg')
%     else % Only subjects with monotonical CS-US contingency learning
%         savefig(fullfile(plotpath,['ROIplot_' roiname '_' num2str(roi_no) 'ROIs_MonotSubs']))
%         saveas(gcf,fullfile(plotpath,['ROIplot_' roiname '_' num2str(roi_no) 'ROIs_MonotSubs']),'png')
%         saveas(gcf,fullfile(plotpath,['ROIplot_' roiname '_' num2str(roi_no) 'ROIs_MonotSubs']),'svg')
%     end

end