function [template_tries] = try_templates(yfilt1, ...
        template, ...
        pfound, ...
        try_num, ...
        fig_dir)
    
    %%
    %to import emg time series into emglab via global
    %%>> global EMGSIGNAL
    %%>> EMGSIGNAL = my_data;
    
    %%
    
    
    
    %prepare template Y and signal X
    % Y = exp(-((1:40)-20).^2/20.).*cos(((1:40)-20)*2*pi/10);
    % Y2 = exp(-((1:100)-50).^2/100.);
    % X = [zeros(1,40) 2*Y zeros(1,10) 3*Y2 zeros(1,10)];
    
    
    %use previous script data

    % figure, plot(template);
    % tname = sprintf('Template #%d\n',try_num);
    % title(tname);
    % grid on;
    % xlabel('position #');
    % ylabel('Current (uA)');
    
    
    
    
    
    
    %%
    %close all;
    tcounter =0;
    template_tries={};
    
    last_match = 0;
    total_skip = 0;
    for jj = 1:length(pfound) %200
        fprintf(1,'Trying peak = %d/%d @%d\n',jj,length(pfound), try_num);
        clear lags c m im lngX lngY X
        Y = template; %short sequence of yfilt1
        
        %for our template, 0, 200, 15899, should be first
        X = yfilt1(total_skip+70:end); %the full signal

        
        % calculation normalized cross-correlation
        lngX = length(X);
        lngY = length(Y);
        assert(lngX >= lngY);
        lags = 0:(lngX-lngY);
        for i = lags
            c(i+1) = xcorr(X(i+1:i+lngY) - mean(X(i+1:i+lngY)), ...
                Y -mean(Y),0,'coeff');
        end
        [m,im]=max(c);
        
        if (m < 0.956)
            last_match = 100;
            continue; %try another section
        else
            fprintf(1,'max=%f, lag=%d, last_match = %d\n', ...
                c(im),lags(im), last_match);
            tcounter=tcounter+1;
        end
        
        
        %plotting
        h1 = figure;
        subplot(2,1,2);
        plot(lags(im)+1:(lngY+lags(im)),Y,'r','linewidth',2);
        hold on;
        plot(1:lngX,X,'b');
        legend('template','signal'); grid on;
        subplot(2,1,1);
        if(length(lags) < length(c))
            lags(length(lags)+1:length(c)) =0;
        end
        plot(lags,c,'-');
        hold on;
        plot(lags(im),c(im),'*r');
        text(lags(im)+4,c(im)-0.05,'max correlation', 'color','red');
        xlabel('lags');
        title(sprintf('normalized cross-correlation @%d=%4.2f, im = %d,TRY=%d', ...
            jj, c(im), im,try_num));
        grid on;
        
        subplot(2,1,2);
        ax_vals = axis;
        axis([ (im -50) (im + 50) ax_vals(3) ax_vals(4)]);
        
        pname = sprintf('Peak_list_TEMPLATE%0d_CORR_%0d.png', ...
            try_num,jj);
        pname = fullfile(fig_dir, pname);
        saveas(gcf,pname);
        delete(h1);
        
        
        
        last_match = im;
        total_skip = total_skip + last_match;
        
        
        template_tries{tcounter,1} = lags(im)+1:(lngY+lags(im));
        %template_tries{tcounter,2} = c(im):c(im)+length(Y)-1;
    end
    
    
end
