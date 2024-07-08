#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# gitHubAssets.sh                                        Last Change: 2024-07-08
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
# This is a helper file for getGitHub.sh to keep track of the versions and
# assets available on gitHub.
#-------------------------------------------------------------------------------
LATEST=v4.23
MODEL=${MODEL:-SLOSH}

#-------------------------------------------------------------------------------
# Versions and dates of the various releases of SLOSH on gitHub
# The T### variable is the name of the tag for that version.
#-------------------------------------------------------------------------------
V=v3.94; D="2009-10-08"; vers+=($V); ds+=($D); T394="${V}_$D"
V=v3.95; D="2010-10-19"; vers+=($V); ds+=($D); T395="${V}_$D"
V=v3.96; D="2011-02-17"; vers+=($V); ds+=($D)
V=v3.97; D="2012-01-20"; vers+=($V); ds+=($D); T397="${V}_$D"
V=v4.11; D="2013-05-24"; vers+=($V); ds+=($D); T411="${V}_$D"
V=v4.12; D="2014-09-03"; vers+=($V); ds+=($D); T412="${V}_$D"
V=v4.20; D="2019-11-13"; vers+=($V); ds+=($D); T420="${V}_$D"
V=v4.21; D="2020-01-08"; vers+=($V); ds+=($D); T421="${V}_$D"
V=v4.22; D="2021-05-11"; vers+=($V); ds+=($D)
V=v4.23; D="2024-07-08"; vers+=($V); ds+=($D); T423="${V}_$D"

#-------------------------------------------------------------------------------
# Basin sets per version.  Default to the SLOSH (vs ETSS or PSURGE) file set.
#-------------------------------------------------------------------------------
B_v394=($T394:a1302.hchs $T394:f0502.hmia)
B_v395=($T395:a1302.hchs $T395:f0503.hmi3)
B_v396=("${B_v395[@]}")
B_v397=("${B_v395[@]}")
B_v411=($T411:a1303.hch2 $T395:f0503.hmi3)
#----- v412 -----
B_v412+=($T412:a0102.pn2  $T412:a0401.pv2  $T412:a0503.ny3  $T412:a0603.de3)
B_v412+=($T412:a0701.acy  $T412:a0801.oce  $T412:a0904.cp5  $T412:a1003.hor3)
B_v412+=($T412:a1104.ht3  $T412:a1203.il3  $T412:a1303.hch2 $T412:a1404.esv4)
B_v412+=($T412:f0103.ejx3 $T412:f0202.co2  $T412:f0303.pb3  $T412:f0403.eok3)
B_v412+=($T412:f0503.hmi3 $T412:f0704.eke2 $T412:f0903.efm2 $T412:f1003.etp3)
B_v412+=($T412:f1102.cd2  $T412:f1203.ap3  $T412:f1303.hpa2 $T412:f1404.epn3)
B_v412+=($T412:g0103.emo2 $T412:g0201.hbix $T412:g0309.ms7  $T412:g0310.hms8)
B_v412+=($T412:g0402.lf2  $T412:g0505.ebp3 $T412:g0604.egl3 $T412:g0702.ps2)
B_v412+=($T412:g0803.cr3  $T412:g0903.ebr3 $T412:i0101.bha  $T412:i0202.hsju)
B_v412+=($T412:i0301.evi2 $T412:i0601.hnl  $T412:x0102.eex2 $T412:x0204.egm3)
B_v412+=($T412:x0301.ewct $T412:x0401.egoa $T412:x0501.enom $T412:x0601.eotz)
#----- v420 -----
B_v420+=($T412:a0102.pn2  $T420:a0401.pv2  $T420:a0503.ny3  $T420:a0603.de3)
B_v420+=($T420:a0904.cp5  $T420:a1003.hor3 $T420:a1104.ht3  $T420:a1203.il3)
B_v420+=($T420:a1303.hch2 $T420:a1404.esv4 $T420:f0103.ejx3 $T420:f1003.etp3)
B_v420+=($T420:f1102.cd2  $T420:f1203.ap3  $T420:f1303.hpa2 $T420:f1404.epn3)
B_v420+=($T420:g0103.emo2 $T420:g0309.ms7  $T420:g0402.lf2  $T420:g0505.ebp3)
B_v420+=($T420:g0604.egl3 $T420:g0702.ps2  $T420:g0803.cr3  $T420:g0903.ebr3)
if [[ $MODEL != "ETSS" ]] ; then
   B_v420+=($T412:f0403.eok3 $T420:f0602.hsff $T420:f0603.hsfe $T420:f0604.hsfd)
fi
if [[ $MODEL != "PSURGE" ]] ; then
   B_v420+=($T420:f0202.co2  $T420:f0303.pb3  $T420:f0503.hmi3 $T420:f0704.eke2)
   B_v420+=($T420:f0903.efm2 $T420:x0103.exm  $T420:x0205.eglc $T420:x0303.nep)
   B_v420+=($T420:x0401.egoa $T420:x0602.ebbc)
fi
if [[ $MODEL != "ETSS" && $MODEL != "PSURGE" ]] ; then
   B_v420+=($T412:g0310.hms8 $T412:i0101.bha  $T412:i0202.hsju $T412:i0301.evi2)
   B_v420+=($T412:i0601.hnl)
