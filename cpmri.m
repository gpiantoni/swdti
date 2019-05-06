function cpmri(cfg, subj)
%CPMRI copy MRI images
% fslmaths gosd_svui_0001_smri_t1_brain.nii.gz -add gosd_svui_0002_smri_t1_brain.nii.gz -add gosd_svui_0003_smri_t1_brain.nii.gz -add gosd_svui_0004_smri_t1_brain.nii.gz -add gosd_svui_0006_smri_t1_brain.nii.gz -add gosd_svui_0006_smri_t1_brain.nii.gz -add gosd_svui_0007_smri_t1_brain.nii.gz -add gosd_svui_0008_smri_t1_brain.nii.gz -add gosd_svui_0009_smri_t1_brain.nii.gz -add gosd_svui_0010_smri_t1_brain.nii.gz -add gosd_svui_0011_smri_t1_brain.nii.gz -add gosd_svui_0012_smri_t1_brain.nii.gz -add gosd_svui_0013_smri_t1_brain.nii.gz -add gosd_svui_0015_smri_t1_brain.nii.gz -div 13 gosd_svui_avg_smri_t1_brain

mversion = 1;
%01 11/10/11 created

%-----------------%
%-input
if nargin == 1
  subj = cfg.subj;
end
%-----------------%

%---------------------------%
%-start log
output = sprintf('(p%02.f) %s (v%02.f) started at %s on %s\n', ...
  subj, mfilename,  mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%---------------------------%
%-dir and files
rdir = sprintf('%s%04.f/%s/%s/', cfg.recs, subj, cfg.mod3, cfg.rawd); % recording
ddir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod3, cfg.cond3); % data
if isdir(ddir); rmdir(ddir, 's'); end
mkdir(ddir)

rfile = sprintf('%s_%04.f_%s_%s', cfg.rec, subj, cfg.mod3, cfg.cond3); % recording
dfile = sprintf('%s_%s_%04.f_%s_%s', cfg.proj, cfg.rec, subj, cfg.mod3, cfg.cond3); % data
%---------------------------%

%---------------------------%
%-get data
ext = '.nii.gz';
system(['ln ' rdir rfile ext ' ' ddir dfile ext]);
%---------------------------%

%---------------------------%
%-realign
%-------%
%-bet
system(['/usr/local/fsl/bin/bet ' ddir dfile ' ' ddir dfile '_brain -f 0.5 -g 0']);
%-------%

%-------%
%-flirt
system(['/usr/local/fsl/bin/flirt -in ' ddir dfile '_brain -ref /usr/local/fsl/data/standard/MNI152_T1_1mm_brain ' ...
  '-out ' ddir dfile '_brain_flirt -omat ' ddir dfile '_brain_flirt.mat ' ...
  '-bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear']);
%-------%

%-------%
%-fnirt
%-------%

%-------%
%-copy data
system(['ln ' ddir dfile '_brain_flirt.nii.gz ' cfg.smri dfile '_brain.nii.gz']);
%-------%
%---------------------------%

%---------------------------%
%-end log
toc_t = toc(tic_t);
outtmp = sprintf('(p%02.f) %s (v%02.f) ended at %s on %s after %s\n\n', ...
  subj, mfilename, mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
  datestr( datenum(0, 0, 0, 0, 0, toc_t), 'HH:MM:SS'));
output = [output outtmp];

%-----------------%
fprintf(output)
fid = fopen([cfg.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%