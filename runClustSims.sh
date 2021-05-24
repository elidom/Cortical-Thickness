#!/bin/tcsh
  
setenv study $argv[1]
  
foreach meas (thickness volume)

  foreach hemi (lh rh)
    
    foreach smoothness (20)
      
      foreach dir ({$hemi}.{$meas}.{$study}.{$smoothness}.glmdir)
        
          mri_glmfit-sim \
          --glmdir {$dir} \
          --cache 3.0 pos \
          --cwp 0.05 
            
      end
        
    end
      
  end
    
end
