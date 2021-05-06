function P = GetRegressionResults(P)

if P.toggles.doPainOnly
    thresholdVAS = 0;
else
    thresholdVAS = 50;
end
% x = P.calibration.pressure;
% y = P.calibration.rating;
[predPressureLin,predPressureSig,predPressureRob,betaLin,betaSig,betaRob] = FitData(x,y,[thresholdVAS P.pain.Calibration.VASTargetsVisual],2);

painThresholdLin = predPressureLin(1);
painThresholdSig = predPressureSig(1);
predPressureLin(1) = []; % remove threshold pressure, retain only VASTargets
predPressureSig(1) = []; % remove threshold pressure, retain only VASTargets

if betaLin(2)<0
    warning('\n\n********************\nNEGATIVE SLOPE. This is physiologically highly implausible. Exclude participant.\n********************\n');
end

% construct regression results output file
P.calibration.fitData.interceptLinear = betaLin(1); % lin intercept
P.calibration.fitData.slopeLinear = betaLin(2); % lin slope
P.calibration.fitData.interceptSigmoid = betaSig(1); % sig intercept
P.calibration.fitData.slopeSigmoid = betaSig(2); % sig slope
P.calibration.fitData.painThresholdAwiszus = P.awiszus.painThresholdFinal; % as per Awiszus thresholding
P.calibration.fitData.painThresholdLinear = painThresholdLin; % as per linear regression for VAS 0 (pain threshold)
P.calibration.fitData.painThresholdSigmoid = painThresholdSig; % as per nonlinear regression for VAS 0 (pain threshold)
P.calibration.fitData.predPressureLinear = predPressureLin;
P.calibration.fitData.predPressureSigmoid = predPressureSig;

fprintf('\n\n==========REGRESSION RESULTS==========\n');
fprintf('>>> Linear intercept %1.1f, slope %1.1f. <<<\n',betaLin);
fprintf('>>> Sigmoid intercept %1.1f, slope %1.1f. <<<\n',betaSig);
fprintf('To achieve VAS0, use %1.1f% kPa (lin) or %1.1f kPa (sig).\n',painThresholdLin,painThresholdSig);
fprintf('This yields for\n');

for vas = 1:numel(P.pain.Calibration.VASTargetsVisual)
    fprintf('- VAS%d: %1.1f kPa (lin), %1.1f kPa (sig)\n',P.pain.Calibration.VASTargetsVisual(vas),predPressureLin(vas),predPressureSig(vas));
end

save(P.out.file.param, 'P');

end