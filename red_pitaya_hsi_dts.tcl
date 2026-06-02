################################################################################
# HSI tcl script for building RedPitaya DTS (device tree)
#
# Usage:
# hsi -mode tcl -source red_pitaya_hsi_dts.tcl -tclargs projectname
################################################################################


set prj_name [lindex $argv 0]
cd prj/$prj_name

set path_sdk sdk

if {[file exists $path_sdk/red_pitaya.xsa]} {
    hsi open_hw_design $path_sdk/red_pitaya.xsa
} else {
    hsi open_hw_design $path_sdk/red_pitaya.sysdef
}

set ver 2017.2

puts "Input arguments: $argv"
foreach item $argv {
  if {[string match "*DTS_VER*" $item]} {
        # Case 1: DTS_VER=1.2
        if {[string match "*=*DTS_VER*" $item] || [string match "DTS_VER=*" $item]} {
            set param [split $item "="]
            if {[lindex $param 1] ne ""} {
                set ver [lindex $param 1]
            }
        } else {
            # Case 2: DTS_VER 1.2 or -DTS_VER 1.2
            set idx [lsearch -exact $argv $item]
            if {$idx >= 0 && [expr {$idx + 1}] < [llength $argv]} {
                set ver [lindex $argv [expr {$idx + 1}]]
            }
        }
    }
}
puts "DTS version: $ver"


hsi set_repo_path ../../../device-tree-xlnx/

hsi create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0

hsi set_property CONFIG.kernel_version $ver [hsi get_os]
hsi set_property CONFIG.dt_overlay true [hsi get_os]

hsi generate_target -dir $path_sdk/dts

exit
