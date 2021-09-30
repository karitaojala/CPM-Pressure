function PlotPressureVAS_CPM_IndividualRatings(sList,LF,outDir,COLORS,highlightPEs) % based on EquiNoxBehav

    % this stuff is relevant for export size
    markerSize = 20;
    lineWidth = 1;

    if ~highlightPEs
        mAlpha = 0.4;
    elseif highlightPEs==1
        mAlpha = 0;
    elseif highlightPEs==2
        mAlpha = NaN;
    end
    sbErrorbars = 0;

    if nargin==3
        highlightPEs = 0;
    end    

    allSbs = sList; % default

    for m = 1%:2 % groups/conditions

        R(m) = figure;
        set(R(m).Children,'FontSize',8); % set for all, increase others later                     
        set(R(m),'PaperUnits','centimeters');
        set(R(m),'PaperPosition',[0 0 9.525 9.525*0.8]); % AR 0.8 - standard widths 6.68 9.525

        allSbs = WF.SbId;
        
        for sb = 1:numel(allSbs)
            subLF = LF(LF.SbId==allSbs(sb),:);

            for ii = 1:2         
                
                xi = repmat(sb+(ii-1)*numel(allSbs),sum(subLF.Modality==m  & subLF.Intensity==ii),1);
                % show individual ratings in this mod/int combination                    
                scatter(xi,subLF.VAS(subLF.Modality==m & subLF.Intensity==ii),markerSize,'MarkerEdgeColor','none','MarkerFaceColor',squeeze(COLORS(m,ii,:))','MarkerFaceAlpha',0.4);
                hold on;
                
                if sbErrorbars
                    % error bars for mean ratings
                    xi = sb+(ii-1)*numel(allSbs);
                    errorbar(xi,mean(subLF.VAS(subLF.Modality==m & subLF.Intensity==ii)),std(subLF.VAS(subLF.Modality==m & subLF.Intensity==ii)),'LineWidth',2,'Color',[0 0 0])
                end
                
                % x for mean ratings
                if 1==2 % display mean as LINE
                    x = repmat(sb+(ii-1)*numel(allSbs),1,2)+[-1 1];
                    y = repmat(mean(subLF.VAS(subLF.Modality==m & subLF.Intensity==ii)),1,2);
                    line(x,y,'LineStyle','-','Color',[0 0 0],'LineWidth',3)
                else % display mean as SCATTER
                    xi = sb+(ii-1)*numel(allSbs);
                    scatter(xi,mean(subLF.VAS(subLF.Modality==m & subLF.Intensity==ii)),markerSize*2,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',squeeze(COLORS(m,ii,:))','MarkerFaceAlpha',1)
                end
            end

        end

        title('Single trial ratings');
        
        xticks([numel(allSbs)/2 numel(allSbs)+numel(allSbs)/2]);
        xticklabels({'Low','High'})
        xlabel('Stimulus intensity','FontSize',11,'FontWeight','bold');
        xlim([0 numel(allSbs)*2+1]);
        
        ylabel(sprintf('VAS rating\n(large circle=subject means)'),'FontSize',11,'FontWeight','bold');        
        ylim([0 100]);
        
        line(xlim,[25 25],'LineStyle','--','Color',[0.5 0.5 0.5],'LineWidth',2); % low calibrated temp
        line(xlim,[75 75],'LineStyle','--','Color',[0.5 0.5 0.5],'LineWidth',2); % high calibrated temp    

        line([min(xlim) numel(allSbs)],repmat(mean(LF.VAS(LF.Modality==m & LF.Intensity==1)),1,2),'LineStyle','-','Color',[0 0 0],'LineWidth',lineWidth); % low calibrated temp
        line([numel(allSbs) max(xlim)],repmat(mean(LF.VAS(LF.Modality==m & LF.Intensity==2)),1,2),'LineStyle','-','Color',[0 0 0],'LineWidth',lineWidth); % high calibrated temp    
                 
        if sbErrorbars
            eStr = '_wSE';
        else
            eStr = '';
        end
            
        fN = sprintf('%s%sallIndRatings%s_modality%d_alpha%s.png',outDir,filesep,eStr,m,regexprep(num2str(mAlpha),'\.','pt'));                    
        print(fN,'-dpng','-r300') ;          
        fprintf('Figure saved at %s.\n',fN);
        
    end    