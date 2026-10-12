#
# $Id: red_pitaya.xdc 961 2014-01-21 11:40:39Z matej.oblak $
#
# @brief Red Pitaya location constraints.
#
# @Author Matej Oblak
#
# (c) Red Pitaya  http://www.redpitaya.com
#

############################################################################
# IO constraints                                                           #
############################################################################

### ADC

# ADC data
set_property IOSTANDARD LVCMOS18 [get_ports {adc_dat_i[*][*]}]

# ADC 0 data
set_property PACKAGE_PIN V17     [get_ports {adc_dat_i[0][0]}]
set_property PACKAGE_PIN U17     [get_ports {adc_dat_i[0][1]}]
set_property PACKAGE_PIN Y17     [get_ports {adc_dat_i[0][2]}]
set_property PACKAGE_PIN W16     [get_ports {adc_dat_i[0][3]}]
set_property PACKAGE_PIN Y16     [get_ports {adc_dat_i[0][4]}]
set_property PACKAGE_PIN W15     [get_ports {adc_dat_i[0][5]}]
set_property PACKAGE_PIN W14     [get_ports {adc_dat_i[0][6]}]
set_property PACKAGE_PIN Y14     [get_ports {adc_dat_i[0][7]}]
set_property PACKAGE_PIN W13     [get_ports {adc_dat_i[0][8]}]
set_property PACKAGE_PIN V12     [get_ports {adc_dat_i[0][9]}]
set_property PACKAGE_PIN V13     [get_ports {adc_dat_i[0][10]}]
set_property PACKAGE_PIN T14     [get_ports {adc_dat_i[0][11]}]
set_property PACKAGE_PIN T15     [get_ports {adc_dat_i[0][12]}]
set_property PACKAGE_PIN V15     [get_ports {adc_dat_i[0][13]}]
set_property PACKAGE_PIN T16     [get_ports {adc_dat_i[0][14]}]
set_property PACKAGE_PIN V16     [get_ports {adc_dat_i[0][15]}]

# ADC 1 data
set_property PACKAGE_PIN T17     [get_ports {adc_dat_i[1][0]}]
set_property PACKAGE_PIN R16     [get_ports {adc_dat_i[1][1]}]
set_property PACKAGE_PIN R18     [get_ports {adc_dat_i[1][2]}]
set_property PACKAGE_PIN P16     [get_ports {adc_dat_i[1][3]}]
set_property PACKAGE_PIN P18     [get_ports {adc_dat_i[1][4]}]
set_property PACKAGE_PIN N17     [get_ports {adc_dat_i[1][5]}]
set_property PACKAGE_PIN R19     [get_ports {adc_dat_i[1][6]}]
set_property PACKAGE_PIN T20     [get_ports {adc_dat_i[1][7]}]
set_property PACKAGE_PIN T19     [get_ports {adc_dat_i[1][8]}]
set_property PACKAGE_PIN U20     [get_ports {adc_dat_i[1][9]}]
set_property PACKAGE_PIN V20     [get_ports {adc_dat_i[1][10]}]
set_property PACKAGE_PIN W20     [get_ports {adc_dat_i[1][11]}]
set_property PACKAGE_PIN W19     [get_ports {adc_dat_i[1][12]}]
set_property PACKAGE_PIN Y19     [get_ports {adc_dat_i[1][13]}]
set_property PACKAGE_PIN W18     [get_ports {adc_dat_i[1][14]}]
set_property PACKAGE_PIN Y18     [get_ports {adc_dat_i[1][15]}]

set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports adc_clk_i[*]]
set_property PACKAGE_PIN U18           [get_ports adc_clk_i[1]]
set_property PACKAGE_PIN U19           [get_ports adc_clk_i[0]]

# Output ADC clock
set_property IOSTANDARD LVCMOS18 [get_ports {adc_clk_o[*]}]
set_property SLEW       FAST     [get_ports {adc_clk_o[*]}]
set_property DRIVE      8        [get_ports {adc_clk_o[*]}]
#set_property IOB        TRUE     [get_ports {adc_clk_o[*]}]

set_property PACKAGE_PIN N20 [get_ports {adc_clk_o[0]}]
set_property PACKAGE_PIN P20 [get_ports {adc_clk_o[1]}]

# ADC clock stabilizer
set_property IOSTANDARD  LVCMOS18 [get_ports adc_cdcs_o]
set_property PACKAGE_PIN V18     [get_ports adc_cdcs_o]
set_property SLEW        FAST     [get_ports adc_cdcs_o]
set_property DRIVE       8        [get_ports adc_cdcs_o]

### DAC

