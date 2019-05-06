function swtbss(cfg)
%SWTBSS tbss on slow wave data

mversion = 2;
%02 11/08/23 check msf files if not empty for tbss2
%01 11/08/19 created

%---------------------------%
%-start log
output = sprintf('%s (v%02.f) started at %s on %s\n', ...
  mfilename,  mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
fprintf(output)
if isfield(cfg, 'fid') && ~isempty(fopen(cfg.fid)); fwrite(cfg.fid, output); end

tic_t = tic;
%---------------------------%

%---------------------------%
%-dir and files
fafile = sprintf('%s_%s_*_%s_%s_FA.nii.gz', cfg.proj, cfg.rec, cfg.mod2, cfg.cond2); % fa images
wrfile = sprintf('%s_%s_*_%s_%s_FA_FA_to_target_warp.msf', cfg.proj, cfg.rec, cfg.mod2, cfg.cond2); % wrap file (it's empty till tbss2 has finished)
allfa = dir([cfg.tbss fafile]);
%---------------------------%

%---------------------------%
%-tbss
cdir = pwd;
cd(cfg.tbss)

%-------%
%-TBSS preproc
system(['tbss_1_preproc ' sprintf('%s ', allfa(:).name) ]);
% copy images from slicedir?
%-------%

%-------%
%-TBSS registation
system('tbss_2_reg -T');

while 1
  pause(5)
  
  %-method 1: check if flirt and fnirt are running
  %it fails bc it takes some time to initialize
  [~, running] = system('ps -u gpiantoni | grep -c f*irt');
  fprintf(running)
  
  %-method 2: tbss2 creates some empty files and it puts something in it at
  %the end of the computation
  allwr = dir([cfg.tbss 'FA/' wrfile]);
  if numel(allwr) > 0 && all([allwr.bytes] ~= 0)
    break
  end
  
  pause(5)
end
disp('done')
%-------%

%-------%
%-TBSS postreg
system('tbss_3_postreg -S');
%-------%

%-------%
%-TBSS prestats
system(['tbss_4_prestats ' num2str(cfg.swtbss.thr)]);
%-------%

%-------%
%-TBSS: other measures
for i = 1:numel(cfg.preprdti.type)
  if ~strcmp(cfg.preprdti.type{i}, 'FA')
    disp(['computing ' cfg.preprdti.type{i} ])
    system(['tbss_non_FA ' cfg.preprdti.type{i}]);
  end
end
%-------%
cd(cdir)
%---------------------------%

%---------------------------%
%-clean up
if strcmpi(cfg.clean, 'dti') || strcmpi(cfg.clean, 'all')
  rmdir([cfg.tbss 'origdata'], 's')
  for i = 1:numel(cfg.preprdti.type)
    rmdir([cfg.tbss cfg.preprdti.type{i}], 's')
  end
end
%---------------------------%

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