## Nexys A7 100 MHz clock
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 10.000 [get_ports clk]

## Reset button: CPU_RESETN on Nexys A7, active low
set_property PACKAGE_PIN C12 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Status LEDs
## LED0 = pass, LED1 = fail, LED2-LED9 = debug_led[0]-debug_led[7]
set_property PACKAGE_PIN H17 [get_ports pass]
set_property IOSTANDARD LVCMOS33 [get_ports pass]

set_property PACKAGE_PIN K15 [get_ports fail]
set_property IOSTANDARD LVCMOS33 [get_ports fail]

set_property PACKAGE_PIN J13 [get_ports {debug_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[0]}]

set_property PACKAGE_PIN N14 [get_ports {debug_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[1]}]

set_property PACKAGE_PIN R18 [get_ports {debug_led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[2]}]

set_property PACKAGE_PIN V17 [get_ports {debug_led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[3]}]

set_property PACKAGE_PIN U17 [get_ports {debug_led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[4]}]

set_property PACKAGE_PIN U16 [get_ports {debug_led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[5]}]

set_property PACKAGE_PIN V16 [get_ports {debug_led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[6]}]

set_property PACKAGE_PIN T15 [get_ports {debug_led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_led[7]}]

## Config voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
