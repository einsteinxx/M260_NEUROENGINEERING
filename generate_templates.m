%get templates and try them out



%%
fig_dir = '/home/kgonzalez/FALL2018/BIOENG_M260/PROJECT/FIG_DIR';

%% Scan for slopes beside each central peak
dy = diff(yfilt1);
ddy = diff(dy);
dt = diff(time); %fixed sampling, so should not change


close all
for ii = 1:3 %length(peaks)
    
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
       plot(time(pfound(jj)), peaks(pfound(jj)), 'rd');
       end
       plot(time(locs(ii)), peaks(ii));
       title(sprintf('ii = %d',ii));
       grid on;
       
       plot(time(pfound(1)-1:pfound(end)-1), ...
           dy(pfound(1):pfound(end)),'gx-.')
       
       pname = sprintf('Peak_list_%d.png',ii);
       pname = fullfile(fig_dir, pname);
       saveas(gcf,pname);
       close(gcf)
       
       try_templates(yfilt1, pfound,ii, fig_dir);
    end
    

end




%%


template = yfilt1(pfound(1):pfound(end));
figure, plot(template);


%