%whisking
%01/13/17
clear all
level = 0.3;

videoanalysispath = '/home/jon/Documents/MATLAB/videoanalysis/';
addpath(genpath(videoanalysispath));
dd = uigetdir('/home/jon/Documents/behaviordata', 'Select date folder:');
dd = [dd '/'];
addpath(genpath(dd));
%%

if ~exist('tsinfo')
    if exist([dd 'tsinfo.mat'])
        load([dd 'tsinfo']);
    else
        error('no tsinfo')
    end;
end;

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

bwim = im2bw(r.read(1), level);
numFrames = 500;
diffscores = zeros(1, numFrames+1);
frameskip = 2;
fend = numFrames*frameskip;
h = r.Height;
w = r.Width;
f = zeros(h, w, 3, numFrames+1, 'uint8');
fgray = zeros(h, w, 1, numFrames+1, 'uint8');
fgraysub = zeros(h, w, 1, numFrames+1, 'uint8');
% fmono = zeros(h, w, 1, numFrames, 'logical');
% fedge = zeros(h, w, 1, numFrames, 'logical');
% fedgesub = zeros(h, w, 3, numFrames, 'uint8');
%points = zeros(h, w, numFrames);

hf = figure;
colormap(hf, 'gray');
subax = subplot(211);axis([0 w 0 h])
colorax = subplot(212);axis([0 w 0 h])
f(:, :, :, 1) = r.read(1);
fgray(:, :, 1) = rgb2gray(f(:,:,:,1));
fgraysub(:, :, 1) = fgray(:, :, 1);
% fmono(:, :, 1, 1) = im2bw(f(:,:,:, 1), level);
% fedge(:, :, 1, 1) = edge(fmono(:,:,1));
% red = zeros(1,1,3);
% red(1,1,1)=255;
axis equal

disp('Finding edges...')
tic
j=1;
numPix = numel(fgraysub(:,:,j));
for i = 1:frameskip:fend
    j=j+1;
    f(:, :, :, j) = r.read(i);
    fgray(:, :, j) = rgb2gray(f(:, :, :, j));
    fgraysub(:, :, j) = 10*(fgray(:, :, j) - fgray(:, :, j-1));
    mat = fgraysub(:,:,j);
    s = sum(mat(:));
    diffscores(j) = s/numPix;
    
%     fmono(:, :, 1, i) = im2bw(f(:,:,:,i), level);
%     fedge(:, :, 1, i) = edge(fmono(:,:,1,i));
%     fedgesub(:, :, 1, i) = 255*double(fedge(:,:,1,i-1) & fedge(:,:,1,i));
%     fedgesub(:, :, 1, i) = 1+fedgesub(:,:,1,i);
    %determ(i) = det(double(fedgesub(floor(h/2):end, 1:floor(h/2)+1, 1, i)));
    %[ypoints, xpoints] = ind2sub([h w], find(fedgesub(:,:,1,i)>0));
    
    %imagesc(fedgesub(:,:,:,i), 'parent', subax);
    %imagesc(f(:,:,:,i), 'parent', colorax); hold on;
    %scatter(xpoints, ypoints, 'r.');
    %drawnow
end

smoothdif = smooth(diffscores(5:end));
whiskthresh = 0.6*range(smoothdif) + min(smoothdif);
plot(7:frameskip:fend, smoothdif', 'k'); hold on;
plot([0 fend],  [whiskthresh whiskthresh], 'r');
[xi,yi] = polyxpoly(7:frameskip:fend,smoothdif',[0 fend],[whiskthresh whiskthresh]);

dateind = regexp(dd, '\d\d_\d\d_\d\d\d\d');
day = dd(dateind:dateind+9);
dateslash = strrep(dd(dateind:dateind+9), '_', '/');
expression = 'C\d';
nameIndex = regexp(dd,expression);
mousename = dd(nameIndex:nameIndex+3);
title(['Whisking (' mousename ': ' dateslash ')']);
xlabel('Frame Number');
savefig([dd 'whisking']);
toc;
v = VideoWriter([dd 'graysub.avi']);
%fedgesub(fedgesub<1) = f(fedgesub<1);
open(v)
writeVideo(v,fgraysub)

close(v)
%plot(difscores(1:760))
