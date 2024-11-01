#!/bin/csh -f

<<<<<<< HEAD
cd /data/usr/xuemy/try_scalar/try_scalar/work/rtl_compile
=======
cd /data/usr/xuemy/8fetch_ooo/dev_ooo/toy_scalar/work/rtl_compile
>>>>>>> 89e66991d0bf01e1b1c749468c20af396b652198

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/tools/software/synopsys/vcs/T-2022.06/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

