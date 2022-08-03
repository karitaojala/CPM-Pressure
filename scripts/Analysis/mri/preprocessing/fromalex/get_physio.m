function [desmtx, breaths, beats, names]= get_physio(dir_data,name, k,nscans,TR,mode)
%UNTITLED Summary of this function goes here
% name - string (04, 09 etc.) session = 1,2,3
% This will be called from the 1st levelanalysis  for each
% subject/session

if nargin < 6
    mode = 'mat';
end

samp_int          = 0.01; % 10 ms equals 100Hz
tol_s             = 5;    % taken times 10 = ms
order_c           = 3;    % according to Harvey 2008 --> 3C4R1X
order_r           = 4;
order_cr          = 1;

h_size            = 300; %for breathing histogram

desmtx            = [];

% read logfiles
if strcmp(mode,'ced')
    [puls, resp, scan] = readlog_ced(name,k,dir_data,samp_int);
elseif strcmp(mode,'trio')
    disp(['Not ready yet ...']);
elseif strcmp(mode,'mat')
    [puls, resp, scan] = readlog_mat(name,k,dir_data,samp_int,nscans,TR);
else
    disp(['Unknown modality : ' mode]);
end

% detrend  & smooth
puls = spm_conv(spm_detrend(puls),5);
resp = spm_conv(spm_detrend(resp),50);

% extract scanner pulses and check validity
if length(scan) == length(puls) %means we have a time series NOT events
    scan = spm_conv(scan,10);
    p    = peak_LMS(scan,100);
    d_p  = diff(p);
    med  = median(d_p);  % robust against outliers
    while any(d_p>med+tol_s | d_p<med-tol_s)
        disp('odd pulses')
        wh      = find(d_p>med+tol_s | d_p<med-tol_s,1);
        p(wh+1) = [];disp(['deleted pulse ' num2str(wh+1)]);
        d_p     = diff(p);med  = median(d_p);
    end
    scanner   =  p;
else
    scanner   = scan';
end

d_p  = diff(scanner);
med  = median(d_p);  % robust against outliers
fprintf('Found %1.0f pulses estimated TR of %1.2f s\n',size(scanner,2),med.*samp_int);

% now breathing
resp      = -(resp - spm_conv(resp,10./samp_int));%change sign and remove baseline drifts
%resp      = -resp;

p         = peak_LMS(resp,100);
d_p       = diff(p);
med       = median(d_p);  % robust against outliers
fprintf('Found %1.0f breaths estimated breathing interval of %1.2f s or %1.0f bpm\n',size(p,2),med.*samp_int,60./(med.*samp_int));
breaths = size(p,2);
%everything else is done kernel based
n_resp    = (resp-min(resp))*max(resp)./(max(resp)-min(resp));
ksize     = 2*round(0.5*(1/samp_int));
kern      = [-ones(1,ksize) 0 ones(1,ksize)];
% use deriv to find breathing in / breathing out
sig_all   = conv(resp, kern);
sig_all   = sign(sig_all(ksize+1:end-ksize)); %+1 / -1 for breathing in/out
% create histogramm
[h, rout] = hist(n_resp, h_size+1); %h_size + 1 to avoid index of zero
h         = spm_conv(h,h_size/50);
p_prog    = (cumsum(h)./sum(h))';

resp_p    = pi*p_prog(1+round(n_resp./max(n_resp)*h_size)).*sig_all;

% index of scanner pulses and fourier expansion
resp_s    = resp_p(scanner);
debug = 0;
if debug
    figure(3);
    subplot(1,4,4);
    plot(h);
    subplot(1,2,1);
    x = 1:size(resp_p,1);
    plot(x,normit(n_resp)*pi,'r-',x,resp_p,'b-',x,sig_all,'g-');
end
desmtx    = [desmtx fourier_expand(resp_s, order_r)];

% now pulse
p         = peak_LMS(puls,500);
d_p       = diff(p);
med       = median(d_p);  % robust against outliers
fprintf('Found %1.0f heartbeats estimated R-R interval of %1.2f s or %1.0f bpm\n',size(p,2),med.*samp_int,60./(med.*samp_int));
beats = size(p,2);
fdp       = d_p./med;     %

