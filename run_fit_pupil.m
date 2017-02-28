%run_fit_pupil
%Turn off NARGCHK warning
warning('off','MATLAB:nargchk:deprecated');
%Find video file
[vidFile,vidPath,FilterIndex] = uigetfile('*.avi', 'Select video:', '/home/jon/Documents/behaviordata/C103example/10_03_2016_10_09_31/');
videoanalysispath = '/home/jon/Documents/MATLAB/videoanalysis/';
addpath(genpath(videoanalysispath));
cd(vidPath);

%%
%Video dimensions
r = VideoStreamer(vidFile);
h = r.Height;
w = r.Width;
numFrames = r.NumberOfFrames;

%%
%Get Frames to fit
acceptbox = false;
prompt = {'Enter start frame:',sprintf('Enter end frame (%d frames):',numFrames), 'Enter frame skip:'};
dlg_title = 'Pupil Fit Options';
num_lines = 1;
defaultans = {'3290','3310', '1'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
startFrame = str2num(answer{1});
endFrame = str2num(answer{2});
frameSkip = str2num(answer{3});
frames = startFrame:frameSkip:endFrame;

%%
%Specifying eyebox
firstim = r.read(startFrame);
drawim = firstim;
fig = figure('Color', 'white', 'Name', 'Draw Pupil Box');

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
while ~acceptthresh
    imshow(imbinarize(grayim, thresh));
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


%%
%Call fit_pupil
diameters = fit_pupil(eyex, eyey, thresh, frames, vidFile, vidPath, true);


