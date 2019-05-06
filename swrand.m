function swrand(cfg)
%SWRAND create design and run randomise on slow waves

mversion = 7;
%07 11/10/11 updated wait-part in order to deal with multiple contrasts for one design/datatype
%06 11/08/27 don't count 'seed' files when continuing
%05 11/08/23 delete and recreate rand directory
%04 11/08/23 randomise_parallel
%03 11/08/23 loop over test
%02 11/08/19 created
%01 11/08/15 slow wave traveling and DTI

%---------------------------%
%-start log
output = sprintf('%s (v%02.f) started at %s on %s\n', ...
  mfilename,  mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%---------------------------%
%-DELETE RAND DIRECTORY
if isdir(cfg.rand); rmdir(cfg.rand, 's'); end
mkdir(cfg.rand);
%---------------------------%

%-------------------------------------%
%-loop over designs
nimg = 0;
for d = 1:numel(cfg.swdes.des)
  
  %---------------------------%
  %-dir and files
  desmat = [cfg.desd cfg.swdes.des(d).name '.mat'];
  conmat = [cfg.desd cfg.swdes.des(d).name '.con'];
  %---------------------------%
  
  %---------------------------%
  %-----------------%
  %-compute model
  cdir = pwd;
  cd(cfg.tbss)
  
  %-------%
  %-parameter for randomise
  opt = [];
  opt.d = desmat;
  opt.t = conmat;
  opt.m = [cfg.tbss 'stats/mean_FA_skeleton_mask.nii.gz'];
  %-------%
  
  for i = 1:numel(cfg.preprdti.type)
    if ~strcmp(cfg.preprdti.type{i}(1), 'V') % it cannot handle 3d data
      
      nimg = nimg + numel(cfg.swdes.des(d).fun); % corrp_tstat1, corrp_tstat2, corrp_tstat3 etc
      opt.i = [cfg.tbss 'stats/all_' cfg.preprdti.type{i} '.nii.gz'];
      opt.o = [cfg.rand 'swdti_' cfg.swdes.des(d).name '_' cfg.preprdti.type{i}];
      % system(['randomise -i ' opt.i ' -o "' opt.o '" -d "' opt.d '" -t "' opt.t '" -m ' opt.m ' ' cfg.swrand.opt]);
      system(['randomise_parallel -i ' opt.i ' -o "' opt.o '" -d "' opt.d '" -t "' opt.t '" -m ' opt.m ' ' cfg.swrand.opt]);
      
    end
  end
  
  cd(cdir)
  %-----------------%
  %---------------------------%
  
end

%-----------------%
%-check whether the program has finished
while 1
  pause(15)
  
  %-method 1: check if randomise running
  %it fails bc it takes some time to initialize
  [~, running] = system('ps -u gpiantoni | grep -c randomise');
  fprintf([datestr(now, 'HH:MM:SS') '  ' running])
  
  %-method 2:
  allwr = dir([cfg.rand 'swdti_*_corrp_tstat*.nii.gz']); % <- modify num2str if you move this outside the d-loop
  allseed = numel(find(~cellfun(@isempty, strfind({allwr.name}, 'SEED'))));
  
  if numel(allwr) - allseed == nimg
    break
  end
  
  pause(45)
end
disp('done')
%-----------------%
%-------------------------------------%

%---------------------------%
%-end log
toc_t = toc(tic_t);
outtmp = sprintf('%s (v%02.f) ended at %s on %s after %s\n\n', ...
  mfilename, mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'), ...
  datestr( datenum(0, 0, 0, 0, 0, toc_t), 'HH:MM:SS'));
output = [output outtmp];

%-----------------%
fprintf(output)
fid = fopen([cfg.log '.txt'], 'a');
fwrite(fid, output);
fclose(fid);
%-----------------%
%---------------------------%
