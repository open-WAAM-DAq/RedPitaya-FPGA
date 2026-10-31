# Legacy ADC constraints for the 125-14 Z7020 projects other than v0.94, which
# capture the ADC data from the PLL clock.  v0.94 captures it from the
# forwarded clock and sets its own input delay in prj/v0.94/sdc.
set_input_delay -clock adc_clk 3.400 [get_ports adc_dat_i[*][*]]
set_false_path -from [get_clocks adc_clk]     -to [get_clocks pll_adc_clk]
