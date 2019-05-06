function cpsleep(cfg, subj)
%CPSLEEP copy sleep data

mversion = 5;
%05 11/11/12 don't use SPM at all
%04 11/09/28 correct scores here
%03 11/09/28 cfg.subj -> subj
%02 11/08/19 data name includes recording name
%01 11/08/17 created

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
rdir = sprintf('%s%04.f/%s/%s/', cfg.recs, subj, cfg.mod1, cfg.rawd); % recording 
ddir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod1, cfg.cond1); % data
if isdir(ddir); rmdir(ddir, 's'); end
mkdir(ddir)

rfile = sprintf('%s_%04.f_%s_%s%s', cfg.rec, subj, cfg.mod1, cfg.cond1, cfg.cond1plus); % recording
dfile = sprintf('%s_%s_%04.f_%s_%s', cfg.proj, cfg.rec, subj, cfg.mod1, cfg.cond1); % data
%---------------------------%

%---------------------------%
%-get data (these are symbolic links)
%-----------------%
system(['cp ' rdir rfile '.mat ' ddir dfile '.mat']);
system(['chmod u+w ' ddir dfile '.mat']);
system(['ln ' rdir rfile '.dat ' ddir dfile '.dat']);
%-----------------%

%-----------------%
%-rename files (to avoid inconsistency)
load([ddir dfile], 'D');
D.fname = [dfile '.mat'];
D.data.fnamedat = [dfile '.dat'];
D.data.y.fname = [ddir dfile '.dat'];
%-----------------%

%-----------------%
%-merge scores if necessary
if size(D.other.CRC.score,2) == 3
  fprintf('scores are already merged, with name: %s\n', D.other.CRC.score{2,3});
elseif size(D.other.CRC.score,2) == 1
  D.other.CRC.score(:,3) = D.other.CRC.score(:,1);
  fprintf('copying scores from %s\n', D.other.CRC.score{2,1});
else
  %-------%
  %-merge them
  D.other.CRC.score(:,3) = D.other.CRC.score(:,1);
  D.other.CRC.score{2,3} = 'Automatic merge';
  
  SWand = and(D.other.CRC.score{1,1} == 3 | D.other.CRC.score{1,1} == 4, D.other.CRC.score{1,2} == 3 | D.other.CRC.score{1,2} == 4); % both agreed it's SW
  SWxor = xor(D.other.CRC.score{1,1} == 3 | D.other.CRC.score{1,1} == 4, D.other.CRC.score{1,2} == 3 | D.other.CRC.score{1,2} == 4); % disagreement
  D.other.CRC.score{1,3}(SWand) = 4; % agreement = 4
  D.other.CRC.score{1,3}(SWxor) = 2; % disagreement = 2
  %-------%
  fprintf('Automatic computation of merged scores\n');
end
%-----------------%

%-----------------%
save([ddir dfile], 'D');
%-----------------%
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