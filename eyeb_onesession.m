%dd = pwd;
%dd = [dd '/'];
clear
videoanalysispath = '/home/jon/Documents/MATLAB/videoanalysis/';
addpath(genpath(videoanalysispath));
mousepath = uigetdir('/home/jon/Documents/behaviordata', 'Select mouse folder:');
mousepath = [mousepath '/'];
addpath(genpath(mousepath));
cd(mousepath);
folders = dir('0*');
failed = {};
foldername = [mousepath 'analysis-' date '/'];
varfolder = [mousepath 'variables-' date '/'];
mkdir(foldername);
mkdir(varfolder);
for day = 24:length(folders)
    try
    dd = [mousepath folders(day).name '/'];
    
    %Parse out date for case where single date is selected
    dateind = regexp(dd, '\d\d_\d\d_\d\d\d\d');
    date = dd(dateind:dateind+9);
    dateslash = strrep(dd(dateind:dateind+9), '_', '/');    
    %%
    expression = 'C\d';
    nameIndex = regexp(dd,expression);
    mousename = dd(nameIndex:nameIndex+3);
    
    if isempty(mousename)
        %mousename = input('Enter mouse name: ', 's');
        mousename = 'mouse';
    end;
    %%
    
%     if ~exist('tsinfo')
%         if exist([dd 'tsinfo.mat'])
%             load([dd 'tsinfo']);
%         else
%             error(['no tsinfo for ' mousename ' on ' dateslash])
%         end;
%     end;

        if exist([dd 'tsinfo.mat'])
            no_tsinfo = false;
            load([dd 'tsinfo.mat']);
        else
            %error(['no tsinfo for ' mousename ' on ' dateslash])
            disp(['no tsinfo for ' mousename ' on ' dateslash])
            no_tsinfo = true;
        end;

    
    if no_tsinfo
        continue
    end
    
    % trials to include
    te = tsinfo.event.t;
    tid = tsinfo.event.id;
    %kkstep=1; k0=10;kend =40;%length(te)-1;
    %kkstep=5; k0=100;kend =100;
    kkstep=5; k0=10;kend =100;
    
    % window for averaging pixel intensity (initial position)
    yind_ip = 424:455;
    xind_ip = 320:400;
    
    % optimize for individual sessions
    % 10_03_2016_10_09_31//
    yind = yind_ip+6;
    xind = xind_ip+11;
    
    %% video file
    
    warning('off','MATLAB:nargchk:deprecated')
    
    vid_f = fieldnames(tsinfo.video); vid_f = vid_f{1};
    vid_dir = [dd vid_f '/'];
    cam = 'camSleepSetup1.avi';
    vid = [vid_dir cam];
    
    disp('Constructing video reader...')
    tic
    r = VideoStreamer(vid);toc;
    N = r.NumberofFrames;
    tv = tsinfo.video.(vid_f).camSleepSetup1.t;
    
    %% data file
    piezo_ch=3;
    treadmill_ch=2;
    loadpiezo = 1;
    loadtreadmill = 1;
    if loadpiezo
        data_f = fieldnames(tsinfo.data); data_f = data_f{1};
        data_dir = [dd tsinfo.data.(data_f).datadir];
        
        disp('Accessing video data...')
        tic
        fid = dopen(data_dir, 'hmr', 'id', piezo_ch, 'gain', 1);
        [xh, th] = dread(fid); toc;
    end
    if loadtreadmill
        data_f = fieldnames(tsinfo.data); data_f = data_f{1};
        data_dir = [dd tsinfo.data.(data_f).datadir];
        
        disp('Accessing video data...')
        tic
        fid = dopen(data_dir, 'hmr', 'id', treadmill_ch, 'gain', 1);
        [xh_tm, th_tm] = dread(fid); toc;
    end
    
    %%
    % set of frames to measure per trial (relative to CS onset)
    ind = 1:1:16;
    
    
    starttime = tic;
    onesession = struct('datadir',[], 'pztraces', [], 'pztimes', [], 'eyescores', [], ...
        'eyetimes', [], 'avg', [], 'avgtime', [], 'treadtraces', [], 'treadtimes', []);
    
    datadir = data_dir;
    onesession.datadir = datadir;
    showim = 0;
    
    %find id of CS tone
    csus = char(tsinfo.event.list(1));
    csus = regexprep(csus,'[.*: ','');
    cstone = regexprep(csus, '][.*', ']');
    if length(tsinfo.event.list)<3 %if one tone
        cstoneid = 2;
        names = {'CS+US+'; 'CS+'};
    elseif isempty(strfind(char(tsinfo.event.list(2)), cstone)) %if two tone and id of CS+ isn't 2
        cstoneid = 3;
        names = {'CS+US+'; 'CS-'; 'CS+'};
    else %if two tone and id of CS+ is 2
        cstoneid = 2;
        names = {'CS+US+'; 'CS+'; 'CS-'};
    end
    
    colors = ['m' 'g' 'b'];
    kc=0;
    for kk=k0:kkstep:kend
        disp(['Tracing eye images for trial ' num2str(kk) '...'])
        tic
        t0 = te(kk);
        [tve,I] = min(abs(tv-t0)); % I is the frame closest to the ts of the event te(kk);
        % tve is time of frame closest to te(kk)
        
        kc=kc+1;
        if kk==10 | kk==50 | kk==100
            showim = 1;
        else showim = 0;
        end
        figname = sprintf('eye-image-trial-%03i', kk);
        if(showim), figure('Color', 'white', 'Name', figname);  end;
        
        es0=0;
        for jj=1:length(ind)
            framenr = I+ind(jj)-1; % -1 so that I = frame#1
            f = r.read(framenr);
            fe = f(xind,yind,:);
            reltf = tv(framenr)-t0; %time of frame relative to event (ms)
            
            if loadpiezo
                Hmrpz = xh((th>=tv(framenr) & (th<tv(framenr+1))));
                Hmrpzt= th((th>=tv(framenr) & (th<tv(framenr+1))));
                pz=(100/27)*(10+sum(Hmrpzt)*1e-8);
                Hmrpz = decimate(Hmrpz,12);
                
                Hmrtm = xh_tm((th_tm>=tv(framenr) & (th_tm<tv(framenr+1))));
                Hmrtmt= th_tm((th_tm>=tv(framenr) & (th_tm<tv(framenr+1))));
                tm=(100/27)*(10+sum(Hmrtmt)*1e-8);
                Hmrtm = decimate(Hmrtm,12);

                
                eyescore = round(mean(mean(mean(fe))));
                if jj==1
                    onesession(kc).pztimes = Hmrpzt(1:12:end)-t0;
                    onesession(kc).pztraces = 1e7*Hmrpz';
                    
                    onesession(kc).eyescores = eyescore;
                    onesession(kc).eyetimes = reltf;
                    onesession(kc).stimid = names{tid(1)};
                    onesession(kc).treadtimes = Hmrtmt(1:12:end)-t0;
                    onesession(kc).treadtraces = 1e4*Hmrtm';
                else
                    onesession(kc).pztimes = [onesession(kc).pztimes, Hmrpzt(1:12:end)-t0];
                    onesession(kc).pztraces = [onesession(kc).pztraces, 1e7*Hmrpz'];
                    onesession(kc).treadtimes = [onesession(kc).treadtimes, Hmrtmt(1:12:end)-t0];
                    onesession(kc).treadtraces = [onesession(kc).treadtraces, 1e4*Hmrtm'];
                    
                    onesession(kc).eyescores = [onesession(kc).eyescores, eyescore];
                    onesession(kc).eyetimes = [onesession(kc).eyetimes, reltf];
                    onesession(kc).stimid = names{tid(kk)};
                end
            end
            
            if (showim)
                tit = sprintf('Event %d: t%2.0f ', kk, round(reltf) );
                subplot(4,4,jj);
                imshow(fe); title(tit);
                if jj==1
                    hold on; plot([27,27],[0,28],'r');
                    %             elseif jj == 2
                    %                 subplot(4,4,2);title(strrep(strcat('xi:',num2str(xind(1)),'-',num2str(xind(end))), '_', '\_'));
                    %              elseif jj == 3
                    %                 subplot(4,4,3);title(strrep(strcat('yi:',num2str(yind(1)),'-',num2str(yind(end))), '_', '\_'));
                    %             elseif jj == 4
                    %                 subplot(4,4,4);title(strrep(strcat(mousename,'_',datadir), '_', '\_'));
                elseif jj==16
                    hold on; plot([0,35],[50,50],'r');
                end
                savefig([dd figname])
            end;
            
        end;
        if loadpiezo
            onesession(kc).pztraces_sm = smooth(onesession(kc).pztraces,10);
            for sm=1:49
                onesession(kc).pztraces_sm = smooth(onesession(kc).pztraces_sm,10);
            end
        end
        %pause;
        toc;
    end;
    disp(['Total elapsed time: ' num2str(toc(starttime)) ' seconds.']);
    
    
    
    if loadpiezo
        eyescorefig = figure('Color', 'white', 'Name', 'Eyescore and Piezo Trace') ; hold on;
        for kk=k0:kkstep:kend
            id = tid(kk);
            
            eyescoretrace = onesession(1+(kk-k0)/kkstep).eyescores-onesession(1+(kk-k0)/kkstep).eyescores(1);
            pztrace = onesession(1+(kk-k0)/kkstep).pztraces_sm-onesession(1+(kk-k0)/kkstep).pztraces_sm(100);
            if pztrace(950) < 10 | id == 1
                % probe trial
                subplot(3,1,[1:2]); plot(onesession(1+(kk-k0)/kkstep).eyetimes,eyescoretrace, 'color', colors(id)); hold on;
                subplot(3,1,3); plot(onesession(1+(kk-k0)/kkstep).pztimes,pztrace,'color', colors(id)); hold on;
                
            else
                subplot(3,1,[1:2]); plot(onesession(1+(kk-k0)/kkstep).eyetimes,eyescoretrace, 'm'); hold on;
                subplot(3,1,3); plot(onesession(1+(kk-k0)/kkstep).pztimes,pztrace,'m');hold on;
            end;
        end;
        %     for kk=1:length(onesession)
        %         id = tid(kk);
        %
        %         eyescoretrace = onesession(kk).eyescores-onesession(kk).eyescores(1);
        %         pztrace = onesession(kk).pztraces_sm-onesession(kk).pztraces_sm(100);
        %         if pztrace(950) < 10 | id == 1
        %             % probe trial
        %             subplot(3,1,[1:2]); plot(onesession(kk).eyetimes,eyescoretrace, 'color', colors(id)); hold on;
        %             subplot(3,1,3); plot(onesession(kk).pztimes,pztrace,'color', colors(id)); hold on;
        %
        %         else
        %             subplot(3,1,[1:2]); plot(onesession(kk).eyetimes,eyescoretrace, 'm'); hold on;
        %             subplot(3,1,3); plot(onesession(kk).pztimes,pztrace,'m');hold on;
        %         end;
        %     end;
        eyescoreplot = subplot(3,1,[1:2]); axis([33 500 -10 80])
        %legend('CS+US+', 'CS+', 'CS-', 'Location','northwest')
        ylabel(eyescoreplot, 'Pixel intensity')
        title(eyescoreplot, ['Eyeblink latency (' mousename ': ' dateslash ')'])
        piezoplot = subplot(3,1,3); axis([33 500 -2 40])
        title(piezoplot, 'Piezo trace')
        xlabel(piezoplot, 'Time (us)')
        ylabel(piezoplot, 'Air pressure')
        %title(['top:behavior bottom:piezo',strrep(strcat(mousename,'_',datadir), '_', '\_')]);
        halffig = figure('Color', 'white', 'Name', '1st and 2nd halves'); hold on;
        %halfnrtrs = floor((kend-k0+1)/(2*kkstep));
        halfnrtrs = floor(length(onesession)/2);
        
        avg = zeros(size(onesession(1).eyescores));
        avgtime = zeros(size(onesession(1).eyetimes));
        for trnr=1:halfnrtrs
            avg = avg+onesession(trnr).eyescores-onesession(trnr).eyescores(1);
            avgtime = avgtime+onesession(trnr).eyetimes;
        end;
        avg = avg/halfnrtrs;
        avgtime = avgtime/halfnrtrs;
        plot(avgtime, avg, 'b', 'LineWidth', 2);
        
        
        avg2 = zeros(size(avg));
        avgtime2 = zeros(size(avgtime));
        for trnr=halfnrtrs+1:2*halfnrtrs
            avg2 = avg2+onesession(trnr).eyescores-onesession(trnr).eyescores(1);
            avgtime2 = avgtime2+onesession(trnr).eyetimes;
        end;
        
        
        avg2 = avg2/halfnrtrs;
        avgtime2 = avgtime2/halfnrtrs;
        plot(avgtime2, avg2, 'k', 'LineWidth', 2);
        title(strrep(strcat(mousename,'_',datadir), '_', '\_'));
        legend('1st half', 'second half', 'Location', 'SouthEast');
        axis([33 500 -inf inf]);
        
        onesession(1).avg = avg;
        onesession(1).avgtime = avgtime;
        
        onesession(2).avg = avg2;
        onesession(2).avgtime = avgtime2;
        
        onesession(3).avg = (avg+avg2)/2;
        onesession(3).avgtime = (avgtime+avgtime2)/2;
        savefig(halffig, [dd 'half_time_performance'])
        savefig(eyescorefig, [dd 'eyescore_trace'])
    end
    dd = dd(1:dateind-1);
    save([foldername mousename '_' date '.mat'], 'onesession');

    whos('-file', [varfolder date '.mat']);
    clearvars -except mousepath videoanalysispath folders failed foldername varfolder
    close all
    catch exception
        failed = [failed; {date}];
        msgText = getReport(exception);
        disp(msgText);
        continue
    end
end
return;






