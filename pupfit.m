mousepath = uigetdir('/home/jon/Documents/behaviordata', 'Select mouse folder:');
mousepath = [mousepath '/'];
addpath(genpath(mousepath));    
videoanalysispath = '/home/jon/Documents/MATLAB/videoanalysis/';
    addpath(genpath(videoanalysispath));
cd(mousepath);
folders = dir('0*');
failed = {};
foldername = [mousepath 'pupil-' date '/'];
mkdir(foldername);
diameters = {};
k0 = 10;
kkstep = 10;
kend = 100;
trialframes = 30;
preframes = 10; %number of frames before CS onset
firstday = 14;
datepath = [mousepath folders(firstday).name '/'];
addpath(genpath(datepath));
cd(datepath);
viddir = dir('vid*');
viddir = viddir.name;
write_vid = true;
dd = [datepath viddir '/'];
cd(dd);
r = VideoStreamer('camSleepSetup1.avi');
h = r.Height;
w = r.Width;
firstim = r.read(1);
fig = figure('Color', 'white', 'Name', 'Draw box around pupil:');
drawim = firstim;
acceptbox = false;
while ~acceptbox
    imshow(drawim)
    truesize
    hold on
    eyeboxcoords = getrect;
    eyeboxcoords = uint32(eyeboxcoords);
    rectangle('Position',eyeboxcoords,'EdgeColor','r')
    % Construct a questdlg with three options
    choice = questdlg('Accept rectangle?', ...
        'Rectangle Options', ...
        'Accept','Redraw','New draw frame', 'Accept');
    % Handle response
    switch choice
        case 'Accept'
            eyex = eyeboxcoords(1):(eyeboxcoords(1)+eyeboxcoords(3));
            eyex = double(eyex);
            eyey = eyeboxcoords(2):(eyeboxcoords(2)+eyeboxcoords(4));
            eyey = double(eyey);
            hold off
            acceptbox = true;
        case 'Redraw'
            close(fig)
            fig = figure('Color', 'white', 'Name', 'Draw box around pupil:');
            continue
        case 'New draw frame'
            a = inputdlg('Select new draw frame: ','Change Draw Frame',1,{num2str(startFrame)});
            drawim = r.read(str2num(a{1}));
    end
end

acceptthresh = false;
grayim = rgb2gray(drawim);
thresh = 0.15;
    boxarea = range(eyex)*range(eyey);
    filtersize = floor(boxarea/32);
while ~acceptthresh
    imshow(bwareaopen(imbinarize(grayim, thresh), filtersize));
    % Construct a questdlg with three options
    choice = questdlg('Accept threshold?', ...
        'Rectangle Options', ...
        'Accept','Up','Down', 'Accept');
    % Handle response
    switch choice
        case 'Accept'
            hold off
            acceptthresh = true;
        case 'Up'
            thresh = min(1.0, thresh + 0.01);
            continue
        case 'Down'
            thresh = max(0, thresh - 0.01);
            continue
    end
end

for day = firstday:length(folders)
    
    datepath = [mousepath folders(day).name '/'];
    addpath(genpath(datepath));
    cd(datepath);
    viddir = dir('vid*');
    if isempty(viddir)
        continue
    end
    viddir = viddir.name;
    
    dd = [datepath viddir '/'];
    cd(dd);

    
    if exist([datepath 'tsinfo.mat'])
        no_tsinfo = false;
        load([datepath 'tsinfo.mat']);
    else
        %error(['no tsinfo for ' mousename ' on ' dateslash])
        disp(['no tsinfo for'])
        no_tsinfo = true;
        continue
    end
    
    vid_f = fieldnames(tsinfo.video); vid_f = vid_f{1};
    te = tsinfo.event.t;
    ind = 1:trialframes;
    tv = tsinfo.video.(vid_f).camSleepSetup1.t;
    
    
    kk=k0:kkstep:kend;
    numtrials = length(kk);
    I = zeros(1, numtrials);
    for i = 1:numtrials
        t0 = te(kk(i));
        [tve,I(i)] = min(abs(tv-t0));
    end
    frames = repmat(ind,numtrials, 1);
    I = repmat(I', 1, trialframes);
    frames = I + frames - 1 - preframes; % -1 so that I = frame#1
    
    frames = reshape(frames', 1, []);
    vid = [dd 'camSleepSetup1.avi'];
    csonsetframes = frames + preframes;
    csonsetframes = csonsetframes(1:trialframes:end);
    try
        diameter = fit_pupil(eyex, eyey, thresh, frames, vid, dd, write_vid );
        
    catch exception
        msgText = getReport(exception);
        disp(msgText);
        ellipse_t = struct( ...
            'a',[],...
            'b',[],...
            'phi',[],...
            'X0',[0],...
            'Y0',[0],...
            'X0_in',[],...
            'Y0_in',[],...
            'long_axis',[0],...
            'short_axis',[0],...
            'status','');
        xcoords = [];
        ycoords = [];
        msgText = getReport(exception);
        disp(msgText);
        
        continue
    end
    diameterstruct = struct(...
        'date', folders(day).name,...
        'diameters', diameter,...
        'frametimes', frames/30, ...
        'csonsetframes', csonsetframes,...
        'csonsettimes', csonsetframes/30, ...
        'trials', kk);
    save([foldername folders(day).name '.mat'], 'diameterstruct')
end