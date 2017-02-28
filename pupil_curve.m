%Learning Curve

%Load sessions
sessionsfolder = uigetdir('/home/jon/Documents/behaviordata/', 'Select analysis Folder:');
C = strsplit(sessionsfolder,'/');
sf = C{end};
sessionsfolder = [sessionsfolder '/'];

addpath(genpath(sf));
cd(sessionsfolder)

%Get all the names of single sessions stored
pupildata = dir('*.mat');
pupfig = figure('Color', 'white', 'Name', 'Pupil Data', 'units', 'normalized', 'position', [.1 .1 .3 .7]); hold on

%subplot for diameters
dplot = subplot(2,1,1);

%subplot for velocity
vplot = subplot(2,1,2);

%subplot for acceleration
%aplot = subplot(313);

linestyle = {'-'; ':'; '--'};
obj = [];
split = {[]; []; []};
daystruct = struct('id', {'CS+US+'; 'CS+'; 'CS-'},...
    'included', {false; false; false}, ...
    'avgtrace', split, 'avgtimes',split);
pupil = struct('day', {1; length(pupildata)}, 'data', {daystruct; daystruct});

for day = 1:length(pupildata)
    
    cd ..
    da = regexprep(pupildata(day).name, '.mat', '');
    if exist([da '/' 'tsinfo.mat'])
        no_tsinfo = false;
        load([da '/' 'tsinfo.mat']);
    else
        %error(['no tsinfo for ' mousename ' on ' dateslash])
        %disp(['no tsinfo for ' mousename ' on ' dateslash])
        no_tsinfo = true;
        continue
    end;
    
    
    cd(sf)
    tid = tsinfo.event.id;
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
    
    session_data = load(pupildata(day).name);
    session_data = session_data.diameterstruct;
    diameters = session_data.diameters;
    frametimes = session_data.frametimes;
    consetframes = session_data.csonsetframes;
    csonsettimes = session_data.csonsettimes;
    trials = session_data.trials;
    switch day
        case 1
            halfcol = 'r';
            halfnum = 1;
            displayname = 'Day 1';
        case length(pupildata)
            halfcol = 'b';
            displayname = ['Day ' num2str(day)];
            halfnum = 2;
        otherwise
            continue
    end
    
    
    for trial = trials
        id = names{tid(trial)};
        pupil(halfnum).data(tid(trial)).included = true;
        i = find(trials==trial);
        trialframes = length(diameters)/length(trials);
        j = trialframes*(i-1);
        framerange = j+1:j+trialframes;
        
        d = diameters(framerange);
        pupil(halfnum).data(tid(trial)).avgtrace = [pupil(halfnum).data(tid(trial)).avgtrace; d];
        
        ft = frametimes(framerange) - csonsettimes(i);
        pupil(halfnum).data(tid(trial)).avgtimes = [pupil(halfnum).data(tid(trial)).avgtimes; ft];
        
        p = plot(dplot, ft, d, [halfcol linestyle{tid(trial)}]);
        
        set(p, 'DisplayName', [id ' Day ' num2str(day)]);
        obj = [obj p];
        hold(dplot, 'on')
        plot(dplot, [0 0], [50 50], 'g--')
        hold(dplot, 'on')
        
    end
    
    for ttype = 1:3
        t = size(pupil(halfnum).data(ttype).avgtimes);
        t = t(1);
        if pupil(halfnum).data(ttype).included
            avt = sum(pupil(halfnum).data(ttype).avgtimes, 1)/t;
            av = sum(pupil(halfnum).data(ttype).avgtrace, 1)/t;
            ap = plot(vplot, avt, av, [halfcol linestyle{ttype}], 'LineWidth', 2); hold(vplot, 'on');
            set(ap, 'DisplayName', [names{ttype} ' Day ' num2str(day)])
            
        end
    end
    
    
    
end


hold(dplot, 'off')
objc = unique({obj.DisplayName});

legend(vplot, 'Location', 'northwest');
xlabel(vplot, 'Time (ms) after CS onset')
ylabel(vplot, 'Average pupil diameter (px)')


xlabel(dplot, 'Time (ms) after CS onset')
ylabel(dplot, 'Single trial pupil diameter (px)')

cindex = regexp(sessionsfolder, 'C\d+');
title(dplot, sessionsfolder(cindex:cindex+3))

savefig(pupfig, [sessionsfolder 'pupil-trace'])