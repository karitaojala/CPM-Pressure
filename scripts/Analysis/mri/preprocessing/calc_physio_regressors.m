function [physioreg,output_fig] = calc_physio_regressors(physiodata,physregopts)

% Debug mode on = 1 / off = 0
debug = 1;

% Retrieve regressor options
samp_int    = physregopts.samp_int;
%tol_s       = physregopts.tol_s;
order_c     = physregopts.order_c;
order_r     = physregopts.order_r;
order_cr    = physregopts.order_cr;
h_size      = physregopts.h_size; 

% Regressor matrix initiation
regmtx      = [];

% Retrieve data
pulse       = physiodata.pulse;
resp        = physiodata.resp;

scans       = zeros(numel(pulse),1);
tTR         = physiodata.scansRunStart;
scans(tTR)  = 1;
scanner     = logical(scans);

% kernel widths for convolution of the signals
kernelResp  = 50;
kernelPulse = 5;

% peak detection algorithm options
LMSResp     = 100; % what does this variable do?
LMSPulse    = 500; % what does this variable do?

% detrend  & smooth both respiration and pulse signals with specific kernel
% width
resp    = spm_conv(spm_detrend(resp),kernelResp);
pulse   = spm_conv(spm_detrend(pulse),kernelPulse);

%% respiration
resp      = -(resp - spm_conv(resp,10./samp_int)); % change sign and remove baseline drifts

% find peaks
p         = peak_LMS(resp,LMSResp);
d_p       = diff(p);
med       = median(d_p);  % robust against outliers
breaths   = size(p,2);
fprintf('Found %1.0f breaths estimated breathing interval of %1.2f s or %1.0f bpm\n',breaths,med.*samp_int,60./(med.*samp_int));

% everything else is done kernel based
n_resp    = (resp-min(resp))*max(resp)./(max(resp)-min(resp));
ksize     = 2*round(0.5*(1/samp_int));
kern      = [-ones(1,ksize) 0 ones(1,ksize)];

% use deriv to find breathing in / breathing out
sig_all   = conv(resp, kern);
sig_all   = sign(sig_all(ksize+1:end-ksize)); % +1 / -1 for breathing in/out

% create histogramm
[h, rout] = hist(n_resp, h_size+1); % h_size + 1 to avoid index of zero
h         = spm_conv(h,h_size/50);
p_prog    = (cumsum(h)./sum(h))';

resp_p    = pi*p_prog(1+round(n_resp./max(n_resp)*h_size)).*sig_all;

% index of scanner pulses and fourier expansion
resp_s    = resp_p(scanner);

if debug
    fig = figure('Position',[100,100,1000,600]);
    % signal
    subplot(2,2,1);
    plot(resp);
    title('Respiratory signal')
    hold on
    % detected breaths
    subplot(2,2,3);
    x = 1:size(resp_p,1);
    plot(x,normfit(n_resp)*pi,'r-',x,resp_p,'b-',x,sig_all,'g-');
    title('Detected breaths with kernel width')
    % smoothed histogram of signal values
%     subplot(3,2,5);
%     plot(h);
%     title('Histogram of normalized respiratory signal')
end

% respiration regressors
regmtx    = [regmtx fourier_expand(resp_s,order_r)];

%% pulse
% find peaks
p         = peak_LMS(pulse,LMSPulse);
d_p       = diff(p);
med       = median(d_p);  % robust against outliers
beats     = size(p,2);
fprintf('Found %1.0f heartbeats estimated R-R interval of %1.2f s or %1.0f bpm\n',beats,med.*samp_int,60./(med.*samp_int));

fdp       = d_p./med; % standardized by median

while any(fdp > 1.5)
    wh      = find(fdp > 1.5,1);
    p       = [p(1:wh) p(wh)+round(med) p(wh+1:end)]; % insert data point
    d_p     = diff(p);
    med     = median(d_p);  % robust against outliers
    fdp     = d_p./med;     % standardized by median
    
    wh      = find(fdp < 0.5,1);
    p(wh+1) = [];
    d_p     = diff(p);
    med     = median(d_p);  % robust against outliers
    fdp     = d_p./med;     % standardized by median
end

card_p = zeros(size(pulse));

for ph = 1:size(d_p,2)
    card_p(p(ph):p(ph+1)-1) = linspace(0,2*pi,d_p(ph))';
    %card_p(p(ph):p(ph+1)) = linspace(0,2*pi,d_p(ph))';
end

card_s = card_p(scanner);

if debug
    %figure;
    % signal
    subplot(2,2,2);
    plot(pulse);
    title('Cardiac pulse signal')
    % detected diff in pulse signal = heartbeats
    subplot(2,2,4);
    %x = 1:size(card_p,1);
    plot(card_p);
    title('Detected heartbeats')
    % smoothed histogram of signal values
%     subplot(2,1,2);
%     plot(h);
    output_fig = fig;
end

% pulse regressors
regmtx = [regmtx fourier_expand(card_s, order_c)];
% also the interactions
regmtx = [regmtx fourier_expand(card_s+resp_s, order_cr)];
regmtx = [regmtx fourier_expand(card_s-resp_s, order_cr)];

% get regressor names
names  = get_desc(order_c, order_r, order_cr);

% output
physioreg = regmtx;%[desmtx, breaths, beats, names];

end

% Supplementary functions
function mat_f = fourier_expand(pha, order)

mat_f  =  zeros(size(pha,1),order);
for i = 1:order
    mat_f(:,2*i-1) = cos(i*pha);
    mat_f(:,2*i)   = sin(i*pha);
end

end

function out = get_desc(order_c, order_r, order_cr)

go = 1;
for i = 1:order_c
    out{go} = ['Card' num2str(i) 'Cos'];
    out{go+1} = ['Card' num2str(i) 'Sin'];
    go = go + 2;
end
for i = 1:order_r
    out{go} = ['Resp' num2str(i) 'Cos'];
    out{go+1} = ['Resp' num2str(i) 'Sin'];
    go = go + 2;
end
for i = 1:order_cr
    out{go} = ['Card+Resp' num2str(i) 'Cos'];
    out{go+1} = ['Card+Resp' num2str(i) 'Sin'];
    go = go + 2;
end
for i = 1:order_cr
    out{go} = ['Card-Resp' num2str(i) 'Cos'];
    out{go+1} = ['Card-Resp' num2str(i) 'Sin'];
    go = go + 2;
end

end