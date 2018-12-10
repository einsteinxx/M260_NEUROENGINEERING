

%Order of operations
% Filter the data
% Smooth Data to remove some noise
%
%
file_dir = '/home/kgonzalez/UCLA/NEURO_206/WEEK9';
%% Input file
%M= csvread('EMG_example_2_fs_2k.csv'); %read in csv file
M = csvread(fullfile(file_dir,'EMG_example_2_fs_2k.csv'));
time= M(:,1); % first column is the time series
fs= (time(2)-time(1))^-1; % calculate the sample frequecy
channel_number= size(M,2)-1; % num of channels in the database
for i=1:channel_number
figure('Color',[1 1 1]);plot(time,M(:,i+1)); %plot each channel
str= sprintf('Channel %d',i);
xlabel('seconds');title(str);xlim([time(1) time(size(time,1))]); % label and title each plots
end
channel_select= 1; % select channel for testing. channel_select<= channel_number
test_input= M(:,channel_select+1); % test_input will go through all the individual sections

%%


%file_dir = '/home/kgonzalez/UCLA/NEURO_206/EMG_INFO/MECexample/MEC/data';
% file_dir = '/home/kgonzalez/UCLA/NEURO_206/WEEK9';
% %file = 's4t1data.daq';
% file = 'EMG_example_1_90s_fs_2k.csv';
% 
% data = csvread(fullfile(file_dir, file));
% %data=daqread(fullfile(file_dir, file));  used for s4tldata
% 
% vals = data; %data(1.01e5:1.07e5,1);
% figure, plot(vals,'r-'); grid on;
% 
% 
% m = mean(vals);

%%
vals = M(:,2);

%%
%Get important power levels --WORKS
[pxx,fx] = pwelch(vals,[],[],[],fs);
figure, plot(fx,pxx)

%% Show a power plot to determine usable frequency ranges
%----WORKS, EASIEST FILTER METHOD
close all
spectrogram(vals,[],[],[],fs,'yaxis')


%using the matlab app filter creator to make this
%GETFILTER Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.2 and the DSP System Toolbox 9.4.
% Generated on: 29-Nov-2018 22:15:05

Fpass = 20;    % Passband Frequency
Fstop = 500;   % Stopband Frequency
Apass = 1;     % Passband Ripple (dB)
Astop = 60;    % Stopband Attenuation (dB)
Fs    = 2000;  % Sampling Frequency

h = fdesign.lowpass('fp,fst,ap,ast', Fpass, Fstop, Apass, Astop, Fs);

Hd = design(h, 'equiripple', ...
    'MinOrder', 'any', ...
    'StopbandShape', 'flat');


%apply the filter
yfilt1 =filter(Hd,vals);
figure, plot(time,vals,'k.-');
hold on;
plot(time,yfilt1,'r.-');
grid on;


%get order of filter used
filtord('Hd');

grpdelay(Hd,2,fs)
%% RECTIFY
%y = detrend(vals); %remove any DC offset

vals = yfilt1; 
fprintf(1,'Using filtered yfilt\n');

rectified = abs(vals);

figure, plot(time, rectified);
xlabel('Time (s)');
ylabel('Current (A)');
title('Rectified BandPass Filtered Signal');
grid on;

%% PEAKS

[peaks_val,locs] = findpeaks(rectified);

min_amplitude = 0.3;
%filter out peaks below a minimum threshold
remove_index = [];
for ii = 1:length(peaks_val)
   if (peaks_val(ii) < min_amplitude)
      remove_index = [remove_index ii]; 
       
   end
end
peaks_val(remove_index) = [];
locs(remove_index) = [];



figure, plot(time, vals,'b.-');
hold on;
plot(time(locs), peaks_val,'kd');

%% Scan for slopes beside each central peak
dy = diff(yfilt1);
ddy = diff(dy);
dt = diff(time); %fixed sampling, so should not change


