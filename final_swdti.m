function final_swdti(cfgin)

% 12/08/21 rerun using qsub in fieldtrip
% 11/12/20 two thresholds for spindles
% 11/11/12 allows input cfgin, and use catstruct
% 11/11/10 remove cpmri
% 11/11/10 added cpdti in the script
% 11/11/02 tested with different grad/bvec (grad is best, but small differences)
% 11/10/25 only load sw, sp, freq if used
% 11/10/19 don't create cfg.log
% 11/10/17 using qsub to avoid memory leaks
% 11/10/17 allows argout for swreport
% 11/10/17 always specify detection options for sw2csv
% 11/10/06 detects spindles as well
% 11/10/06 pass strings instead of handles
% 11/08/17 created

%-------------------------------------%
%-PATH--------------------------------%
%-------------------------------------%

%---------------------------%
%-path
if ~exist('ft_defaults')
  addpath /data1/toolbox/fieldtrip/
  ft_defaults
  addpath /usr/local/matlab2011b/toolbox/stats/stats % range
  addpath /data1/toolbox/fieldtrip/qsub/
end
%---------------------------%

%---------------------------%
%-paths in cfg
cfg = [];

cfg.proj = 'gosd';
cfg.rec  = 'svui';
cfg.rawd = 'raw'; % name of the raw directory inside recordings

cfg.mod1 = 'eeg';
% cfg.cond1 = 'sleep';
% cfg.cond1plus = '_scores_fasttb';

cfg.cond1 = 'scores';
cfg.cond1plus = '_sleep_fasttb';

cfg.mod2 = 'smri';
cfg.cond2 = 'dti';

cfg.mod3 = 'smri';
cfg.cond3 = 't1';

%-------%
%-find the raw data
% define the directory with the data.
% cfg.rcnd is the recording condition, this will be used to find the files
% within cfg.recd
cfg.base = ['/data1/projects/' cfg.proj filesep];
cfg.recd = [cfg.base 'recordings/' cfg.rec filesep];
cfg.recs = [cfg.recd 'subjects/'];
%-------%

cfg.scrp = [cfg.base 'scripts/'];
cfg.data = [cfg.base 'subjects/'];
cfg.anly = [cfg.base 'analysis/swdti/']; % cfg.anly = [cfg.base 'analysis/slowwaves/'];
cfg.smri = [cfg.base 'analysis/smri/'];
cfg.imgd = [cfg.anly 'images/'];
cfg.rslt = [cfg.base 'results/'];

cfg.detd = [cfg.anly 'detected/'];
if ~isdir(cfg.detd); mkdir(cfg.detd); end

cfg.tbss = [cfg.anly 'tbss/'];
if ~isdir(cfg.tbss); mkdir(cfg.tbss); end
cfg.desd = [cfg.tbss 'design/'];
if ~isdir(cfg.desd); mkdir(cfg.desd); end
cfg.rand = [cfg.tbss 'rand/'];

cfg.csvf = [cfg.anly 'swdti.csv'];
%-----------------%

%-----------------%
addpath([cfg.scrp 'swdti/'])
cfg.qlog = [cfg.scrp 'swdti/qsublog/'];
%-----------------%
%-------------------------------------%

%-------------------------------------%
%-CFG---------------------------------%
%-------------------------------------%

%---------------------------%
%-general
cfg.subjall = [1:4 6:15]; 
cfg.run = [1:3 5:9]; % control which steps it should run

cfg.clean = '';  % 'eeg' or 'dti' or 'all'
st = 0;
stepsubj = 1:5;
stepgrp  = 6:9;
%---------------------------%

%---------------------------%
%-SLEEP EEG
%-----------------%
%-cfg 01: copy sleep data
st = st + 1;
cfg.step{st} = 'cpsleep';
%-----------------%