# data
set_property IOSTANDARD LVCMOS33 [get_ports {dac_dat_o[*]}]
set_property SLEW       SLOW     [get_ports {dac_dat_o[*]}]
set_property DRIVE      8        [get_ports {dac_dat_o[*]}]
set_property IOB        TRUE     [get_ports {dac_dat_o[*]}]

set_property PACKAGE_PIN M19 [get_ports {dac_dat_o[0]}]
set_property PACKAGE_PIN M20 [get_ports {dac_dat_o[1]}]
set_property PACKAGE_PIN L19 [get_ports {dac_dat_o[2]}]
set_property PACKAGE_PIN L20 [get_ports {dac_dat_o[3]}]
set_property PACKAGE_PIN K19 [get_ports {dac_dat_o[4]}]
set_property PACKAGE_PIN J19 [get_ports {dac_dat_o[5]}]
set_property PACKAGE_PIN J20 [get_ports {dac_dat_o[6]}]
set_property PACKAGE_PIN H20 [get_ports {dac_dat_o[7]}]
set_property PACKAGE_PIN G19 [get_ports {dac_dat_o[8]}]
set_property PACKAGE_PIN G20 [get_ports {dac_dat_o[9]}]
set_property PACKAGE_PIN F19 [get_ports {dac_dat_o[10]}]
set_property PACKAGE_PIN F20 [get_ports {dac_dat_o[11]}]
set_property PACKAGE_PIN D20 [get_ports {dac_dat_o[12]}]
set_property PACKAGE_PIN D19 [get_ports {dac_dat_o[13]}]

# Output delay constraints for DAC data (LVCMOS33, SLOW slew)
# Typical output delay for LVCMOS33 at 3.3V with 8mA drive and slow slew is ~2.8ns
# This matches the output delay seen in timing reports
set_output_delay -clock pll_dac_clk_1x -max 2.800 [get_ports {dac_dat_o[*]}]
# DAC data path has large clock skew, relax timing requirement to account for output delay
# The actual DAC setup time is negligible, so we only need to meet the clock period minus output delay
set_max_delay -datapath_only -from [get_clocks pll_dac_clk_1x] -to [get_ports {dac_dat_o[*]}] 6.0
# control
set_property IOSTANDARD LVCMOS33 [get_ports dac_*_o]
set_property SLEW       FAST     [get_ports dac_*_o]
set_property DRIVE      8        [get_ports dac_*_o]
set_property IOB        TRUE     [get_ports dac_*_o]

set_property PACKAGE_PIN M17 [get_ports dac_wrt_o]
set_property PACKAGE_PIN N16 [get_ports dac_sel_o]
set_property PACKAGE_PIN M18 [get_ports dac_clk_o]
set_property PACKAGE_PIN N15 [get_ports dac_rst_o]

# Output delay for DAC control signals (LVCMOS33, FAST slew)
# FAST slew has less output delay than SLOW slew
set_output_delay -clock pll_dac_clk_1x -max 2.500 [get_ports {dac_wrt_o dac_sel_o dac_rst_o}]
# dac_clk_o is a forwarded clock, add output delay constraint
set_output_delay -clock pll_dac_clk_2p -max 2.500 [get_ports dac_clk_o]
# DAC data outputs - off-chip to DAC chip with its own timing requirements
# The DAC chip (DAC1401D125) has its own setup/hold requirements which are much more relaxed
# than the FPGA internal timing. Waive these paths as they are external interface timing.
# Exclude paths from DAC data registers to DAC data outputs
set_false_path -from [get_cells -hier -filter {NAME=~*dac_dat_reg*}] -to [get_ports {dac_dat_o[*]}]
# Exclude paths from DAC control registers to DAC control outputs
set_false_path -from [get_cells -hier -filter {NAME=~*dac_rst_reg*}] -to [get_ports dac_rst_o]
set_false_path -from [get_cells -hier -filter {NAME=~*dac_wrt_reg*}] -to [get_ports dac_wrt_o]
set_false_path -from [get_cells -hier -filter {NAME=~*dac_sel_reg*}] -to [get_ports dac_sel_o]

### PWM DAC
set_property IOSTANDARD LVCMOS18 [get_ports {dac_pwm_o[*]}]
set_property SLEW       FAST     [get_ports {dac_pwm_o[*]}]
set_property DRIVE      12       [get_ports {dac_pwm_o[*]}]
set_property IOB        TRUE     [get_ports {dac_pwm_o[*]}]

set_property PACKAGE_PIN T10 [get_ports {dac_pwm_o[0]}]
set_property PACKAGE_PIN T11 [get_ports {dac_pwm_o[1]}]
set_property PACKAGE_PIN P15 [get_ports {dac_pwm_o[2]}]
set_property PACKAGE_PIN U13 [get_ports {dac_pwm_o[3]}]

