function roi_plot_parameters(options,analysis_version,model,roitype,rois,seeds,plot_con,compare_cond,comparison_name,plottype)
%Plot of averaged beta values extracted from each ROI, one value for each
%condition, including error bars (Figure 5 in the article)

roiresultpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],model.name,'ROI');
plotpath = fullfile(roiresultpath,'Plots'); % Plot path
if ~exist(plotpath,'dir');mkdir(plotpath);end

for seed = seeds
    
    clear contrast_files meanbeta allbetas meanerror
    
    if any(seeds) && options.spinal
        seed_name = ['_' options.stats.firstlvl.ppi.spinal.roi_names{seed}];
    elseif any(seeds) && ~options.spinal
        seed_name = ['_' options.stats.firstlvl.ppi.brain.roi_names{seed}];
    else
        seed_name = [];
    end
    
    tvalues = [];
    pvalues = [];
    dvalues = [];
    roiInd = 1;
    
    for roi = rois % Loop over type of ROI
        
        roi_name = options.stats.secondlvl.roi.names{roi}; % ROI name
        roi_plotname = options.stats.secondlvl.roi.plot_names{roi};
        
        contrast_names = model.congroups_2ndlvl.names_cons;
        
        for con = 1:numel(plot_con)
            roifile_con = fullfile(roiresultpath,['MeanBetas_' contrast_names{plot_con(con)} seed_name '_' roi_name '.mat']);
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
            roiplotnames{roiInd} = roi_plotname;
            
        end
        
        roiInd = roiInd + 1;
        
    end
    
    roi_no = numel(rois); % Number of ROIs
    
    % Figure dimensions for printing
    figwidth = 10;
    figheight = 5.5;
    leftmarg    = 0.12;
    rightmarg   = 0.05;
    upmarg      = 0.22;
    downmarg    = 0.05;
    inmarg      = 0.15;
    
    label_roi = 1;%numel(rois)-1; % Which ROI subplot has the labels
    
    % Create figure
    roifig = figure('DefaultAxesFontSize', 12, 'DefaultAxesFontName', 'Arial', 'DefaultTextFontName', 'Arial');
    set(roifig, 'Units', 'Centimeters',...
        'PaperUnits', 'Centimeters', ...
        'PaperPositionMode','auto')
    set(roifig,'Position', [0, 0, figwidth, figheight])
    
    % Figure axes columns and rows
    axcolumns = 2;%3;
    axrows = ceil(roi_no/axcolumns);
    pos = axpos(axrows, axcolumns, leftmarg, rightmarg, upmarg, downmarg, inmarg); 
    
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
        
        % Draw plot contents
        %EXP_color = [220 50 32]./255; % Color for US+ markers (red)
        %CON_color = [0 90 181]./255; % Color for US- markers (blue)
        %EXP_vs_CON_color = [245 145 5]./255; % Color for US+ > US- comparison
        colors = [252, 192, 24; 58, 119, 242]./255;
        bar_color = [85 125 190]./255;
        %nonsigcolor = [128 128 128]./255; % Color for non-significant test
        
        % T-tests
        if compare_cond && sum(plot_con == [1 2]) == 2
            % Paired t-test EXP vs. CON (1-tailed)
            [~,p,~,stats] = ttest(roibetas(:,2),roibetas(:,1),'Tail','right'); % EXP > CON
            d = computeCohen_d(roibetas(:,2),roibetas(:,1),'paired');
        elseif compare_cond && sum(plot_con == [13 14] | plot_con == [17 18]) == 2
            % Paired t-test EXP vs. CON (2-tailed)
            [~,p,~,stats] = ttest(roibetas(:,2),roibetas(:,1),'Tail','both'); % EXP =/ CON
            d = computeCohen_d(roibetas(:,2),roibetas(:,1),'paired');
        elseif ~compare_cond
            % One-sample t-test against zero (2-tailed)
            if size(roibetas,2) == 2
                [~,p,~,stats] = ttest(mean(roibetas,2)); % EXP-CON avg =/ 0
                d = computeCohen_d(mean(roibetas,2),zeros(size(mean(roibetas,2))),'independent');
            else
                [~,p,~,stats] = ttest(roibetas); 
                d = computeCohen_d(roibetas,zeros(size(roibetas)),'independent');
            end
        end
        
        tvalues = [tvalues; stats.tstat];
        pvalues = [pvalues; p];
        dvalues = [dvalues; d];
        %     if c_pvalue2(roi,1) < 0.05 % If corrected p-value for axiom 2 test 1 is less than 0.05 (significant)
        %         line(x_pos_2,y_pos1,'Color',EXP_color,'LineWidth',1.7); % Draw the comparison line
        %         text(x_pos_2(1)+0.06,y_pos1(1)+0.3,'*','Color',EXP_color,'FontSize',14,'FontWeight','bold'); % Add a star/asterisk to denote significance
        %     elseif roi_pvalue2(1) < 0.05 % If the uncorrected p-value is less than 0.05 (without multiple comparisons correction)
        %         line(x_pos_2,y_pos1,'Color',EXP_color,'LineWidth',1.7);
        %         text(x_pos_2(1)+0.06,y_pos1(1)+0.3,'\circ','Color',EXP_color,'FontSize',14,'FontWeight','bold'); % Add a circle to denote trend
        
        % Draw mean beta value markers and error bars for the different conditions
        if compare_cond
            
            if plottype == 1 % bar graph
                x_min = 0; % Markers between 0 and 1, leave a little bit of space outside to accommodate markers
                x_max = 3; 
                line([x_min x_max],[0 0],'Color',[128 128 128]./255,'HandleVisibility','off','LineWidth',1.5)
                hold on
                bar(1:2,roimeanbetas,'FaceColor',bar_color,'LineWidth',2)
                errorbar(1:2,roimeanbetas,roierrors,roierrors, ...
                    'LineWidth',2, 'LineStyle','none', 'CapSize', 0, 'Color', 'black');
                xlim([x_min x_max])
            elseif plottype == 2 % raincloud
                plot_top_to_bottom = 0;
                h = rm_raincloud({roibetas(:,1) roibetas(:,2)}, colors, plot_top_to_bottom);
                hold on
                if plot_top_to_bottom