%-----------------%
%-cfg 02: detect slow waves
st = st + 1;
cfg.step{st} = 'detsw';
cfg.stage = [2 4];
cfg.pad = 1; % this is necessary to allow overlap between epochs
cfg.reject = 'partial'; % 'complete' or 'partial' or 'no'
cfg.reref.reref = 'yes';
cfg.reref.refchannel = {'E94' 'E190'}; % 'all';
cfg.reref.implicit = 'E257';
cfg.reref.feedback = 'none';
cfg.reref.derivative = 'no';

cfg.badchan.auto(1).met  = 'var'; % method to automatically find bad channels
cfg.badchan.auto(1).fun  = '@(allchan) find(allchan > 10000)';
cfg.badchan.auto(2).met  = 'range'; % method to automatically find bad channels
cfg.badchan.auto(2).fun  = '@(allchan) find(allchan > 3000)';
cfg.badchan.auto(3).met  = 'diff'; % method to automatically find bad channels
cfg.badchan.auto(3).fun  = '@(allchan) find(allchan > 1000)';
cfg.elecfile = '/data1/toolbox/elecloc/EGI_GSN-HydroCel-256_new_cnfg'; % contains layout, nbor, elec

cfg.detsw.feedback = 'yes'; % 'yes' or 'no':
cfg.detsw.sw.roi(1).name = 'anterior';
cfg.detsw.sw.roi(1).chan = {'E10','E11','E12','E13','E14','E15','E16','E17','E18','E186','E19','E198','E2','E20','E207','E21','E214','E215','E22','E223','E224','E23','E24','E25','E257','E26','E27','E28','E29','E3','E30','E31','E32','E33','E34','E35','E36','E37','E38','E39','E4','E40','E41','E46','E47','E5','E6','E7','E8','E9'};
cfg.detsw.sw.roi(2).name = 'left';
cfg.detsw.sw.roi(2).chan = {'E105','E106','E42','E43','E44','E45','E48','E49','E50','E51','E52','E53','E54','E55','E56','E57','E58','E59','E60','E61','E62','E63','E64','E65','E66','E68','E69','E70','E71','E72','E74','E75','E76','E77','E78','E79','E80','E83','E84','E85','E86','E87','E88','E94','E95','E96','E97'};
cfg.detsw.sw.roi(3).name = 'right';
cfg.detsw.sw.roi(3).chan = {'E1','E131','E132','E142','E143','E144','E153','E154','E155','E161','E162','E163','E164','E169','E170','E171','E172','E173','E177','E178','E179','E180','E181','E182','E183','E184','E185','E190','E191','E192','E193','E194','E195','E196','E197','E202','E203','E204','E205','E206','E210','E211','E212','E213','E220','E221','E222'};
cfg.detsw.sw.roi(4).name = 'posterior';
cfg.detsw.sw.roi(4).chan = {'E100','E101','E107','E108','E109','E110','E114','E115','E116','E117','E118','E119','E122','E123','E124','E125','E126','E127','E128','E129','E130','E135','E136','E137','E138','E139','E140','E141','E147','E148','E149','E150','E151','E152','E157','E158','E159','E160','E167','E168','E81','E89','E90','E98','E99'};

cfg.detsw.sw.filter = [.2 4];
cfg.detsw.sw.negthr = -60;
cfg.detsw.sw.zcr = [.2 1];
cfg.detsw.sw.p2p = 75;
cfg.detsw.sw.postzcr = 1;
cfg.detsw.sw.trvlnegthr = -30; % only for traveling
cfg.detsw.sw.feedback = 'none';

cfg.detsw.sp.filter = [11 16];
cfg.detsw.sp.thr = 3;
cfg.detsw.sp.dur = [.5 2];
% cfg.detsw.sp.thrB = 3;
cfg.detsw.sp.feedback = 'none';

cfg.freqsw.length = 2;
cfg.freqsw.foilim = [0 18]; % freq res depends on length
% cfg.freqsw.roi(1) = cfg.detsw.sw.roi(1); % anterior
cfg.freqsw.roi(1) = cfg.detsw.sw.roi(1); % posterior
%-----------------%
%---------------------------%

%---------------------------%
%-DTI
%-----------------%
%-cfg 03: copy DTI data
st = st + 1;
cfg.step{st} = 'cpdti';
%-----------------%

