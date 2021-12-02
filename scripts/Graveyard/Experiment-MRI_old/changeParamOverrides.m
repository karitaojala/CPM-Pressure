% Quick script to change a parameter/overrides in P/O in the middle of the experiment
% P/O has to be loaded in the workspace
% Here the changed parameter:

%P. = ;
%O.debug.toggleVisual    = 1; % toggle no visuals

% Save data
save(P.out.file.param,'P','O');