%                     x_min = -0.5;
%                     x_max = 0.5;
                    y_min = -5;
                    y_max = 5;
                else
                    x_min = -2;
                    x_max = 4;
                    y_min = -1;
                    y_max = 1.5;
                end
            end
            
        else
            x_min = 0; % Markers between 0 and 1, leave a little bit of space outside to accommodate markers
            x_max = 2;
            bar(mean(roimeanbetas,2),'FaceColor',bar_color,'LineWidth',2)
            errorbar(mean(roimeanbetas,2),mean(roierrors,2), ...
                'LineWidth',2, 'LineStyle','none', 'CapSize', 0, 'Color', 'black');
        end
        
        % Set axis limits
        % Suitable limit for the mean beta values across ROIs and conditions
        if plottype == 1 && mean(roimeanbetas) < 0
            y_min = round(min(roimeanbetas)-max(roierrors)-0.1,1);
            y_max = 0.2;
        elseif plottype == 1 && mean(roimeanbetas) >= 0
            y_min = -0.15;
            y_max = 0.15;
            %y_max = round(max(roimeanbetas)+max(roierrors)+0.1,1); 
            %y_min = -0.2; 
        end
        
        if plottype > 0
            ylim([y_min y_max])
            xlim([x_min x_max])
        end
        
        % Define and set title for the figure: ROI name
        roititle = roiplotnames{plottedroi};
        %roititle = strrep(roititle,'_',' '); % Replace underscores with spaces
        title(roititle,'FontSize',14,'FontWeight','normal')
        
        % Figure axis properties
        if plottype == 1 || plot_top_to_bottom
            if roi_ind == label_roi
                ylabel(ax,'BOLD signal (a.u.)','FontSize',12);
            end
            xlabel(ax,'Conditionioning stimulus','FontSize',12);
        elseif plottype == 2 && ~plot_top_to_bottom
            %ylabel(ax,'Conditionioning stimulus','FontSize',12);
            set(gca,'YTick',[])
            xlabel(ax,'BOLD signal (a.u.)','FontSize',12);
        end
        
        if plottype == 1 && compare_cond
            set(gca,'XTick',[1 2]);
            set(gca,'XTickLabel',{'Non-painful' 'Painful','FontSize',12});
            p_x_pos = 1;
        elseif plottype == 1 && ~compare_cond
            set(gca,'XTick',1);
            set(gca,'XTickLabel',{'Painful/non-painful mean','FontSize',12})
            p_x_pos = 0.5;
        elseif plottype == 2 && plot_top_to_bottom
            p_y_pos = 3;
        elseif plottype == 2 && ~plot_top_to_bottom
            p_x_pos = 0;
            set(gca,'XTick',x_min:2:x_max);
            %ylabel('Conditioning','FontSize',12)
        end
        set(gca, 'box', 'off') % Legend box off
        
        % Significance markers
        if strcmp(roitype,'Anatomical') % p-values only for a priori anatomical ROIs, not significant functional clusters (circular)
            if plottype == 1
                text(p_x_pos,y_max-0.03,['{\it p} = ' num2str(p,2)],'FontSize',10,'FontWeight','bold');
            elseif plottype == 2 && ~plot_top_to_bottom
                text(p_x_pos+3.5,y_max-0.3,['{\it p} = ' num2str(p,2)],'FontSize',10,'FontWeight','bold');
            end
        end
        
        if plottype == 2 && roi_ind == label_roi
            legend([h.s{2} h.s{1}],'Painful', 'Non-painful','Location','southwest')
            legend('boxoff')
        end
        
        roi_ind = roi_ind + 1;
        
    end
    
    if ~isempty(seed_name)
        seed_name = strrep(seed_name,'_',' ');
        suptitle(seed_name(2:end))
    end
    
    % Set paper size
    PAPER = get(roifig,'Position');
    set(roifig,'PaperSize',[PAPER(3), PAPER(4)]);
    
    % Save figure
    if isempty(seed_name)
        plotname = ['ROIplot_' comparison_name seed_name];
    else
        plotname = ['ROIplot_' comparison_name '_' seed_name];
    end
    savefig(fullfile(plotpath,plotname))
    saveas(gcf,fullfile(plotpath,plotname),'png')
    saveas(gcf,fullfile(plotpath,plotname),'svg')
    
    % Save stats
%     roistats.p = pvalues;
%     roistats.t = tvalues;
%     roistats.d = dvalues;
%     roistats.names = options.stats.secondlvl.roi.names(rois)';
%     if isempty(seed_name)
%         statsfile = fullfile(roiresultpath,['Stats_' comparison_name seed_name '.mat']);
%     else
%         statsfile = fullfile(roiresultpath,['Stats_' comparison_name '_' seed_name '.mat']);
%     end
%     save(statsfile,'roistats')
    
end

end