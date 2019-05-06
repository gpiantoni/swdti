function preprdti(cfg, subj)
%PREPRDTI prepare DTI
%
% It's not necessary to rotate the bvec, because the differences are
% extremely small

mversion = 8;
%08 11/11/10 b0 is the last one, not the first!
%07 11/11/03 using fugue, compatible with redoec='no'
%06 11/11/02 don't redo eddycurrent if you only change bvec 
%05 11/10/26 include fugue and clean up
%04 11/10/11 cfg.subj -> subj
%03 11/08/23 fixed bug: with ec, bval and bvec got the wrong name
%02 11/08/19 more straightforward naming
%01 11/08/18 created

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
ddir = sprintf('%s%04.f/%s/%s/', cfg.data, subj, cfg.mod2, cfg.cond2); % data
fadir = sprintf('%s%04.f/%s/%s/fa/', cfg.data, subj, cfg.mod2, cfg.cond2); % FA directory

dfile = sprintf('%s_%s_%04.f_%s_%s', cfg.proj, cfg.rec, subj, cfg.mod2, cfg.cond2); % data
ffile = sprintf('%s_%s_%04.f_%s', cfg.proj, cfg.rec, subj, cfg.mod2); % field (magnitude and phase)
ngfile = sprintf('%s_%s_%04.f_%s_%s_ng', cfg.proj, cfg.rec, subj, cfg.mod2, cfg.cond2); % no gradient
%---------------------------%

%---------------------------%
%-clean up previous analysis
%-----------------%
if strcmp(cfg.preprdti.redoec, 'yes')
  delete([ddir '*brain*'])
  delete([ddir '*ng*'])
  delete([ddir '*_ec*'])
end
delete([ddir '*fugue*'])
delete([ddir 'fieldmap2diff.mat'])

if isdir(fadir); rmdir(fadir, 's'); end
mkdir(fadir)
%-----------------%
%---------------------------%

%---------------------------%
%-prepare DTI data
%-----------------%
%-get names right
origfile = dfile; % to be used for getting gradients and naming FA
if strcmpi(cfg.preprdti.ec, 'yes')
  dfile = sprintf('%s_%s_%04.f_%s_%s_ec', cfg.proj, cfg.rec, subj, cfg.mod2, cfg.cond2); % data
end
%-----------------%

%-----------------%
%-run or skip preparation
if strcmp(cfg.preprdti.redoec, 'yes')
  
  %-------%
  %-get b0 image
  system(['fslroi ' ddir origfile ' ' ddir ngfile ' ' num2str(cfg.preprdti.b0) ' 1']);
  %-------%
  
  %-------%
  %-make mask
  system(['bet ' ddir ngfile ' ' ddir ngfile '_brain -m -f .3']); % change -f, (no -n because of fugue)
  %-------%
  
  
  if strcmpi(cfg.preprdti.ec, 'yes')
    %-------%
    %-eddy current correction
    system(['eddy_correct ' ddir origfile ' ' ddir dfile ' ' num2str(cfg.preprdti.b0)]);
    
    % eddy_correct DTI/data1.nii.gz DTI/data1_corr.nii.gz 0
    %-------%
  end
end
%-----------------%
%---------------------------%