%-----------------%
%-cfg 04: fix bvec: wait until I understand the code of the function
st = st + 1;
cfg.step{st} = 'fixbvec';
%-----------------%

%-----------------%
%-cfg 05: preproc DTI
st = st + 1;
cfg.step{st} = 'preprdti';
cfg.preprdti.b0 = 64; % index of the B0 scan (no gradient applied), following FSL convention
cfg.preprdti.ec = 'yes';
cfg.preprdti.redoec = 'no'; % use previous ec, but for example test new gradients
cfg.preprdti.fugue = 'no';
cfg.bvec = '.bvec'; % '.bvec' (from PAR) or '.grad' (from raw folder)
cfg.preprdti.type = {'FA' 'L1'}; % FA is obligatory
%-----------------%
%---------------------------%

%---------------------------%
%-GROUP STATS
%-----------------%
%-cfg 06: swtbss
st = st + 1;
cfg.step{st} = 'swtbss';
cfg.swtbss.thr = 0.2;
%-----------------%

%-----------------%
%-cfg 07: swdes
st = st + 1;
cfg.step{st} = 'swdes';
d = 0;

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'numel(sw)/numel(unique([sw.trl]))';
cfg.swdes.des(d).stage{1} = [2];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'mean([sw.negpeak_val])';
cfg.swdes.des(d).stage{1} = [2];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = '-mean([sw.negpeak_val]./([sw.zcr_time]-[sw.negpeak_time]))';
cfg.swdes.des(d).stage{1} = [2];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'numel(sw)/numel(unique([sw.trl]))';
cfg.swdes.des(d).stage{1} = [4];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'mean([sw.negpeak_val])';
cfg.swdes.des(d).stage{1} = [4];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = '-mean([sw.negpeak_val]./([sw.zcr_time]-[sw.negpeak_time]))';
cfg.swdes.des(d).stage{1} = [4];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'numel(sp)/numel(unique([sp.trl]))';
cfg.swdes.des(d).stage{1} = [2];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'mean([sp.energytot])';
cfg.swdes.des(d).stage{1} = [2];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'numel(sp)/numel(unique([sp.trl]))';
cfg.swdes.des(d).stage{1} = [4];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%

%-------%
d = d+1;
cfg.swdes.des(d).fun{1} = 'mean([sp.energytot])';
cfg.swdes.des(d).stage{1} = [4];
cfg.swdes.des(d).mean = 'y'; % demean design
cfg.swdes.des(d).ones = 'y'; % add ones in first column
cfg.swdes.des(d).orth = 'y';
%-------%
%-----------------%

%-----------------%
%-cfg 08: swrand
% ATTENTION: it deletes and recreates the cfg.rand folder!
% COPY GOOD RESULTS SOMEWHERE ELSE
st = st + 1;
cfg.step{st} = 'swrand';
% FWE:
% -x   -> single voxel correction: _vox_p_tstat  | _vox_corrp_tstat
% --T2 -> TFCE correction:         _tfce_p_tstat | _tfce_corrp_tstat
% -c N -> cluster-size correction:               | _clustere_corrp_tstat
% -C N -> cluster-mass correction:               | _clusterm_corrp_tstat
cfg.swrand.clus = '';
cfg.swrand.demean = '-D'; % '-D' or ''
cfg.swrand.opt = ['--T2 ' cfg.swrand.clus ' -n 600 ' cfg.swrand.demean]; % 1800 = 120*15
%-----------------%

%-----------------%
%-cfg 9: swreport
st = st + 1;
cfg.step{st} = 'swreport';

%-------%
cfg.swreport.test(1).fun = @(x)deal(1-x, find(x >= 0));
% cfg.swreport.test(2).img = cfg.swreport.test(1).img;
% cfg.swreport.test(2).fun = @(x)deal(1-x, find(x >= .5));
%-------%
%-----------------%
%---------------------------%

%---------------------------%
%-fix CFG
%-------%
%-use extra info from cfgin
if nargin == 1
  cfg = catstruct(cfg, cfgin);
