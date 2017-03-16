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
tag = 1;
while exist(foldername)
foldername = sprintf('%sanalysis-%s-%02i/', mousepath, date, tag);
varfolder = sprintf('%svariables-%s-%02i/', mousepath, date, tag);
tag = tag+1;
end

mkdir(foldername);
mkdir(varfolder);
firstday = 8;

acceptbox = false;
loopstart = tic;
for iday = firstday:length(folders)
    
    clearvars -except mousepath videoanalysispath folders failed foldername varfolder firstday iday yind xind acceptbox loopstart
    close all
    %% video file
    
    warning('off','MATLAB:nargchk:deprecated')
    sessionfolder = [mousepath folders(iday).name '/'];
    vid_dir = dir([sessionfolder 'vid*']);
    if isempty(vid_dir)
        continue
    end
    vid_dir = vid_dir(1).name;
    cam = 'camSleepSetup1.avi';
    vid = [sessionfolder vid_dir '/' cam];
    
    disp('Constructing video reader...')
    tic
    streamer = VideoStreamer(vid);toc;
    if iday == firstday
        fig = figure('Color', 'white', 'Name', 'Drag box to eye corner:');
        drawim = streamer.read(1);
        while ~acceptbox
            imshow(drawim)
            truesize
            axis on
            hold on
            impixelinfo
            rect = [380 300 36 80];
            r2 = imrect(gca, rect);
            setResizable(r2, 0);
            wait(r2);
            pos = getPosition(r2);
            
            %eyeboxcoords = int64(r2);
            rectangle('Position',pos,'EdgeColor','r')
            % Construct a questdlg with three options
            choice = questdlg('Accept rectangle?', ...
                'Rectangle Options', ...
                'Accept','Redraw','New draw frame', 'Accept');
            % Handle response
            switch choice
                case 'Accept'
                    yind = pos(1):pos(1)+pos(3);
                    xind = pos(2):pos(2)+pos(4);
                    hold off
                    acceptbox = true;
                    delete(r2);
                    close(fig)
                case 'Redraw'
                    close(fig)
                    fig = figure('Color', 'white', 'Name', 'Draw box around pupil:');
                    
                case 'New draw frame'
                    a = inputdlg('Select new draw frame: ','Change Draw Frame',1,{num2str(startFrame)});
                    drawim = streamer.read(str2num(a{1}));
            end
        end
    end
    try
        eyeblink(foldername, sessionfolder, streamer, 1, 1, 120, floor(xind), floor(yind));
    catch exception
        failed = [failed; {date}];
        msgText = getReport(exception);
        disp(msgText);
        continue
    end
end
tocvar = toc(loopstart);
hours = floor(tocvar/3600);
minutes = floor((tocvar - 3600*hours)/60);
seconds = floor(tocvar - 3600*hours - 60*minutes);
disp(sprintf('Elapsed time for session: %02i:%02i:%02i.', hours, minutes, seconds));