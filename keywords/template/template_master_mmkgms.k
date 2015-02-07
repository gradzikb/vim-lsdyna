$-------------------------------------BOF---------------------------------------
$
*KEYWORD 99999999
$
$-------------------------------------------------------------------------------
$    TITLE
$-------------------------------------------------------------------------------
$
*TITLE
?title?
$
$-------------------------------------------------------------------------------
$    TIME TERMINATION
$-------------------------------------------------------------------------------
$
*CONTROL_TERMINATION
$#  endtim    endcyc     dtmin    endeng    endmas     nosol
         ?
$
$-------------------------------------------------------------------------------
$    MASS SCALING
$-------------------------------------------------------------------------------
$
*CONTROL_TIMESTEP
$#  dtinit    tssfac      isdo    tslimt     dt2ms     lctim     erode     ms1st
                 0.9                      -1.0e-03         1
$
*DEFINE_CURVE_TITLE
$# title
Max_timestep
$#    lcid      sidr       sfa       sfo      offa      offo    dattyp
         1         0       1.0       1.0       0.0       0.0
$#                a1                  o1
                 0.0             1.0e-03
              1000.0             1.0e-03
$
$-------------------------------------------------------------------------------
$    CONTROL CARDS
$-------------------------------------------------------------------------------
$
*CONTROL_MPP_IO_NODUMP
$
*CONTROL_ENERGY
$#    hgen      rwen    slnten     rylen
         2
$
*CONTROL_SHELL
$#  wrpang     esort     irnxx    istupd    theory       bwc     miter      proj

$#  rotascl   intgrd    lamsht    cstyp6    thshel

$#   pstupd  sidt4tu     cntco    itsflg    irquad
                             2
$#   nfail1   nfail4   psnfail    keepcs

$
*CONTROL_CONTACT
$#  slsfac    rwpnal    islchk    shlthk    penopt    thkchg     orien    enmass

$#  usrstr    usrfrc     nsbcs    interm     xpene     ssthk      ecdt   tiedprj

$#   sfric     drfic       edc       vfc        th     th_sf    pen_sf

$#  ignore    frceng   skiprwg    outseg   spotstp   spotdel   spothin

$#    isym    nserod    rwgaps    rwgdth     rwksf      icov    swradf    ithoff

$#  shledg    pstiff    ithcnt    tdcnof     ftall              shltrw
         1
$
$-------------------------------------------------------------------------------
$    OUTPUTS
$-------------------------------------------------------------------------------
$
*DATABASE_GLSTAT
$#      dt    binary      lcur     ioopt
       0.1         2
*DATABASE_MATSUM
$#      dt    binary      lcur     ioopt
       0.1         2
*DATABASE_RBDOUT
$#      dt    binary      lcur     ioopt
       0.1         2
*DATABASE_BNDOUT
$#      dt    binary      lcur     ioopt
       0.1         2
*DATABASE_RCFORC
$#      dt    binary      lcur     ioopt
       0.1         2
*DATABASE_ABSTAT
$#      dt    binary      lcur     ioopt
       0.1         2
$
$-------------------------------------------------------------------------------
$
*DATABASE_BINARY_D3PLOT
$#      dt      lcdt      beam     npltc    psetid
       1.0
$#   loopt

$
$-------------------------------------------------------------------------------
$    INCLUDES
$-------------------------------------------------------------------------------
$
*INCLUDE
?path?
$
*END
$-------------------------------------EOF---------------------------------------
