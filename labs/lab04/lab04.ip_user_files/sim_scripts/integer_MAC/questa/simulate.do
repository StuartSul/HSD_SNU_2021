onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib integer_MAC_opt

do {wave.do}

view wave
view structure
view signals

do {integer_MAC.udo}

run -all

quit -force