fi
#----- v421 -----
B_v421+=($T421:a0102.pn2  $T421:a0401.pv2  $T421:a0503.ny3  $T421:a0603.de3)
B_v421+=($T421:a0904.cp5  $T421:a1003.hor3 $T421:a1104.ht3  $T421:a1203.il3)
B_v421+=($T421:a1303.hch2 $T421:a1405.esv4 $T421:f0103.ejx3 $T421:f1003.etp3)
B_v421+=($T421:f1102.cd2  $T421:f1203.ap3  $T421:f1303.hpa2 $T421:f1404.epn3)
B_v421+=($T421:g0103.emo2 $T420:g0309.ms7  $T421:g0402.lf2  $T421:g0505.ebp3)
B_v421+=($T421:g0604.egl3 $T421:g0702.ps2  $T421:g0803.cr3  $T421:g0903.ebr3)
if [[ $MODEL != "ETSS" ]] ; then
   B_v421+=($T421:f0403.eok3 $T421:f0602.hsff $T421:f0603.hsfe $T421:f0604.hsfd)
fi
if [[ $MODEL != "PSURGE" ]] ; then
   B_v421+=($T420:f0202.co2  $T420:f0303.pb3  $T420:f0503.hmi3 $T420:f0704.eke2)
   B_v421+=($T420:f0903.efm2 $T421:x0103.exm  $T421:x0205.eglc $T420:x0303.nep)
   B_v421+=($T421:x0401.egoa $T420:x0602.ebbc)
fi
if [[ $MODEL != "ETSS" && $MODEL != "PSURGE" ]] ; then
   B_v421+=($T421:g0310.hms8 $T421:i0101.bha  $T421:i0202.hsju $T421:i0302.evi2)
   B_v421+=($T421:i0601.hnl)
fi
#----- v422 -----
B_v422=("${B_v421[@]}")
#----- v423 -----
B_v423+=($T423:a0102.pn2  $T423:a0401.pv2  $T423:a0503.ny3  $T423:a0603.de3)
B_v423+=($T423:a0904.cp5  $T423:a1003.hor3 $T423:a1104.ht3  $T423:a1203.il3)
B_v423+=($T423:a1303.hch2 $T423:a1405.esv4 $T423:f0103.ejx3 $T423:f1003.etp3)
B_v423+=($T423:f1102.cd2  $T423:f1203.ap3  $T423:f1303.hpa2 $T423:f1404.epn3)
B_v423+=($T423:g0103.emo2 $T423:g0309.ms7  $T423:g0402.lf2  $T423:g0505.ebp3)
B_v423+=($T423:g0604.egl3 $T423:g0702.ps2  $T423:g0803.cr3  $T423:g0903.ebr3)
if [[ $MODEL != "ETSS" ]] ; then
   B_v423+=($T423:f0403.eok3 $T423:f0602.hsff $T423:f0603.hsfe $T423:f0604.hsfd)
   B_v423+=($T423:i0202.hsju $T423:i0302.evi2 $T423:i0305.evi4)
fi
if [[ $MODEL != "PSURGE" ]] ; then
   B_v423+=($T423:f0202.co2  $T423:f0303.pb3  $T423:f0503.hmi3 $T423:f0704.eke2)
   B_v423+=($T423:f0903.efm2 $T423:x0103.exm  $T423:x0205.eglc $T423:x0303.nep)
   B_v423+=($T423:x0401.egoa $T423:x0602.ebbc)
   B_v423+=($T423:w0401.hakn $T423:w0501.home $T423:w0601.hotz $T423:w0701.hawi)
   B_v423+=($T423:w0801.hscc)
fi
if [[ $MODEL != "ETSS" && $MODEL != "PSURGE" ]] ; then
   B_v423+=($T423:g0310.hms8 $T423:i0601.hnl $T423:i0702.hkw2)
fi

#-------------------------------------------------------------------------------
# Storm sets per version.
#-------------------------------------------------------------------------------
S_v394=($T394:1989-Hugo $T394:1992-Andrew)
S_v395=($T395:1989-Hugo $T395:1992-Andrew)
S_v396=("${S_v395[@]}")
S_v397=($T397:1989-Hugo $T397:1992-Andrew)
S_v411=($T411:1989-Hugo $T411:1992-Andrew)
S_v412=("${S_v411[@]}")
S_v420=($T420:1989-Hugo $T420:1992-Andrew)
S_v421=("${S_v420[@]}")
S_v422=("${S_v420[@]}")
S_v423=($T423:testTrk $T423:gcc450-o0 $T423:gcc450-o3)

#-------------------------------------------------------------------------------
# GuiLib sets per version.
#-------------------------------------------------------------------------------
G_v394=()
G_v395=()
G_v396=()
G_v397=()
G_v411=()
G_v412=($T412:SLOSH-GuiLib)
G_v420=($T420:SLOSH-GuiLib)
G_v421=("${G_v420[@]}")
G_v422=("${G_v420[@]}")
G_v423=("${G_v420[@]}")
