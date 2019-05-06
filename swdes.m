function swdes(cfg)
%SWDES create design

%TODO: it could be faster if it loads the necessary sw, sp and freq from
%outside the loop (I'm not sure if this is a real bottleneck, max 2min per design )

mversion = 7;
%07 11/11/15 fixed non-functional bug: read sw,sp,freq only if required by the specific design
%06 11/11/13 added despnt, the points to use for the correlation, used by swreport
%05 11/11/13 allows for sw and sp for different stages, and freq only one stage at the time
%04 11/11/01 add extra column of ones
%03 11/10/26 only load sp, sw or freq if used
%02 11/10/25 measures frequency bands as well
%01 11/10/06 created

%---------------------------%
%-start log
output = sprintf('%s (v%02.f) started at %s on %s\n', ...
  mfilename,  mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%-------------------------------------%
%-loop over designs
for d = 1:numel(cfg.swdes.des)
  
  %---------------------------%
  %-dir and files
  desfile = [cfg.desd cfg.swdes.des(d).name];
  %---------------------------%
  
  %---------------------------%
  %-design and contrast
  %-----------------%
  %-design matrix
  des = zeros(numel(cfg.subjall), numel(cfg.swdes.des(d).fun));
  
  %-------%
  %-read slow wave detected
  %FSL automatically concatenates data from all the subjects
  %for EEG, we are doing it here, cfg.subjall(s)
  for s = 1:numel(cfg.subjall)
    
    for f = 1:numel(cfg.swdes.des(d).fun)
      
      if strfind(cfg.swdes.des(d).fun{f}, 'sw')
        swall = [];
        for st = cfg.swdes.des(d).stage{f}
          SWfile = sprintf('%sdetSW_%1.f_%03.f', cfg.detd, st, cfg.subjall(s));
          load(SWfile, 'sw')
          swall = [swall sw];
        end
        sw = swall;
      end
      
      if strfind(cfg.swdes.des(d).fun{f}, 'sp')
        spall = [];
        for st = cfg.swdes.des(d).stage{f}
          SPfile = sprintf('%sdetSP_%1.f_%03.f', cfg.detd, st, cfg.subjall(s));
          load(SPfile, 'sp')
          spall = [spall sp];
        end
        sp = spall;
      end
      
      if strfind(cfg.swdes.des(d).fun{f}, 'freq')
        if numel(cfg.swdes.des(d).stage{f}) ~= 1
          error('you cannot average the frequency power over stages (it could be done, not here)')
        end
        
        freqfile = sprintf('%sfreq_%1.f_%03.f', cfg.detd, st, cfg.subjall(s));
        load(freqfile)
      end
      
      
      des(s, f) = eval(cfg.swdes.des(d).fun{f});
    end
  end
  %-------%
  
  %-------%
  %-save single points
  for f = 1:numel(cfg.swdes.des(d).fun)
    despnt = des(:, f);
    save([desfile '_' num2str(f)], 'despnt')
  end
  %-------%
  
  %-------%
  %-deman
  if strcmp(cfg.swdes.des(d).mean, 'y')
    des = des - repmat(mean(des), numel(cfg.subjall), 1);
  end
  %-------%
  
  %-------%
  %-ones
  descon = des; % we use this later to describe the contrasts
  if strcmp(cfg.swdes.des(d).ones, 'y')
    des = [ones(size(des,1),1) des];
  end
  %-------%
  
  %-------%
  if strcmp(cfg.swdes.des(d).orth, 'y')
    des = spm_orth(des);
  end
  %-------%
  
  %-------%
  %-write mat
  fid = fopen([desfile '.mat'], 'w');
  fwrite(fid, sprintf('/NumWaves\t%1.f\n', size(des,2)));
  fwrite(fid, sprintf('/NumPoints\t%1.f\n', size(des,1)));
  
  fwrite(fid, sprintf('/PPheights\t'));
  for c = 1:size(des,2)
    fwrite(fid, sprintf('\t%1.5f', range(des(:,c))));
  end
  fwrite(fid, sprintf('\n\n'));
  
  fwrite(fid, sprintf('/Matrix\n'));
  for s = 1:size(des,1)
    fwrite(fid, sprintf('%1.5f ', des(s,:)));
    fwrite(fid, sprintf('\n'));
  end
  
  fclose(fid);
  %-------%
  %-----------------%
  
  %-----------------%
  %-contrast
  %-------%
  %-write con
  fid = fopen([desfile '.con'], 'w');
  for c = 1:size(descon,2)
    fwrite(fid, sprintf('/ContrastName%1.f\t"con%1.f"\n', c, c));
  end
  
  fwrite(fid, sprintf('/NumWaves\t%1.f\n', size(des,2)));
  fwrite(fid, sprintf('/NumContrasts\t%1.f\n', size(descon,2)));
  
  fwrite(fid, sprintf('/PPheights\t'));
  for c = 1:size(descon,2)
    fwrite(fid, sprintf('\t%1.5f', range(descon(:,c))));
  end
  fwrite(fid, sprintf('\n'));
  
  printones = sprintf('%1.f ', ones(size(descon,2),1));
  fwrite(fid, sprintf('/RequiredEffect\t\t%s\n\n', printones));
  
  fwrite(fid, sprintf('/Matrix\n'));
  
  coneye = eye(size(descon,2));
  for c = 1:size(descon,2)
    
    if strcmp(cfg.swdes.des(d).ones, 'y')
      printcon = ['0 ' sprintf('%1.f ', coneye(c,:))];
    else
      printcon = sprintf('%1.f ', coneye(c,:));
    end
    
    fwrite(fid, sprintf('%s\n', printcon));
  end
  fclose(fid);
  %-------%
  %-----------------%
  %---------------------------%
end
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