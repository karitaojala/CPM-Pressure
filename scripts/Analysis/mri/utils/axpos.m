function pos = axpos (rownum, colnum, leftmarg, rightmarg, upmarg, downmarg, inmarg)
% FORMAT 
% pos = axpos (rownum, colnum, leftmarg, rightmarg, upmarg,downmarg, inmarg)
% gets an axes number x 4 (x, y, width, height) matrix to be used in axes commands
% Dominik R Bach 2.5.2008-17.9.2008

height=(1-(upmarg+downmarg+(rownum-1)*inmarg))/rownum;
width=(1-(leftmarg+rightmarg+(colnum-1)*inmarg))/colnum;
ax=1;
for row=1:rownum
    for col=1:colnum
        pos(ax,1)=leftmarg+(col-1)*(width+inmarg);
        pos(ax,2)=downmarg+(rownum-row)*(height+inmarg);
        pos(ax,3)=width;
        pos(ax,4)=height;
        ax=ax+1;
    end;
end;
clear ax width height;