function cparPlot(data)
% cparPlot Plot the results in a sampling structure
%   cparPlot(data) this creates a plot of the actual and target pressure
%   for pressure outlet 1 and 2, as well as a plot of the VAS scores.
%
% See also, cparInitializeSampling

figure(1);
clf;
set(gcf,'color', [1 1 1]);

subplot(3,1,1);
plot(data.t, data.Target01, 'k:',...
     data.t, data.Pressure01, 'b');
ylabel('Pressure [kPa]');
legend('Target', 'Actual');
title('Pressure Outlet 1');
set(gca,'TickDir','out');
set(gca,'box','off');

subplot(3,1,2);

plot(data.t, data.Target02, 'k:',...
     data.t, data.Pressure02, 'b');
ylabel('Pressure [kPa]');
legend('Target', 'Actual');
title('Pressure Outlet 2');
set(gca,'TickDir','out');
set(gca,'box','off');

subplot(3,1,3);

plot(data.t, data.VAS, 'k');
xlabel('Time [s]');
ylabel('VAS [cm]');
title('Visual Analog Score (VAS)');
set(gca,'TickDir','out');
set(gca,'box','off');
