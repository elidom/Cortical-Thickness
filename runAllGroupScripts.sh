#!/bin/tcsh

setenv study $argv[1]

tcsh runMrisPreproc.sh $study
tcsh runGLMs.sh $study
tcsh runClustSims.sh $study