end
%-------%

%-------%
%-prepare name for files, by fixing weird signs for filenames
for d = 1:numel(cfg.swdes.des)
  if strcmp(cfg.swdes.des(d).orth, 'y') && strcmp(cfg.swdes.des(d).ones, 'y'); cfg.swdes.des(d).mean = 'y'; end % orthogonalizing w.r.t. to a column of ones is identical to demeaning
  stagestr = sprintf('%1.f', cfg.swdes.des(d).stage{1});
  cfg.swdes.des(d).name = [cfg.swdes.des(d).fun{:} '_s' stagestr '_'...
    cfg.swdes.des(d).mean '_' cfg.swdes.des(d).ones '_' cfg.swdes.des(d).orth];
  cfg.swdes.des(d).name = regexprep(cfg.swdes.des(d).name, {'@' '==' '>=' '<=' '>' '<' '(' ')' '[' ']' '/' ',' '\.' ':'}, {'AT' 'EQ' 'GE' 'LE' 'GT' 'LT' '-I' 'I-' '' '' 'DIV' '_' 'DOT' 'TO'}); % clean-up bad char for filenames
end
%-------%

%-------%
%-only compute the necessary paramters
cfg.rundet = {};
detfeat = {'freq', 'sw', 'sp'};
for i = 1:numel(detfeat)
  if strfind([cfg.swdes.des.name], detfeat{i})
    cfg.rundet = [cfg.rundet detfeat(i)];
  end
end
%-------%

%-------%
switch cfg.swrand.opt(2)
  case '-' %- --T2
    cfg.swreport.test(1).img = '_tfce_corrp_tstat';
  case 'x'
    cfg.swreport.test(1).img = '_vox_corrp_tstat';
  case 'c'
    cfg.swreport.test(1).img = '_clustere_corrp_tstat';
  case 'C'
    cfg.swreport.test(1).img = '_clusterm_corrp_tstat';
end
%-------%
%---------------------------%
%-------------------------------------%

%-------------------------------------%
%-LOG---------------------------------%
%-------------------------------------%
%-----------------%
%-Log file
logdir = [cfg.anly 'log/'];
if ~isdir(logdir); mkdir(logdir); end

cfg.log = sprintf('%slog_%s_%s_%s', ...
  logdir, cfg.proj, datestr(now, 'yy-mm-dd'), datestr(now, 'HH-MM-SS'));
% if ~isdir(cfg.log); mkdir(cfg.log); end % logdir for images

fid = fopen([cfg.log '.txt'], 'w');

output = sprintf('Analysis started at %s on %s\n', ...
  datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
fprintf(output)
fwrite(fid, output);
%-----------------%

%-----------------%
%-cfg in log
output = struct2log(cfg);

fprintf(output)
fwrite(fid, output);
fclose(fid);
%-----------------%
%-------------------------------------%

%-------------------------------------%
%-SINGLE-SUBJECT ANALYSIS-------------%
%-------------------------------------%
%-----------------%
%-for parallel processing
subjcell = num2cell(cfg.subjall);
cfgcell = repmat({cfg}, 1, numel(cfg.subjall));
%-----------------%

for r = intersect(cfg.run, stepsubj)
  
  if r == 2
    
    %-----------------%
    %-qsub
    cd(cfg.qlog)
    qsubcellfun(cfg.step{r}, cfgcell, subjcell, 'memreq', 10*1024^3, 'timreq', 48*60*60)
    cd([cfg.scrp 'swdti/'])
    %-----------------%
    
  else
    
    for s = cfg.subjall
      feval(cfg.step{r}, cfg, s)
    end
    
  end
end
%-------------------------------------%

%-------------------------------------%
%-GROUP ANALYSIS----------------------%
%-------------------------------------%
for r = intersect(cfg.run, stepgrp)
  
  if nargout(cfg.step{r})
    cfg.minval = feval(cfg.step{r}, cfg);
  else
    feval(cfg.step{r}, cfg)
  end
  
end
%-------------------------------------%
 
