# Bank 13
set_property PACKAGE_PIN Y9 [get_ports {GCLK}];  # "GCLK"
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

# Bank 34
set_property PACKAGE_PIN P16 [get_ports {CENTER_PUSHBUTTON}];  # "BTNC"
set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 34]];

# Bank 33
set_property PACKAGE_PIN T22 [get_ports {LED[0]}];  # "LD0"
set_property PACKAGE_PIN T21 [get_ports {LED[1]}];  # "LD1"
set_property PACKAGE_PIN U22 [get_ports {LED[2]}];  # "LD2"
set_property PACKAGE_PIN U21 [get_ports {LED[3]}];  # "LD3"
set_property PACKAGE_PIN V22 [get_ports {LED[4]}];  # "LD4"
set_property PACKAGE_PIN W22 [get_ports {LED[5]}];  # "LD5"
set_property PACKAGE_PIN U19 [get_ports {LED[6]}];  # "LD6"
set_property PACKAGE_PIN U14 [get_ports {LED[7]}];  # "LD7"
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];
