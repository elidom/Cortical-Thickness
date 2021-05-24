#!/bin/tcsh
  
set study = $argv[1]
  
foreach hemi (lh rh)
  foreach smoothness (20)
    foreach meas (volume thickness)
        mri_glmfit \
        --y {$hemi}.{$meas}.{$study}.{$smoothness}.mgh \
        --fsgd FSGD/{$study}.fsgd \
        --C Contrasts/ta_nt.mtx \
        --C Contrasts/nt_ta.mtx \
        --surf fsaverage {$hemi} \
        --cortex \
        --glmdir {$hemi}.{$meas}.{$study}.{$smoothness}.glmdir
    end
  end
end
