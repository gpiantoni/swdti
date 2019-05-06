function cpdti(cfg, subj)
%CPDTI: rename files in gosd, following the naming convetion:
% Results should be in form:
%   gosd_003_smri_dti
% where
%   003 is the subject number (following the VU numbering)
% it also creates the bvec and bval files. Check that read_par is in
% private

mversion = 8;
%08 11/11/10 dcm2nii should not zip (I cannot unzip anymore)
%07 11/11/10 part of final_swdti (dcm2nii works)
%06 11/10/12 copy b0 and grad as well
%05 11/10/11 don't copy into recordings, but project "gosd"
%04 11/08/19 rename dti file within .nii.gz
%03 11/08/18 works with DTI
%02 11/07/28 add csv name
%01 110712 created

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
%-parameters
vuid = [12 4 3 8 9 19 15 17 7 27 29 16 25 34 36];
ext = '.nii.gz';
%---------------------------%

%---------------------------%
%-copy original data
%----------------%
%-create folders
rdir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod2, cfg.rawd);
ddir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod2, cfg.cond2);
if isdir(rdir); rmdir(rdir, 's'); end
if isdir(ddir); rmdir(ddir, 's'); end
mkdir(rdir);
mkdir(ddir);
%----------------%

%----------------%
%-copy data into orig
vudir = sprintf('/data/recordings/svui/import/svui-mri_2011-10-14_23-48-17/sleep_VU_%02.f/mri/raw/', vuid(subj));
cptype = {'*DTI_64*PAR', '*DTI_64*REC', '*DTI_B0*.PAR', '*DTI_B0*.REC', '*DTI_64*.grad'};

for t = 1:numel(cptype)
  rawdata{t} = dir([vudir cptype{t}]);
  
  %-------%
  %-if zipped
  if numel(rawdata{t}) ~= 1
    rawdata{t} = dir([vudir cptype{t} '.gz']);
  end
  %-------%
  
end

if any(cellfun(@isempty, rawdata))
  error(['check original data'])
end

for t = 1:numel(cptype)
  system(['ln ' vudir rawdata{t}(1).name ' ' rdir]);
end
%----------------%
%---------------------------%

%---------------------------%
%-conver the par/rec
%-------%
%-unzip
gzfile = dir([rdir '*.gz']);
for g = 1:numel(gzfile)
  gunzip([rdir gzfile(g).name])
  delete([rdir gzfile(g).name])
end
%-------%

%-------%
%-then use dcm2nii to convert from PAR/REC into nifti
% in preferences, check that it returns "input filename" and output should
% be compressed fsl
system(['dcm2nii -o ' rdir ' -d N -g N -e Y ' rdir '*.PAR']); % don't zip (I cannot unzip anymore
%-------%
%---------------------------%

%-------------------------------------%
%-rename and move
%---------------------------%
%-dti and b0 correction
alldti = dir([rdir '*DTI*.nii']); % only DTI

for d = 1:numel(alldti)
  
  if strfind(alldti(d).name, 'DTI_64') % 64 dti data
    cond = 'dti';
  elseif strfind(alldti(d).name, '1x1.nii') % magnitude
    cond = 'magn';
  elseif strfind(alldti(d).name, '1x2.nii') % phase
    cond = 'phase';
  else
    warning('data format not recognized')
  end
  
  newname = sprintf('%s%s_%s_%04.f_%s_%s', ...
   ddir, cfg.proj, cfg.rec, subj, cfg.mod2, cond);
  disp(newname)
  
  %-----------------%
  %-unzip, rename, zip
  % gunzip([rdir alldti(d).name])
  system(['mv ' rdir alldti(d).name ' ' newname ext(1:4)]);
  gzip([newname ext(1:4)])
  delete([newname ext(1:4)])
  %-----------------%
  
  if strcmp(cond, 'dti')

    %-----------------%
    %-check whether b0 is the first or the last one
    [~, act] = system(['fslmeants -i ' newname ' -c 57 69 30']);
    act = str2num(act);
    [B0, iB0] = max(act);
    
    %-------%
    %-find second best
    act(iB0) = [];
    [noB0] = max(act);
    %-------%
    
    outtmp = sprintf('B0 is in slice % 2.f: % 4.f (second best: % 4.f)\n', iB0-1, B0, noB0);
    output = [output outtmp];
    %-----------------%
    
    %-----------------%
    %-create bval and bvec
    %---------%
    %-read PAR file
    PAR = read_par([rdir rawdata{1}.name]);
    %---------%
    
    %---------%
    %-get slice indeces
    slidx = [find(diff(PAR.slice_index(:, 43))); size(PAR.slice_index, 1)];
    
    %-following is not true, slidx is correct
%     %now reorder, for some reason the B0 is at the end of PAR but at the
%     %beginning of NIFTI
%     slidx = [slidx(end); slidx(1:end-1)];
    %---------%
    
    %---------%
    %-bval
    bvals = PAR.slice_index(slidx,34);
    bvalfile = [newname '.bval'];
    fbid = fopen(bvalfile, 'w');
    fwrite(fbid, sprintf('%1.f ', bvals));
    fclose(fbid);
    %---------%
    
    %---------%
    %-bvec
    bvecy = PAR.slice_index(slidx, 46);
    bvecz = PAR.slice_index(slidx, 47);
    bvecx = PAR.slice_index(slidx, 48);
    vecname = newname; % we can use it for grad later on
    bvecfile = [newname '_orig.bvec'];
    
    fbid = fopen(bvecfile, 'w');
    fwrite(fbid, sprintf('%1.4f\t', bvecx));
    fwrite(fbid, sprintf('\n'));
    fwrite(fbid, sprintf('%1.4f\t', bvecy));
    fwrite(fbid, sprintf('\n'));
    fwrite(fbid, sprintf('%1.4f\t', bvecz));
    fclose(fbid);
    %---------%
    %-----------------%
  end
end
%---------------------------%

%---------------------------%
%-original grad
allgrad = dir([rdir '*.grad']); % grad info

%-----------------%
%-read grad
fid = fopen([rdir allgrad(1).name], 'r');
gradtxt = textscan(fid, '%f%[:]%f%[,]%f%[,]%f');
fclose(fid);

grad = [gradtxt{3} gradtxt{5} gradtxt{7}]';
grad = grad([3 1 2],:);

dlmwrite([vecname '_orig.grad'], grad, 'delimiter', '\t')
%-----------------%
%---------------------------%

%-----------------%
%-clean up, but keep PAR
delete([rdir '*.nii.gz'])
delete([rdir '*.REC'])
delete([rdir '*DTI_B0*'])
%-----------------%
%-------------------------------------%

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