close all
for ii = 21:21 %length(peaks_val)
    
    %how many peaks within +-3ms
    ptime = time - time(locs(ii));%ptime index maps to time directly
    index = find(abs(ptime) < 10e-3);
    
    %are other peaks within this +- 3ms window
    pfound = intersect(index, locs);
    
    if (length(pfound) >= 3)
        fprintf(1,'pfound size is %d @ %d\n',length(pfound),ii);
       figure, plot(time(pfound(1):pfound(end)), ...
           yfilt1(pfound(1):pfound(end)),'o-');
       hold on;
       for jj = 1:length(pfound)
       plot(time(pfound(jj)), peaks_val(pfound(jj)), 'rd');
       end
       plot(time(locs(ii)), peaks_val(ii));
       title(sprintf('ii = %d',ii));
       grid on;
       
       plot(time(pfound(1)-1:pfound(end)-1), ...
           dy(pfound(1):pfound(end)),'gx-.')
       
    end
    
    
    


Y = fft(yfilt1(pfound(1):pfound(end)));

L = length(yfilt1(pfound(1):pfound(end)));
Fs = fs;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
%L = length(yfilt1);             % Length of signal
t = (0:L-1)*T;        % Time vector


figure
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
plot(f,P1) 
tname = sprintf('Single-Sided Amplitude Spectrum of Filtered Signal(t): %d', ...
    ii);
title(tname);
xlabel('f (Hz)')
ylabel('|P1(f)|')

end



[acor, lag] = xcorr(yfilt1(100:300), yfilt1(pfound(1):pfound(end)));
[~,I] = max(abs(acor));
lagDiff = lag(I);
timeDiff = lagDiff/Fs

figure
plot(lag,acor)
a3 = gca;
a3.XTick = sort([-3000:1000:3000 lagDiff]);

%% FFT of filtered signal
FY = fft(yfilt1);

Fs = fs;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
L = length(yfilt1);             % Length of signal
t = (0:L-1)*T;        % Time vector