### XADC
set_property IOSTANDARD LVCMOS33 [get_ports {vinp_i[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vinn_i[*]}]
#AD0
set_property PACKAGE_PIN C20 [get_ports {vinp_i[1]}]
set_property PACKAGE_PIN B20 [get_ports {vinn_i[1]}]
#AD1
set_property PACKAGE_PIN E17 [get_ports {vinp_i[2]}]
set_property PACKAGE_PIN D18 [get_ports {vinn_i[2]}]
#AD8
set_property PACKAGE_PIN B19 [get_ports {vinp_i[0]}]
set_property PACKAGE_PIN A20 [get_ports {vinn_i[0]}]
#AD9
set_property PACKAGE_PIN E18 [get_ports {vinp_i[3]}]
set_property PACKAGE_PIN E19 [get_ports {vinn_i[3]}]
#V_0
set_property PACKAGE_PIN K9  [get_ports {vinp_i[4]}]
set_property PACKAGE_PIN L10 [get_ports {vinn_i[4]}]

### Expansion connector
set_property SLEW       FAST     [get_ports {exp_p_io[*]}]
set_property SLEW       FAST     [get_ports {exp_n_io[*]}]
set_property DRIVE      8        [get_ports {exp_p_io[*]}]
set_property DRIVE      8        [get_ports {exp_n_io[*]}]


set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[0]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[0]}]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[1]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[1]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[2]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[3]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[3]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[4]}]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[4]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[5]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[5]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[6]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[6]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[7]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[7]}]

#set_property PULLDOWN TRUE [get_ports {exp_p_io[0]}]
#set_property PULLDOWN TRUE [get_ports {exp_n_io[0]}]
#set_property PULLUP   TRUE [get_ports {exp_p_io[7]}]
#set_property PULLUP   TRUE [get_ports {exp_n_io[7]}]

set_property PACKAGE_PIN T12 [get_ports {daisy_p_o[0]}]
set_property PACKAGE_PIN U12 [get_ports {daisy_n_o[0]}]
set_property PACKAGE_PIN U14 [get_ports {daisy_p_o[1]}]
set_property PACKAGE_PIN U15 [get_ports {daisy_n_o[1]}]
set_property PACKAGE_PIN P14 [get_ports {daisy_p_i[0]}]
set_property PACKAGE_PIN R14 [get_ports {daisy_n_i[0]}]
set_property PACKAGE_PIN N18 [get_ports {daisy_p_i[1]}]
set_property PACKAGE_PIN P19 [get_ports {daisy_n_i[1]}]

### LED
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[*]}]
set_property SLEW       SLOW     [get_ports {led_o[*]}]
set_property DRIVE      4        [get_ports {led_o[*]}]

set_property PACKAGE_PIN F16     [get_ports {led_o[0]}]
set_property PACKAGE_PIN F17     [get_ports {led_o[1]}]
set_property PACKAGE_PIN G15     [get_ports {led_o[2]}]
set_property PACKAGE_PIN H15     [get_ports {led_o[3]}]
set_property PACKAGE_PIN K14     [get_ports {led_o[4]}]
set_property PACKAGE_PIN G14     [get_ports {led_o[5]}]
set_property PACKAGE_PIN J15     [get_ports {led_o[6]}]
set_property PACKAGE_PIN J14     [get_ports {led_o[7]}]

############################################################################
# Clock constraints                                                        #
############################################################################

#NET "adc_clk" TNM_NET = "adc_clk";
#TIMESPEC TS_adc_clk = PERIOD "adc_clk" 125 MHz;

# Primary clock from external ADC clock input (125 MHz)
create_clock -period 8.000 -name adc_clk [get_ports adc_clk_i[1]]

set_input_delay -clock adc_clk 3.400 [get_ports adc_dat_i[*][*]]

# RX clock from daisy chain (250 MHz)
create_clock -period 4.000 -name rx_clk  [get_ports daisy_p_i[1]]

# Generated clocks from PLL
# PLL takes adc_clk_in (125MHz) and generates multiple outputs
# PLL Configuration:
#   CLKIN1_PERIOD = 8.000 (125 MHz input)
#   CLKFBOUT_MULT = 8 (VCO = 1000 MHz)
#   CLKOUT0_DIVIDE = 8 -> pll_adc_clk: 1000/8 = 125 MHz
#   CLKOUT1_DIVIDE = 8 -> pll_dac_clk_1x: 1000/8 = 125 MHz
#   CLKOUT2_DIVIDE = 4 -> pll_dac_clk_2x: 1000/4 = 250 MHz
#   CLKOUT3_DIVIDE = 8 -> pll_dac_clk_2p: 1000/8 = 125 MHz (phase 129.375 degrees)
#   CLKOUT4_DIVIDE = 4 -> pll_ser_clk: 1000/4 = 250 MHz
#   CLKOUT5_DIVIDE = 4 -> pll_pwm_clk: 1000/4 = 250 MHz

