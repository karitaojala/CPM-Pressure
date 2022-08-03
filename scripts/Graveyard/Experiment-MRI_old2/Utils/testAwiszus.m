
P = InstantiateParameters;

responses = [0 0 0 0 0 1 0 1];

for trial = 1:6
    
%     if trial == 1; P.awiszus.nextX = 20; end % first trial take the starting value
    % nextX updated based on ratings
    P = Awiszus('init',P);

    fprintf(['Pressure intensity: ' num2str(P.awiszus.nextX) ' kPa\n'])
    preexPainful = responses(trial);
    if ~preexPainful
        fprintf('Painful: NO\n')
    else
        fprintf('Painful: YES\n')
    end
    
    P = Awiszus('update',P,preexPainful);

    % derive normal cumulative distribution
    if preexPainful==0
        likeli = normcdf(P.awiszus.X,P.awiszus.nextX,P.awiszus.sp);  % tekelili
    elseif preexPainful==1
        likeli = normcdf(P.awiszus.X,P.awiszus.nextX,P.awiszus.sp)*-1+1; % invert
    else
        error('Response must be binary.');
    end
    P.awiszus.dist = P.awiszus.dist.*likeli;
        
    figure
    plot(P.awiszus.X,P.awiszus.dist);
    plot(P.awiszus.X,likeli);
    drawnow;
    
    k=0;
    postCDF=[];
    for ii = 1:size(P.awiszus.dist,2)
        k = k+P.awiszus.dist(ii)/100;
        postCDF = [postCDF,k];
    end
    P.awiszus.nextX = P.awiszus.X(find(postCDF>0.5*postCDF(end),1,'first'));
    
end