################################################################################
# HSI tcl script for building RedPitaya FSBL
#
# Usage:
# hsi -mode tcl -source red_pitaya_hsi_fsbl.tcl -tclargs projectname
################################################################################

cd prj/$::argv

set path_sdk sdk

if {[file exists $path_sdk/red_pitaya.xsa]} {
    hsi open_hw_design $path_sdk/red_pitaya.xsa
} else {
    hsi open_hw_design $path_sdk/red_pitaya.sysdef
}

hsi generate_app    -os standalone \
                    -proc ps7_cortexa9_0 \
                    -app zynq_fsbl \
                    -compile \
                    -sw fsbl \
                    -dir $path_sdk/fsbl

exit