while any(fdp>1.5)
    wh      = find(fdp>1.5,1);
    p       = [p(1:wh) p(wh)+round(med)  p(wh+1:end)]; %insert data point
    d_p     = diff(p);
    med     = median(d_p);  % robust against outliers
    fdp     = d_p./med;     %
    
    wh      = find(fdp<0.5,1);
    p(wh+1) = [];
    d_p     = diff(p);
    med     = median(d_p);  % robust against outliers
    fdp     = d_p./med;     %
end

card_p = zeros(size(puls));
for ph=1:size(d_p,2)
    card_p(p(ph):p(ph+1)-1) = linspace(0,2*pi,d_p(ph))';
end

card_s           = card_p(scanner);

    desmtx = [desmtx fourier_expand(card_s, order_c)];
    % also the interactions
    desmtx = [desmtx fourier_expand(card_s+resp_s, order_cr)];
    desmtx = [desmtx fourier_expand(card_s-resp_s, order_cr)]; 


names  = get_desc(order_c, order_r, order_cr);

end

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


function [puls,resp,scan] = readlog_ced(name,k,dir_data,samp_int)
sess = num2str(k);
physio_file = [dir_data filesep [name '_' sess '.txt']];
[ ~, ~, ~, scan, puls, ecg, resp] = textread(physio_file,'%f %f %f %f %f %f %f','headerlines', 1, 'delimiter','\t');
end

function [puls,resp,scan] = readlog_mat(name,k,dir_data,samp_int,nscans,TR)

physio_file = [dir_data filesep name '_clean.mat'];
a           = load(physio_file);
scan = a.Ch_6.times;

ind = [0; find(diff(scan)>mean(diff(scan))); size(scan,1)];
%clear up scans
correct = find(diff(ind) == nscans);
ind     = ind(correct);
scan    = scan(ind(k)+1:ind(k)+nscans);

%now pulse
puls    = a.Ch_2.values;
dt      = a.Ch_2.interval;
pulsID  = a.Ch_2.title;
if ~strcmp(pulsID,'Puls')
    error('Expect channel 2 to be Puls');
end
index = [round(scan(1)./dt) round(scan(end)./dt)+TR*1000]; %10 more samples
puls  = puls(index(1):index(2),:);
%now resp
resp    = a.Ch_1.values;
dt      = a.Ch_1.interval;
respID  = a.Ch_1.title;
if ~strcmp(respID,'Resp')
    error('Expect channel 1 to be Resp');
end
index = [round(scan(1)./dt) round(scan(end)./dt)+TR*1000];
resp  = resp(index(1):index(2),:);
%finally adjust dt for scans (is in s, needs to be at 100Hz)
scan = 1 + round((scan - scan(1)) / samp_int);
puls = interp1(puls,1:samp_int./dt:size(puls,1))';
resp = interp1(resp,1:samp_int./dt:size(resp,1))';
end


function [puls,resp,scan] = readlog_trio(name, k, samp_int)
sess = num2str(k);
s_file = [dir_data filesep name filesep sess filesep [name '_' sess '.ext']];
p_file = [dir_data filesep name filesep sess filesep [name '_' sess '.puls']];
r_file = [dir_data filesep name filesep sess filesep [name '_' sess '.resp']];
sbuf   = textread(s_file,'%s','delimiter',' ');
sbuf(find(strcmp(sbuf,'5000')),:) = [];
ind    = 5:find(strcmp(sbuf,'5003'))-1; %4 dummy bytes '5003' shows end of data
sdat   = str2num(strvcat(sbuf(ind)));

sbuf   = textread(p_file,'%s','delimiter',' ');
sbuf(find(strcmp(sbuf,'5000')),:) = [];
ind    = 5:find(strcmp(sbuf,'5003'))-1; %4 dummy bytes '5003' shows end of data
pdat   = str2num(strvcat(sbuf(ind)));

sbuf   = textread(r_file,'%s','delimiter',' ');
sbuf(find(strcmp(sbuf,'5000')),:) = [];
ind    = 5:find(strcmp(sbuf,'5003'))-1; %4 dummy bytes '5003' shows end of data
rdat   = str2num(strvcat(sbuf(ind)));

end
