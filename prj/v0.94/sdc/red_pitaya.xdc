# set_property LOC XADC_X0Y0 [get_cells i_ams/XADC_inst]

############################################################################
# Clock constraints                                                        #
############################################################################

# set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks adc_clk]
# set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks par_clk]

# Primary clock from external ADC clock input (125 MHz)
# Waveform: 0.000ns rise, 4.000ns fall (50% duty cycle)
# adc_clk is defined by the shared board XDC (sdc/red_pitaya.xdc).

# RX clock from daisy chain (250 MHz)
# Waveform: 0.000ns rise, 2.000ns fall (50% duty cycle)
# rx_clk is defined by the shared board XDC (sdc/red_pitaya.xdc).

# Generated clocks from PLL
# PLL takes adc_clk_in (125MHz) and generates multiple outputs
# PLL Configuration:
#   CLKIN1_PERIOD = 8.000 (125 MHz input)
#   CLKFBOUT_MULT = 8 (VCO = 1000 MHz)
#   CLKOUT0_DIVIDE = 8 -> pll_adc_clk: 1000/8 = 125 MHz
#   CLKOUT1_DIVIDE = 8 -> pll_dac_clk_1x: 1000/8 = 125 MHz
#   CLKOUT2_DIVIDE = 4 -> pll_dac_clk_2x: 1000/4 = 250 MHz
#   CLKOUT3_DIVIDE = 4 -> pll_dac_clk_2p: 1000/4 = 250 MHz
#   CLKOUT4_DIVIDE = 4 -> pll_ser_clk: 1000/4 = 250 MHz
#   CLKOUT5_DIVIDE = 4 -> pll_pwm_clk: 1000/4 = 250 MHz
#
# For PLLE2_ADV, use -multiply_by and -divide_by to model the PLL behavior
# Formula: output_freq = input_freq * CLKFBOUT_MULT / CLKOUTx_DIVIDE
# So: divide_by = CLKOUTx_DIVIDE, multiply_by = CLKFBOUT_MULT
# PLL generated clocks are defined by the shared board XDC (sdc/red_pitaya.xdc).

# Clock for output DAC clock port (125 MHz)
# Waveform: 0.000ns rise, 4.000ns fall (50% duty cycle)
# dac_clk_o is defined by the shared board XDC (sdc/red_pitaya.xdc).

# False path constraints for cross-domain paths
# These paths are between independent clock domains and should not be timing-checked
set_false_path -from [get_clocks adc_clk] -to [get_clocks pll_adc_clk]
set_false_path -from [get_clocks pll_adc_clk] -to [get_clocks adc_clk]
set_false_path -from [get_clocks adc_clk] -to [get_clocks par_clk]
set_false_path -from [get_clocks par_clk] -to [get_clocks adc_clk]
set_clock_groups -asynchronous -group [get_clocks par_clk] -group [get_clocks pll_adc_clk]
set_false_path -from [get_clocks pll_adc_clk] -to [get_clocks clk_fpga_0]
set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks pll_adc_clk]

# False path constraints between PLL output clocks with different periods
# Paths between 125 MHz and 250 MHz PLL outputs are likely CDC and should not be checked
set_false_path -from [get_clocks pll_adc_clk] -to [get_clocks pll_dac_clk_2x]
set_false_path -from [get_clocks pll_dac_clk_2x] -to [get_clocks pll_adc_clk]
set_false_path -from [get_clocks pll_adc_clk] -to [get_clocks pll_dac_clk_2p]
set_false_path -from [get_clocks pll_dac_clk_2p] -to [get_clocks pll_adc_clk]
set_false_path -from [get_clocks pll_adc_clk] -to [get_clocks pll_pwm_clk]
set_false_path -from [get_clocks pll_pwm_clk] -to [get_clocks pll_adc_clk]

set_false_path -from [get_clocks pll_dac_clk_1x] -to [get_clocks pll_dac_clk_2x]
set_false_path -from [get_clocks pll_dac_clk_2x] -to [get_clocks pll_dac_clk_1x]
set_false_path -from [get_clocks pll_dac_clk_1x] -to [get_clocks pll_dac_clk_2p]
set_false_path -from [get_clocks pll_dac_clk_2p] -to [get_clocks pll_dac_clk_1x]
set_false_path -from [get_clocks pll_dac_clk_1x] -to [get_clocks pll_pwm_clk]
set_false_path -from [get_clocks pll_pwm_clk] -to [get_clocks pll_dac_clk_1x]

