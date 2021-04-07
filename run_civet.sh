#!/bin/bash

topdir=/misc/charcot2/dominguezma/tutorial/civet

source /misc/charcot/santosg/CIVET/civet_2_1_1/Linux-x86_64/init.sh

ls mnc_vols/*t1.mnc | cut -d "_" -f 3 | cut -d "_" -f 2 | parallel --jobs 3 /misc/charcot2/santosg/civet-2.1.1-binaries-ubuntu-18/Linux-x86_64/CIVET-2.1.1/CIVET_Processing_Pipeline -sourcedir $topdir/mnc_vols -targetdir $topdir/target -prefix TA -N3-distance 0 -lsq12 -mean-curvature -mask-hippocampus -resample-surfaces -correct-pve -interp sinc -template 0.50 -thickness tlink 10:30 -area-fwhm 0:40 -volume-fwhm 0:40 -VBM -surface-atlas AAL -granular -run {}
