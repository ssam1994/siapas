function [xh_tr, th] = readTreadmillData(dd)
if exist([dd 'tsinfo.mat'])
     load([dd 'tsinfo']);
else
      error('no tsinfo') 
end;

treadmill_ch =2;
data_f = fieldnames(tsinfo.data); 
data_f = data_f{1};
data_dir = [dd tsinfo.data.(data_f).datadir];

fid = dopen(data_dir, 'hmr', 'id', treadmill_ch, 'gain', 1);
[xh_tr, th] = dread(fid); 