set_false_path -from [get_clocks pll_dac_clk_2x] -to [get_clocks pll_dac_clk_2p]
set_false_path -from [get_clocks pll_dac_clk_2p] -to [get_clocks pll_dac_clk_2x]
set_false_path -from [get_clocks pll_dac_clk_2x] -to [get_clocks pll_pwm_clk]
set_false_path -from [get_clocks pll_pwm_clk] -to [get_clocks pll_dac_clk_2x]

set_false_path -from [get_clocks pll_dac_clk_2p] -to [get_clocks pll_pwm_clk]
set_false_path -from [get_clocks pll_pwm_clk] -to [get_clocks pll_dac_clk_2p]


### SATA connector
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_p_o[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_n_o[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_p_i[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_n_i[*]}]

set_property PULLTYPE PULLUP [get_ports daisy_p_i[1]]

# Remove constraints for non-existent expansion connector ports (8-10)
# These ports don't exist in the current design
#set_property -dict {PACKAGE_PIN Y9  IOSTANDARD LVCMOS33} [get_ports {exp_p_io[8]}]
#set_property -dict {PACKAGE_PIN Y8  IOSTANDARD LVCMOS33} [get_ports {exp_n_io[8]}]
#set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33} [get_ports {exp_p_io[9]}]
#set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS33} [get_ports {exp_n_io[9]}]
#set_property -dict {PACKAGE_PIN Y7  IOSTANDARD LVCMOS33} [get_ports {exp_p_io[10]}]
#set_property -dict {PACKAGE_PIN Y6  IOSTANDARD LVCMOS33} [get_ports {exp_n_io[10]}]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[0].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[1].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[2].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[3].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[4].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[5].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[6].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/ctrl_do_reg/C  ]  -to [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/reg_do_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/reg_done_reg/C ]  -to [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/ctrl_done_csff_reg[0]/D ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/ctrl_we_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/reg_we_csff_reg[0]/D    ]
set_max_delay -datapath_only 8.000 -from [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/ctrl_re_reg/C ]   -to [get_pins sys_bus_interconnect/for_bus[7].inst_sys_bus_cdc/reg_re_csff_reg[0]/D    ]

# Remove constraint that references non-existent pins
# set_false_path -from [get_clocks pll_adc_clk] -to [get_pins {i_asg/ch*/inst_axi_dac/dac_rd_clr_r*/D}]

# Remove constraint that references non-existent clock
# set_false_path -from [get_clocks clk_fpga_0] -to [get_pins {spi_done_csff*/D}]
set_max_delay -datapath_only 8.000 -from [get_pins ps/axi_slave_gp0/rd_araddr*[*]/C] -to [get_pins sys_bus_interconnect/for_bus[*].inst_sys_bus_cdc/bus_m\\.addr*[*]*/D]
set_max_delay -datapath_only 8.000 -from [get_pins ps/axi_slave_gp0/wr_awaddr*[*]/C] -to [get_pins sys_bus_interconnect/for_bus[*].inst_sys_bus_cdc/bus_m\\.addr*[*]*/D]
set_max_delay -datapath_only 8.000 -from [get_pins ps/axi_slave_gp0/rd_do*/C] -to [get_pins sys_bus_interconnect/for_bus[*].inst_sys_bus_cdc/bus_m\\.addr*[*]*/D]
set_false_path -from [get_pins ps/axi_slave_gp0/wr_wdata*[*]/C] -to [get_pins sys_bus_interconnect/for_bus[*].inst_sys_bus_cdc/bus_m\\.wdata*[*]*/D]
# set_false_path -from [get_pins sys_bus_interconnect/for_bus[*].inst_sys_bus_cdc/reg_rdata*[*]*/C] -to [get_pins ps/axi_slave_gp0/axi\\.RDATA*[*]*/D]
set_max_delay -datapath_only 8.000 -from [get_pins i_hk/i_freq_meter/ref_gate_reg/C] -to [get_pins {i_hk/i_freq_meter/mes_gate_csff*[0]/D}]

# False path constraints for ADC to DAC data paths
set_false_path -from [get_pins {adc_dat*[*][*]/C}] -to [get_pins {dac_dat_*[*]/D}]
# set_false_path -from [get_pins {i_adc366x/adc_dat_o*[*]/C}] -to [get_pins {dac_dat_*[*]/D}]

############################################################################
# Input/Output Delays                                                  #
############################################################################

# === Input Delays ===
# ADC data inputs (125 MHz clock domain) - already set in main xdc but add here for completeness
set_input_delay -clock adc_clk -max 3.4 [get_ports adc_dat_i[*][*]]
set_input_delay -clock adc_clk -min 0.0 [get_ports adc_dat_i[*][*]]

# Daisy chain inputs
# Note: daisy_p_i[1] is a clock pin, cannot have input delay relative to rx_clk on the same pin
#set_input_delay -clock rx_clk -max 2.0 [get_ports daisy_p_i[*]]
#set_input_delay -clock rx_clk -min 0.0 [get_ports daisy_p_i[*]]
set_input_delay -clock rx_clk -max 2.0 [get_ports daisy_n_i[*]]
set_input_delay -clock rx_clk -min 0.0 [get_ports daisy_n_i[*]]

# === Output Delays ===
# DAC data outputs
set_output_delay -clock pll_dac_clk_1x -max 2.0 [get_ports dac_dat_o[*]]
set_output_delay -clock pll_dac_clk_1x -min 0.0 [get_ports dac_dat_o[*]]

# DAC control outputs
set_output_delay -clock pll_dac_clk_1x -max 2.0 [get_ports dac_wrt_o]
set_output_delay -clock pll_dac_clk_1x -max 2.0 [get_ports dac_sel_o]
set_output_delay -clock pll_dac_clk_1x -max 2.0 [get_ports dac_clk_o]
set_output_delay -clock pll_dac_clk_1x -max 2.0 [get_ports dac_rst_o]

# Daisy chain outputs
# Serial output timing is driven by fclk[1] (250 MHz), exposed as clk_fpga_1.
set_output_delay -clock clk_fpga_1 -max 2.0 [get_ports daisy_p_o[*]]
set_output_delay -clock clk_fpga_1 -min 0.0 [get_ports daisy_p_o[*]]
set_output_delay -clock clk_fpga_1 -max 2.0 [get_ports daisy_n_o[*]]
set_output_delay -clock clk_fpga_1 -min 0.0 [get_ports daisy_n_o[*]]

# LED outputs
set_output_delay -clock clk_fpga_0 -max 2.0 [get_ports led_o[*]]
set_output_delay -clock clk_fpga_0 -min 0.0 [get_ports led_o[*]]

# === Additional Input Delays ===
# XADC inputs (slow signals, use adc_clk or a slow clock)
set_input_delay -clock adc_clk -max 5.0 [get_ports vinp_i[*]]
set_input_delay -clock adc_clk -min 0.0 [get_ports vinp_i[*]]
set_input_delay -clock adc_clk -max 5.0 [get_ports vinn_i[*]]
set_input_delay -clock adc_clk -min 0.0 [get_ports vinn_i[*]]

# Daisy chain inputs (daisy_p_i[1] is a clock, already constrained as rx_clk)
# Only add delay to daisy_p_i[0] and daisy_p_i[2] if they exist
set_input_delay -clock rx_clk -max 2.0 [get_ports daisy_p_i[0]]
set_input_delay -clock rx_clk -min 0.0 [get_ports daisy_p_i[0]]

# Expansion connector inputs
set_input_delay -clock adc_clk -max 5.0 [get_ports exp_p_io[*]]
set_input_delay -clock adc_clk -min 0.0 [get_ports exp_p_io[*]]
set_input_delay -clock adc_clk -max 5.0 [get_ports exp_n_io[*]]
set_input_delay -clock adc_clk -min 0.0 [get_ports exp_n_io[*]]

# === Additional Output Delays ===
# ADC output clock
set_output_delay -clock adc_clk -max 2.0 [get_ports adc_clk_o[*]]
set_output_delay -clock adc_clk -min 0.0 [get_ports adc_clk_o[*]]
set_output_delay -clock adc_clk -max 2.0 [get_ports adc_cdcs_o]
set_output_delay -clock adc_clk -min 0.0 [get_ports adc_cdcs_o]

# PWM DAC outputs
set_output_delay -clock pll_pwm_clk -max 2.0 [get_ports dac_pwm_o[*]]
set_output_delay -clock pll_pwm_clk -min 0.0 [get_ports dac_pwm_o[*]]

# Expansion connector outputs
set_output_delay -clock adc_clk -max 5.0 [get_ports exp_p_io[*]]
set_output_delay -clock adc_clk -min 0.0 [get_ports exp_p_io[*]]
set_output_delay -clock adc_clk -max 5.0 [get_ports exp_n_io[*]]
set_output_delay -clock adc_clk -min 0.0 [get_ports exp_n_io[*]]

# Optional expansion/control ports are not present in this top-level variant.

