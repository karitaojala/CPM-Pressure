% Quick script to change a parameter/overrides in P/O in the middle of the experiment
% P/O has to be loaded in the workspace
% Here the changed parameter:

%P. = ;
O.debug.toggleVisual    = 0; % toggle visuals
O.display.screen    = 1;
O.debug.toggleVisual    = 1; % toggle no visuals
O.devices.arduino = [];
%P.devices.arduino = 1;

% Save data
save(P.out.file.param,'P','O');