%---------------------------%
%-fugue
if strcmpi(cfg.preprdti.fugue, 'yes')
  
  %-transform into rad/s
  system(['fslmaths ' ddir ffile '_phase -div 100 -mul ' sprintf('%1.15f', pi) '  ' ddir ffile '_phase_pi']);
  
  %-extract brain from magnitude
  system(['bet ' ddir ffile '_magn ' ddir ffile '_magn_brain  -f .3 -m']);
  
  %-only use brain for phase info
  system(['fslmaths ' ddir ffile '_phase_pi -mas ' ddir ffile '_magn_brain_mask ' ddir ffile '_phase_brain']);
  
  %-optional: smooth or improve fieldmap (remember to change names down if you use it)
  % system(['fugue --loadfmap=' ddir ffile '_phase_brain -s 4 --savefmap=' ddir ffile '_phase_brain_s4']);
  
  %-unwrap phase (phase is pretty constant in the center of the brain, it needs unwrapping on temporal lobe and orbitofrontal cortex)
  system(['prelude -p ' ddir ffile '_phase_pi -a ' ddir ffile '_magn_brain -m ' ddir ffile '_magn_brain_mask -o ' ddir ffile '_phase_pi']);
  
  %-apply b0 correction to magn (extremely small differences)
  system(['fugue -v -i ' ddir ffile '_magn_brain --unwarpdir=x- --dwell=0.000700777425 --asym=0.005 --loadfmap=' ddir ffile '_phase_pi -w ' ddir ffile '_magn_brain_warped']);
  
  %-realign magnitude to dti image
  system(['flirt -in ' ddir ffile '_magn_brain_warped -ref ' ddir ngfile '_brain -out ' ddir ffile '_magn_brain_warped_2_ng_brain -omat ' ddir 'fieldmap2diff.mat']);
  
  %-apply realignment to phase
  system(['flirt -in ' ddir ffile '_phase_brain -ref ' ddir ngfile '_brain -applyxfm -init ' ddir 'fieldmap2diff.mat -out ' ddir ffile '_phase_brain_dti']);
  
  %-apply fugue
  % system(['fugue -v -i ' ddir dfile ' --icorr --unwarpdir=y --dwell=0.000700777425 --asym=0.005 --loadfmap=' ddir ffile '_phase_brain_dti -u ' ddir dfile '_fugue']);
  % system(['fugue -v -i ' ddir dfile ' --icorr --unwarpdir=x- --dwell=0.0010818 --loadfmap=' ddir ffile '_phase_brain_dti -u ' ddir dfile '_fugue']);% --saveshift=' ddir dfile 'pixelshift']);
  system(['fugue -v -i ' ddir dfile ' --unwarpdir=x- --dwell=0.000700777425 --asym=0.010 --loadfmap=' ddir ffile '_phase_brain_dti -u ' ddir dfile '_fugue']); 
  
  dfile = [dfile '_fugue'];
  
  %-------%
  %-clean up a little bit
  delete([ddir '*phase_*'])
  delete([ddir '*magn_*'])
  %-------%
  
end
%---------------------------%

%---------------------------%
%-calculate FA
%-------%
%-FA and friends
system(['dtifit -k ' ddir dfile ' -m ' ddir ngfile '_brain_mask ' ...
  '-r ' ddir origfile cfg.bvec ' -b ' ddir origfile '.bval ' ...
  '-o ' fadir origfile]);
%-------%

%-------%
%- create radial diffusivity
system(['fslmaths ' fadir origfile '_L2 -add ' fadir origfile '_L3 -div 2 ' fadir origfile '_RD']);
%-------%
%---------------------------%

%---------------------------%
%-copy DTI data
for i = 1:numel(cfg.preprdti.type)
  if strcmp(cfg.preprdti.type{i}, 'FA')
    system(['ln ' fadir origfile '_' cfg.preprdti.type{i} '.nii.gz ' cfg.tbss]);
  else
    if ~isdir([cfg.tbss cfg.preprdti.type{i}]); mkdir([cfg.tbss cfg.preprdti.type{i}]); end
    system(['ln ' fadir origfile '_' cfg.preprdti.type{i} '.nii.gz ' cfg.tbss cfg.preprdti.type{i} filesep origfile '_FA.nii.gz']); % it has to be called FA
  end
end
%---------------------------%

%---------------------------%
if strcmpi(cfg.clean, 'dti') || strcmpi(cfg.clean, 'all')
  delete([ddir '*brain*'])
  delete([ddir '*ng*'])
  delete([ddir '*ec*'])
  delete([ddir '*fugue*'])
  delete([ddir 'fieldmap2diff.mat'])
end
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
