%get templates and try them out




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
vals = M(:,2);

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

%%
fig_dir = '/home/kgonzalez/FALL2018/BIOENG_M260/PROJECT/FIG_DIR';

%% Scan for slopes beside each central peak
dy = diff(yfilt1);
ddy = diff(dy);
dt = diff(time); %fixed sampling, so should not change


close all;
template_count = 0; %store template type
stored_data = {length(peaks_val),25,1};
for ii = 1:length(peaks_val)
    
    %how many peaks within +-3ms
    ptime = time - time(locs(ii));%ptime index maps to time directly
    index = find(abs(ptime) < 10e-3);
    
    %are other peaks within this +- 3ms window
    [pfound,ia,ib] = intersect(index, locs);
    
    %pfound = intersect(ptime(index), abs(ptime(locs)));
    
    
    if (length(pfound) >= 3)
        
        if(0)
            fprintf(1,'pfound size is %d @ %d\n',length(pfound),ii);
            h = figure;
            plot(time(pfound(1):pfound(end)), ...
                yfilt1(pfound(1):pfound(end)),'o-');
            hold on;
            for jj = 1:length(pfound)
                plot(time(pfound(jj)), peaks_val(ib(jj)), 'rd');
            end
            plot(time(locs(ii)), peaks_val(ii));
            title(sprintf('ii = %d',ii));
            grid on;
            
            plot(time(pfound(1)-1:pfound(end)-1), ...
                dy(pfound(1):pfound(end)),'gx-.')
            
            pname = sprintf('Peak_list_%0d.jpg',ii);
            pname = fullfile(fig_dir, pname);
            %saveas(gcf,pname);
            %pause(0.01);
            delete(h);
            %close(gcf);
            
        end
        
        template_count = template_count + 1;
        
        template = yfilt1(pfound(1):pfound(end));
        template_list{template_count} = pfound;

        
        %data_out=try_templates(yfilt1, template,pfound,ii, fig_dir);
        %stored_data{template_count} = data_out;
        
    end
    
    
end




%%
if(0)
    figure, plot(time, yfilt1);
    hold on;
    for ii = 1:1%length(stored_data)
        for jj = 1:length(stored_data{ii})
            plot(time(stored_data{ii}{jj,1}), ...
                yfilt1(stored_data{ii}{jj,1}), 'r.-')
        end
    end
end
% 
% 
% plot(template_tries{1,1}, template_tries{1,2})
% template = yfilt1(pfound(1):pfound(end));
% figure, plot(template);


%