figure
P2 = abs(FY/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of Filtered Signal(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

%%
close all;
width = 20;
for jj = 20:30 %length(locs)
   w = locs(jj)-width:locs(jj) + width;
   figure, plot(time(w),yfilt1(w));
   hold on;
   plot(time(locs(jj)), peaks_val(jj),'v'); 
   dt = diff(time);
   ddt = diff(dt);
   dy = diff(yfilt1(w));
   ddy = diff(dy);
   
   
   %align with main data
   hold on;
   plot(time(w(1:end-1)),dy,'go-');
   hold on;
   plot(time(w(1:end-2)), ddy,'r.-');
   grid on;
   title('Filtered, 1st Derivative, 2nd Derivative');
   legend('Filt','Peak','1st Deriv','2nd Deriv');
    
end


%% SAVE SPIKE DATA

spike_signal = zeros(length(peaks_val),width*2+1);
figure; hold on;
for ii = 4:10 %length(peaks_val)
    spike_signal(ii,:) = locs(ii)-width:locs(ii)+width;
    
    plot(yfilt1(spike_signal(ii,:)));
    
end


%% ALIGN SPIKES

statelevels(yfilt1)


risetime(yfilt1,time)


%%
for ii = 4:length(peaks_val)
   pulsewidth(yfilt1(spike_signal(ii,:)),time(spike_signal(ii,:)), ...
       'Polarity', 'Positive'); 
    
   dcycle = dutycycle(yfilt1(spike_signal(ii,:)), ...
       time(spike_signal(ii,:)),'Polarity','negative');
   if (~isempty(dcycle) && (length(dcycle)> 1))

       pp = pulseperiod(yfilt1(spike_signal(ii,:)), ...
           time(spike_signal(ii,:)));
       avgFreq = 1.0/mean(pp);
       totalJitter = std(pp);
       fprintf(1,'avgFreq = %f\t\ttotalJitter = %f\n', ...
           avgFreq,totalJitter);
   end

end
%% CLUSTER
%%

[coeff, score, latent, tsquared, explained]=pca(yfilt1);
%%

L = length(vals);
Y = fft(vals);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = fs*(0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')



Y = fft(rectified);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

figure
plot(f,P1) 
title('Rectified Single-Sided Amplitude Spectrum of S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')


%%
fs = 2000;

sEMG1 = vals; %data1(:,2); 
fft_sEMG1 = fft(sEMG1); 
fft_sEMG1 = fftshift(fft_sEMG1);
n = length(sEMG1);  
fs_axis1 = (-n/2:n/2-1)*fs/n; % zero-centered frequency range
abs_fft_sEMG1 = abs(fft_sEMG1);
figure; 
plot(fs_axis1, abs_fft_sEMG1 ); axis([fs_axis1(1) fs_axis1(end) 0 1000]); 
xlabel('Frequency/Hz','fontsize', 14); ylabel('X(jw) magnitude','fontsize', 14); 
title('Frequency Domain - Biceps 1','fontsize', 14);
set(gca,'FontSize',14);
%% 3
% can change to your desired cutoff frequency
highpass = 5;   
lowpass = 10;    

hval = 100;
% get the index of -10 to -5 and 5 to 10Hz. 
cutoff1 = ceil((hval-highpass)/(fs/length(sEMG1))); cutoff2 = ceil((hval-lowpass)/(fs/length(sEMG1)));
cutoff3 = ceil((highpass+hval)/(fs/length(sEMG1))); cutoff4 = ceil((lowpass+hval)/(fs/length(sEMG1)));

%sEMG1 = vals; %data1(:,2); 
H = zeros(length(sEMG1),1);
H(cutoff2:cutoff1) = 1; % take only the -10 to -5Hz
H(cutoff3:cutoff4) = 1; % take only the 5 to 10Hz

figure; plot(fs_axis1, H); 
set(gca,'YLim',[0 2]); 
xlabel('Freqeuncy/Hz','fontsize', 14); 
ylabel('Amplitude','fontsize', 14);
title('Bandpass filter','fontsize', 14);set(gca,'FontSize',14);

%%
rectified = abs(vals);
movRMS = dsp.MovingRMS('Method','sliding window');
y = movRMS(rectified);

[yupper, ylower] = envelope(abs(vals),100,'rms');
figure, plot(yupper,'r.');hold on;
plot(ylower,'k.');


%PRODUCES NICE RMS HERE
cutoff = 3; %Hz to smooth it out
[b,a] = butter(4,cutoff*2/fs,'low');
RMS = filtfilt(b,a,rectified);

plot(time,rectified,'r.');
hold on;
plot(time(:,1),RMS,'k.-');
grid on








%fout=fft(rectified);
%%
% Descriptive statistics
% Signal spike counts
% Peak amplitude (voltage - mV) detection
% Averaging
% Variability analysis
% Root Mean Square




%% BANDPASS

%MATLAB method to get normalized frequencies for butter()
% cut_f1 = 5;
% cut_f2 = 100;
% Wn = [cut_f1/(Fs/2) cut_f2/(Fs/2)];

n =5;
flow = 10; %f, Hz
fhigh = 500;
Wn = [flow/(fs/2) fhigh/(fs/2)];
% Wn = fc/(fs/2);
% [b,a] = butter(n,Wn,'low');
[b,a] = butter(n,Wn,'bandpass');
filtered_y = filtfilt(b,a,vals);

figure, plot(time,vals, 'b.-'); hold on;
plot(time,filtered_y,'r.-');

freqz(b,a);

vals = filtered_y; %make filtered data the default

%%
N = length(vals);
xdft = fft(vals);
xdft = xdft(1:N/2+1);
psdx = (1/(fs*N)) * abs(xdft).^2;
psdx(2:end-1) = 2*psdx(2:end-1);
freq = 0:fs/length(vals):fs/2;

figure, 
plot(freq,10*log10(psdx))
grid on
title('Periodogram Using FFT')
xlabel('Frequency (Hz)')
ylabel('Power/Frequency (dB/Hz)')



%%
%RECTIFY SIGNAL
rectified = abs(vals);
figure, plot(time, rectified,'r.-');
grid on;

%%
if (0)
vals = M(:,2);
%y = lowpass(vals);

    d = fdesign.lowpass('Fp,Fst,Ap,Ast',0.15,0.35,1,60);
    Hd = design(d,'equiripple');
    output = filter(Hd,vals);

    fvtool(Hd);
    plot(psd(spectrum.periodogram,output,'Fs',100))

    
    % Design a 70th order lowpass FIR filter with cutoff frequency of 100 Hz.

Fnorm = 100/(Fs/2);           % Normalized frequency
df = designfilt('lowpassfir','FilterOrder',70,'CutoffFrequency',Fnorm);
    
    
figure, plot(vals,'r.-'); %,'DisplayName','Original');
% legend('-DynamicLegend');
grid on; hold on;
plot(output,'k+'); %,'DisplayName','Smoothed');
hold off;
legend('Original Data', 'FILT  Data');
title('Original Data Vs LPF Data');

end
%% smoothing. 
% Remove some of the noise to see the underlying signals more clearly

n = 5; %filter width is 2n+1
filter_width = 2* n + 1;

clear smoothed_vals;
for ii = (n+1):(length(vals)-n)
    y_sum = 0;
    for jj = -n:n
        y_sum = y_sum + vals(jj+ii)/(filter_width);   
    end
    smoothed_vals(ii) = y_sum; 
end


figure, plot(vals,'r.-'); %,'DisplayName','Original');
% legend('-DynamicLegend');
grid on; hold on;
plot(smoothed_vals,'k+'); %,'DisplayName','Smoothed');
hold off;
legend('Original Data', 'Smoothed Data');
title('Original Data Vs Smoothed Data');
    


