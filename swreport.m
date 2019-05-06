function [minall] = swreport(cfg)
%SWREPORT read output of swrand and make it in text
% this function has an output, which can be used by sw2csv to get the
% lowest p-value

mversion = 13;
%13 12/02/27 report R value as well
%12 12/02/23 report both
%11 12/01/16 report mean and sd instead of single points
%10 11/11/13 report single points for each design/function
%09 11/11/09 use ft_read_mri instead of external toolbox
%08 11/11/03 use atlasquery for interesting areas
%07 11/10/26 only load sp, sw or freq if used
%06 11/10/25 use cluster to report significant clusters
%05 11/10/20 correlation between rall and detd might become useful if I understand how FSL calculates correlations
%04 11/10/17 added mnival, it'll be used in sw2csv
%03 11/10/17 write down n of detected slow waves and spindles
%02 11/10/10 it works with multiple contrasts
%01 11/08/23 created

%---------------------------%
%-start log
output = sprintf('%s (v%02.f) started at %s on %s\n', ...
  mfilename,  mversion, datestr(now, 'HH:MM:SS'), datestr(now, 'dd-mmm-yy'));
tic_t = tic;
%---------------------------%

%-------------------------------------%
%-loop over designs
for d = 1:numel(cfg.swdes.des)
  output = sprintf('%s\n#---------------------------#\n%s\n', output, cfg.swdes.des(d).name);
  
  %-------------------------------%
  %-loop over contrasts
  for f = 1:numel(cfg.swdes.des(d).fun)
    output = sprintf('%s#----------------------#\n%s\n', output, cfg.swdes.des(d).fun{f});
    
    %-----------------%
    %-save single points
    load([cfg.desd cfg.swdes.des(d).name '_' num2str(f)], 'despnt')
    sparam = sprintf('\t% 5.2f', despnt);
    outval = sprintf(' mean % 5.2f s.d. % 5.2f\n%s\n\n', mean(despnt), std(despnt), sparam);
    output = sprintf('%s%s\n', output, outval');
    %-----------------%
    
    %---------------------------%
    %-loop over types
    for i = 1:numel(cfg.preprdti.type)
      if ~strcmp(cfg.preprdti.type{i}(1), 'V')
        
        output = sprintf('%s#-----------------#\n%s\n', output, cfg.preprdti.type{i});
        
        %-------------------%
        %-loop over tests
        for t = 1:numel(cfg.swreport.test)
          output = sprintf('%s#-------#\nIMG:%s FUN:%s\n', output, cfg.swreport.test(t).img, func2str(cfg.swreport.test(t).fun));
          
          %---------%
          %-read image
          rimg = [cfg.rand 'swdti_' cfg.swdes.des(d).name '_' cfg.preprdti.type{i} cfg.swreport.test(t).img num2str(f) '.nii.gz'];
          rall = [cfg.tbss 'stats/all_' cfg.preprdti.type{i} '.nii.gz'];
          %---------%
          
          %---------%
          %-find in img
          [found minval] = find_in_img(cfg.swreport.test(t).fun, rimg); %, rall, alldet{f+bf});
          output = [output found];
          %---------%
          
          %---------%
          %-keep the min p-value
          if t == cfg.test2write
            minall{d}{f}{i} = minval;
          end
          %---------%
          
          output = sprintf('%s#-------#\n', output);
          
        end
        %-------------------%
        
        output = sprintf('%s#-----------------#\n', output);
      end
    end
    %---------------------------%
    
    output = sprintf('%s#----------------------#\n', output);
  end
  %-------------------------------%
  
  %-------------------%
  %-write output
  output = sprintf('%s#---------------------------#\n', output);
  %-------------------%
  
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

function [found minval] = find_in_img(fun, rimg) %, rall, detd)
%where fun is based on max with two outputs:
% fun = @max
% fun = @(x)deal(1-x, find(x > .95)) -> get significant voxels and transform their value in normal p-values (from FSL p-values)

%-------%
%-from tstat to R
t2r = @(t, n) sqrt((t^2)/(t^2 + (n-2)));
n = 14; % number of subjects...
%-------%

%-------%
%-read image
img  = ft_read_mri(rimg);
tstat = NaN;
if strfind(rimg, '_tfce_corrp_')
  timg  = ft_read_mri(strrep(rimg, '_tfce_corrp_', '_'));
  tstat = 1;
end
%-------%

%-------%
%-calculate
[v i] = feval(fun, img.anatomy(:));
[x, y, z] = ind2sub(size(img.anatomy), i);
[xyz] = [x, y, z] - 1; % -1 is the convention used by FSL, not sure if it's standard
mni = [xyz ones(size(xyz,1),1)] * img.transform';
%-------%

%-----------------%
%-print
found = sprintf('%s\n\n', func2str(fun));

if size(mni,1) == 0
  found = [found sprintf('no voxel below the threshold\n')];
  minval = NaN;
  
else
  [minval imin] = min(v(i));
  if ~isnan(tstat)
    tstat = t2r(timg.anatomy(imin), n)^2;
  end
  
  found = [found sprintf('%1.f voxels below the threshold, with min at %1.3f (r^2:%1.3f)\n', size(mni,1), min(v(i)), tstat)];
  
  [~, outtmp] = system(['cluster -i ' rimg ' -t .95 --mm']);
  if size(outtmp,2) > 112
    found = sprintf('%s%s\n', found, outtmp);
    
    %-------%
    %-write which brain areas are involved
    imgpath = fileparts(rimg);
    imgthr = [imgpath '/img_thr.nii.gz'];
    unix(['fslmaths ' rimg ' -thr .95 ' imgthr ]);
    [~, areas] = unix(['atlasquery -a "JHU White-Matter Tractography Atlas" -m ' imgthr]);
    delete(imgthr)
    found = sprintf('%s%s\n', found, areas);
    %-------%
    
  end
end
%-----------------%