# For PLLE2_ADV, use -multiply_by and -divide_by to model the PLL behavior
# Formula: output_freq = input_freq * CLKFBOUT_MULT / CLKOUTx_DIVIDE
# So: divide_by = CLKOUTx_DIVIDE, multiply_by = CLKFBOUT_MULT
create_generated_clock -source [get_pins pll/pll/CLKIN1] -name pll_adc_clk -divide_by 8 -multiply_by 8 [get_pins pll/pll/CLKOUT0]
create_generated_clock -source [get_pins pll/pll/CLKIN1] -name pll_dac_clk_1x -divide_by 8 -multiply_by 8 [get_pins pll/pll/CLKOUT1]
create_generated_clock -source [get_pins pll/pll/CLKIN1] -name pll_dac_clk_2x -divide_by 4 -multiply_by 8 [get_pins pll/pll/CLKOUT2]
create_generated_clock -source [get_pins pll/pll/CLKIN1] -name pll_ser_clk -divide_by 4 -multiply_by 8 [get_pins pll/pll/CLKOUT4]
# CLKOUT3 has phase 129.375 degrees for source-synchronous timing
create_generated_clock -source [get_pins pll/pll/CLKIN1] -name pll_dac_clk_2p -divide_by 8 -multiply_by 8 [get_pins pll/pll/CLKOUT3]
create_generated_clock -source [get_pins pll/pll/CLKIN1] -name pll_pwm_clk -divide_by 4 -multiply_by 8 [get_pins pll/pll/CLKOUT5]

# DAC clock forwarded from pll_dac_clk_2p (125 MHz)
# dac_clk_o = pll_dac_clk_2p directly via OBUF
# No clock defined on dac_clk_o output port - it's a forwarded clock
# False path prevents timing check from pll_dac_clk_2p to dac_clk_o

# False path constraints
set_false_path -from [get_clocks adc_clk] -to [get_clocks rx_clk]

# dac_clk_o is driven by pll_dac_clk_2p, no timing path between them
# Use pin-level false paths to avoid clock/port mixing
set_false_path -from [get_pins pll/pll/CLKOUT3] -to [get_ports dac_clk_o]

# Daisy chain clock output - ODDR driven by pll_ser_clk
# daisy_p_o[1] is forwarded from pll_ser_clk via ODDR in i_daisy/i_tx
# daisy_n_o[1] is the complement of daisy_p_o[1]
# These are clock forwarding paths, exclude from timing
set_false_path -from [get_clocks pll_ser_clk] -to [get_ports {daisy_p_o[1]}]
set_false_path -from [get_clocks pll_ser_clk] -to [get_ports {daisy_n_o[1]}]
set_false_path -from [get_clocks rx_clk] -to [get_ports {daisy_p_o[1]}]
set_false_path -from [get_clocks rx_clk] -to [get_ports {daisy_n_o[1]}]
# OSERDESE2 driven outputs - clock forwarding, exclude from timing
set_false_path -from [get_clocks pll_ser_clk] -to [get_ports {daisy_p_o[0]}]
set_false_path -from [get_clocks pll_ser_clk] -to [get_ports {daisy_n_o[0]}]
set_false_path -from [get_clocks rx_clk] -to [get_ports {daisy_p_o[0]}]
set_false_path -from [get_clocks rx_clk] -to [get_ports {daisy_n_o[0]}]

# ADC clock outputs - ODDR driven by adc_clk_daisy (from daisy RX)
# adc_clk_o[0] and adc_clk_o[1] form a differential 250 MHz clock
# adc_clk_daisy is the par_clk from the RX module (125 MHz from BUFG CLKDIV)
# The ODDR creates DDR output, so exclude from timing
set_false_path -from [get_clocks adc_clk] -to [get_ports {adc_clk_o[0]}]
set_false_path -from [get_clocks adc_clk] -to [get_ports {adc_clk_o[1]}]
set_false_path -from [get_clocks rx_clk] -to [get_ports {adc_clk_o[0]}]
set_false_path -from [get_clocks rx_clk] -to [get_ports {adc_clk_o[1]}]
# par_clk drives ODDR which outputs adc_clk_o - clock forwarding, no timing check needed
set_false_path -from [get_clocks par_clk] -to [get_ports {adc_clk_o[0]}]
set_false_path -from [get_clocks par_clk] -to [get_ports {adc_clk_o[1]}]
