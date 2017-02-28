%Learning Curve

%Load sessions
sessionsfolder = uigetdir('/home/jon/Documents/behaviordata/', 'Select analysis Folder:');
sessionsfolder = [sessionsfolder '/'];

addpath(genpath(sessionsfolder));
cd(sessionsfolder)

%Get all the names of single sessions stored
onesessions = dir('*.mat');
auc = [];
onset = [];

%Calculate plot data
lcfig = figure('Color', 'white', 'Name', 'Learning Curve', 'units', 'normalized', 'position', [.1 .1 .3 .7]); hold on

%subplot for average eyescore traces
avgplot = subplot(312);

%subplot for blink latency
onsetplot = subplot(311);

%subplot for treadmill traces
treadplot = subplot(313);



%color index for trial types
col = {'m' 'g' 'b'};
stimnames = {'CS+US+' 'CS+' 'CS-'};
%separate trial types
split = {[]; []; []};
split_data = struct('id', {'CS+US+'; 'CS+'; 'CS-'}, 'included', {false; false; false}, 'onset', split, 'avgtimes', split, 'avgtraces', split, 'avgtreadtimes', split, 'avgtreadtraces', split);


%keep track of the trial number throughout session days
j=0;

%loop through sessions (days) contained in sessions folder
for i = 1:length(onesessions)
    %load single session
    %(chosen to do this inside loop
    %in the event that number of trials per session varies)
    session_data = load(onesessions(i).name);
    session_data = session_data.onesession;
    session_size = size(session_data);
    numTrials = session_size(2);
    
    %allocate space for index where eyescore threshold is crossed
    crossthresh = zeros(1, numTrials);
    
    %loop through trials in session
    for trial = 1:numTrials
        %get eyescoretrace data
        eyescoretrace = session_data(trial).eyescores-session_data(trial).eyescores(1);
        
        %auc = [auc trapz(eyescoretrace)];
        
        %set threshold to 1 eyescore above the max eyescore in the first three entries
        thresh = 1 + max(eyescoretrace(1:3));
        
        %calculate timepoint where this threshold is crossed
        [xi,yi] = polyxpoly(session_data(trial).eyetimes,eyescoretrace,[0 500],[thresh thresh]);
        
        %if threshold is not crossed (no blink detected), set onset to 500 ms
        if isempty(xi)
            crossthresh(trial) = 500;
            %set onset to the last point threshold crossed
        else
            crossthresh(trial) = xi(end);
        end
        
        %parse data for trial type
        stim = session_data(trial).stimid;
        stimid = find(ismember(extractfield(split_data, 'id'), stim));
        
        if ~split_data(stimid).included
            split_data(stimid).onset = [j + trial, crossthresh(trial)];
            split_data(stimid).avgtimes = session_data(trial).eyetimes;
            split_data(stimid).avgtraces = eyescoretrace;
            if isfield(session_data,'treadtimes')
                split_data(stimid).avgtreadtraces = session_data(trial).treadtraces;
                split_data(stimid).avgtreadtimes = session_data(trial).treadtimes;
            end
        else
            %split data by trial type
            split_data(stimid).onset = [split_data(stimid).onset; [j + trial, crossthresh(trial)]];
            split_data(stimid).avgtimes = [split_data(stimid).avgtimes; session_data(trial).eyetimes];
            split_data(stimid).avgtraces = [split_data(stimid).avgtraces; eyescoretrace];
%             if isfield(session_data,'treadtimes')
%                 split_data(stimid).avgtreadtraces = [split_data(stimid).avgtreadtraces; session_data(trial).treadtraces];
%                 split_data(stimid).avgtreadtimes = [split_data(stimid).avgtreadtimes; session_data(trial).treadtimes];
%             end
            
        end

        split_data(stimid).included = true;
        
    end
    
    %update trial number
    j = j + numTrials;
    
    %prepare avg eyescore trace plots if first or last days
    switch i
        case 1
            halfcol = 'r';
            halfnum = 1;
            displayname = 'First Day';
        case length(onesessions)
            halfcol = 'b';
            displayname = 'All Days';
            halfnum = 2;
        otherwise
            continue
    end
    
    
    linestyle = {'-'; ':'; '--'};
    %plot average trace
    for ttype = 1:3
        t = size(split_data(ttype).avgtimes);
        t = t(1);
        if split_data(ttype).included
            avt = sum(split_data(ttype).avgtimes, 1)/t;
            av = sum(split_data(ttype).avgtraces, 1)/t;
            ap = plot(avgplot, avt, av, [halfcol linestyle{ttype}], 'LineWidth', 2); hold(avgplot, 'on');
            set(ap, 'DisplayName', [stimnames{ttype} ' Day ' num2str(i)])
            if isfield(session_data, 'treadtimes')
                avtmt = sum(split_data(ttype).avgtreadtimes, 1)/t;
                avtm = sum(split_data(ttype).avgtreadtraces, 1)/t;
                atmp = plot(treadplot, avtmt, avtm, [halfcol linestyle{ttype}], 'LineWidth', 2); hold(treadplot, 'on');
                set(atmp, 'DisplayName', [stimnames{ttype} ' Day ' num2str(i)])
            end
        end
    end
end

%plot details for average traces
%legend(avgplot, [ap(1), ap(2)], {'Day 1', ['Day ' num2str(i)]}, 'Location', 'northwest')
%axis(avgplot,[0 500 -10 60]);
legend(avgplot, 'Location', 'northwest');
legend(treadplot, 'Location', 'northwest');
hold(avgplot, 'off')
hold(treadplot, 'off')
xlabel(avgplot, 'Time (ms) after CS onset')
ylabel(avgplot, 'Eyescore (pixel intensity)')

%plot latency data
for g = 1:3
    if split_data(g).included
        plot(onsetplot, split_data(g).onset(:,1),  split_data(g).onset(:,2), [col{g} 'o'], 'DisplayName', stimnames{g})
        hold(onsetplot, 'on')
        sz = size(split_data(g).avgtimes);
        obs = sz(1);
%         if obs>1
%             simple = tsmovavg(split_data(g).onset(:,2),'s',floor(obs/2),1);
%             plot(onsetplot, split_data(g).onset(:,1),  simple, [col{g} '-'])
%             hold(onsetplot, 'on')
%         end
    end
end

%plot details for latency data
legend(onsetplot, stimnames, 'Location', 'southwest')
cindex = regexp(sessionsfolder, 'C\d+');
title(onsetplot, sessionsfolder(cindex:cindex+3))
xlabel(onsetplot, ['Trial #' ' (' num2str(length(onesessions)) ' sessions)'])
ylabel(onsetplot, 'Blink Latency (ms)')

%plot details for latency data
xlabel(treadplot, ['Time (ms) after CS onset'])
ylabel(treadplot, 'Trace')

%save figure in folder containing data for all sessions plotted
savefig(lcfig, [sessionsfolder 'learning'])