%% FFT the smoothed data to see what frequencies are in this data
fft_out = fft(smoothed_vals);
L = length(smoothed_vals);
P2 = abs(fft_out/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

Fs = fs; %?????

f = Fs*(0:(L/2))/L;
figure, plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')


%ORIGINAL SIGNAL
Y = fft(vals);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

figure, plot(f,P1) 
title('Single-Sided Amplitude Spectrum of S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')





% figure, semilogx(abs(flist));
% 
% [b,a] = butter(3,[10 400]/1500); % filter between 10 and 400 Hz
% data = filtfilt(b,a,data);
% data = resample(data,1000,3000);




%% RECTIFY SIGNAL

%%

[pks,locs] = findpeaks(smoothed_vals);

figure;
plot(1:length(smoothed_vals), smoothed_vals,'ro-'); hold on;

plot(locs,pks, 'k*');





%% find change of sign
counter = 0;
for ii = 2:length(vals)
    counter = counter + 1;
    slope(counter) = (vals(ii) - vals(ii-1))/(ii - (ii-1));
    if (slope(counter) < 0)
       rate(counter) = -1;
    else
        rate(counter) = 1;
    end
    
    
end
figure, plot(rate, 'r.'); 
axis([0 50 -1 1]);

%% Get inflection points
box_length = 100;
box = floor(length(vals)/box_length); %box is 100 points wide

%for every box, find the maximum points where it changes direction
for jj = 1:box
   %try every box
   
   segment = 1+(jj-1) * box_length:(jj*box_length);
   max_val(jj) = max(vals(segment));
   min_val(jj) = min(vals(segment));
%    for ii = 1+(jj-1) * box:(jj*box)
       %this gives us the values within that box area
%        fprintf(1,'jj= %d, ii = %d\n', jj,ii);
       
%find max value

% 
%    end
    
end

figure, plot(max_val, 'ro-'); hold on;
plot(min_val, 'k.-'); grid on;

for ii = 1:length(max_val)
    if (ii == 1)
        xpoint_max(ii) = floor(box_length/2);
    else
   xpoint_max(ii) = (ii + (ii-1)) * floor(box_length/2); 
    end
end

figure, plot(vals,'r-'); grid on;hold on;
plot(xpoint_max,max_val,'g*');
%%
box = floor(length(vals)/100);
for ii = 1:length(vals)
    %for each point, see if its neighbor is different
    
    
end




%% LOW PASS FILTER
% B = [1,1];
% A = 1;
% 
% 
% 
% y = filter(B,A,vals);
% figure, plot(vals,'bo-'); grid on; hold on;
% plot(y,'r.-');
% 
% a = fft(y); figure, semilogx(real(a))
% 
% for ii = 1:length(y)
%     y(ii) = abs(y(ii) - m);
%     
% end
% 
% figure, semilogx(y)



%%




%%
%y(t) = |x(t) - xm|




x = -100:1:100;
y = sin(x)/pow2(x) + cos(x);

figure, plot(x,y,'ro-'); grid on;

a = fft(y);

figure, plot(a,'k.-');
grid on;
