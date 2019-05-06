function fixbvec(cfg, subj)
%FIXBVEC modify bvec for philips scanner
% run renaming_convention_dti first, which takes the PAR/REC data

mversion = 8;
%08 11/11/10
%07 11/10/12 renamed: cpdti -> fixbvec
%06 11/10/12 can use bvec (from PAR) or grad (from RAW folder)
%05 11/10/11 reads dti within project folder, not from recordings
%04 11/10/11 cfg.subj -> subj
%03 11/08/23 DTI_gradient_table_creator_Philips_RelX
%02 11/08/18 very similar to cpsleep
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
fprintf(output)
if isfield(cfg, 'fid') && ~isempty(fopen(cfg.fid)); fwrite(cfg.fid, output); end

tic_t = tic;
%---------------------------%

%---------------------------%
%-dir and files (within projects)
addpath /data/toolbox/DTI_gradient_table_creator_Philips_RelX

rdir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod2, cfg.rawd);
ddir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod2, cfg.cond2);
rfile = sprintf('%s_%s_%04.f_%s_%s', cfg.proj, cfg.rec, subj, cfg.mod2, cfg.cond2);

%-------%
%-find PAR
PARall = dir([rdir '*.PAR']);
if numel(PARall) ~= 1
  error(['could not find the correct PAR in ' rdir])
end
%-------%
%---------------------------%

%---------------------------%
%-loop through bvec and grad
btype = {'.grad' '.bvec'};
for i = 1:numel(btype)
  
  %-------%
  %-take bvec, transpose and remove b0
  bfile = [ddir rfile btype{i}]; % bfile with correct bvec
  bvec = dlmread([ddir rfile '_orig' btype{i}]); % original data
  bvec = bvec';
  bvec(cfg.preprdti.b0 + 1, :) = []; % CAREFUL: matlab vs fsl convention
  dlmwrite(bfile, bvec);
  %-------%
  
  %-------%
  %-run DTI_gradient_table_creator_Philips_RelX
  A = [];
  A.par_file = [rdir PARall(1).name];
  A.didREG = 'n';
  A.writeGRAD = 'n';
  A.grad_choice = 'user-defined';
  A.release = 'Rel_2.1';
  A.fat_shift = 'A'; % it does not change results
  A.supplied_grad_file = bfile;
  A.sort_images = 'y';
  bvec = DTI_gradient_table_creator_Philips_RelX(A);
  %-------%
  
  %-------%
  %-write
  delete(bfile)
  dlmwrite(bfile, bvec', 'delimiter', '\t');
  %-------%
  
end
%---------------------------%

%---------------------------%
%-end log
toc_t = toc(tic_t);
output = sprintf('(p%02.f) %s (v%02.f) ended at %s on %s after %s\n\n', ...
  subj, mfilename, mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
  datestr( datenum(0, 0, 0, 0, 0, toc_t), 'HH:MM:SS'));
fprintf(output)
if isfield(cfg, 'fid') && ~isempty(fopen(cfg.fid)); fwrite(cfg.fid, output); end
%---------------------------%