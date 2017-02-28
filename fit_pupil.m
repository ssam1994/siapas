
function diameter = fit_pupil_copy(eyeboxx, eyeboxy, thresh, frames, vid, dd, write_vid )
r = VideoStreamer(vid);
s = size(frames);
numFrames = s(2);
h = r.Height;
w = r.Width;

if write_vid
    v = VideoWriter([dd 'pupil-' date '.avi']);
    open(v)
end

warning('off','MATLAB:nargchk:deprecated')

fig = figure('Color', 'white', 'Name', 'Pupil Trace', 'units', 'normalized', 'position', [.1 .1 .3 .7]);
bwax = subplot(211);
fitax = subplot(212);
diameter = zeros(1, length(frames), 'uint8');
f = zeros(h, w, 3, 'uint8');
%fmono = zeros(h, w, 1, 'logical');
f(:, :, :) = r.read(frames(1));
fgray = rgb2gray(f);
fbw = imbinarize(fgray, thresh);
eyeboxbw = fbw(eyeboxy, eyeboxx, 1);
boxarea = range(eyeboxx)*range(eyeboxy);
filtersize = floor(boxarea/32);
eyeboxbw = bwareaopen(eyeboxbw, filtersize);
axes(bwax);
imshow(eyeboxbw);
pupil = find(eyeboxbw<1);
if isempty(pupil)
    pupil = find(eyeboxbw==1);
end
[y, x] = ind2sub(size(eyeboxbw), pupil);
bounds = boundary(x, y, 0);
axes(fitax);
imshow(f(:, :, :)); hold on;
%[ellipse_t, xcoords, ycoords] = fit_ellipse(x(bounds)+eyeboxx(1),y(bounds)+eyeboxy(1),gca);
hold off;
F = getframe(gcf);
Fim = frame2im(F);
[movh, movw, rgb] = size(Fim);
fvid = zeros(movh, movw, rgb, numFrames, 'uint8');
j=0;
for i=frames
    j=j+1;
    f = r.read(i);
    fgray = rgb2gray(f);
    fbw = imbinarize(fgray, thresh);
    eyeboxbw = fbw(eyeboxy, eyeboxx, 1);
    boxarea = range(eyeboxx)*range(eyeboxy);
    filtersize = floor(boxarea/32);
    eyeboxbw = bwareaopen(eyeboxbw, filtersize);
    %     CC = bwconncomp(eyeboxbw, 8);
    %     numPixels = cellfun(@numel,CC.PixelIdxList);
    %     [biggest,idx] = max(numPixels);
    %     pupil = zeros(size(eyebox));
    %     pupil(CC.PixelIdxList{idx}) = 1;
    
    
    pupil = find(eyeboxbw==false);
    if isempty(pupil)
        pupil = find(eyeboxbw~=false);
    end
    axes(bwax);
    imshow(eyeboxbw);
    [y, x] = ind2sub(size(eyeboxbw), pupil);
    bounds = boundary(x, y);
    if write_vid
        axes(fitax);
        imshow(f(:, :, :)); hold on;
    end
    try
        %[ellipse_t, xcoords, ycoords] = fit_ellipse(x(bounds)+eyeboxx(1),y(bounds)+eyeboxy(1),gca);
        [ellipse_t, xcoords, ycoords] = fit_ellipse(x+eyeboxx(1),y+eyeboxy(1),gca);
    catch exception
        msgText = getReport(exception);
        disp(msgText);
        ellipse_t = struct( ...
            'a',[],...
            'b',[],...
            'phi',[],...
            'X0',[],...
            'Y0',[],...
            'X0_in',[],...
            'Y0_in',[],...
            'long_axis',[0],...
            'short_axis',[0],...
            'status','');
        xcoords = [];
        ycoords = [];
        continue
    end
    if write_vid
        drawnow
        F = getframe(gcf);
        [fvid(:, :, :, j), Map] = frame2im(F);
        writeVideo(v,fvid(:, :, :, j));
    end
    diameter(j) = ellipse_t.long_axis;
end

if write_vid
    
    close(v)
end
return
end

%profile on
%profile view/er