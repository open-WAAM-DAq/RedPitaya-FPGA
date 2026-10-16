### SATA connector
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_p_o[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_n_o[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_p_i[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {daisy_n_i[*]}]
set_property PULLTYPE PULLUP [get_ports daisy_p_i[1]]

# The scope with its DMA masters and HP0 runs on the parallel clock of the ADC366x (derived
# from adc_dclk), the DAC and the GPIO block on the clocks derived from dac_clk, the register
# bus on the PS clocks. Every crossing is synchronized: the trigger and event buses (pulse_cdc
# in rp_oscilloscope), the register interfaces of the blocks, the HP ports (inside the PS) and
# the DAC to ADC loopback in the top (two registers).
set_clock_groups -asynchronous \
  -group [get_clocks -include_generated_clocks adc_dclk] \
  -group [get_clocks -include_generated_clocks dac_clk] \
  -group [get_clocks -include_generated_clocks rx_clk] \
  -group [get_clocks clk_fpga_*]

set_false_path -quiet -from [get_pins -quiet {system_wrapper_i/rp_dac/inst/U_dac1/U_dma_mm2s/U_dma_mm2s_ctrl/fifo_re_rin_reg/D}] -to [get_pins -quiet system_wrapper_i/rp_dac/inst/U_dac1/U_dma_mm2s/U_dma_mm2s_ctrl/fifo_re_r_reg/D]
set_false_path -quiet -from [get_pins -quiet {system_wrapper_i/rp_dac/inst/U_dac2/U_dma_mm2s/U_dma_mm2s_ctrl/fifo_re_rin_reg/D}] -to [get_pins -quiet system_wrapper_i/rp_dac/inst/U_dac2/U_dma_mm2s/U_dma_mm2s_ctrl/fifo_re_r_reg/D]
