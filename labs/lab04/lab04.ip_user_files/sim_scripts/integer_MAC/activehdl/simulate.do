onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+integer_MAC -L xbip_utils_v3_0_9 -L xbip_pipe_v3_0_5 -L xbip_bram18k_v3_0_5 -L mult_gen_v12_0_14 -L xbip_dsp48_wrapper_v3_0_4 -L xbip_dsp48_addsub_v3_0_5 -L xbip_dsp48_multadd_v3_0_5 -L xbip_multadd_v3_0_13 -L xil_defaultlib -L secureip -O5 xil_defaultlib.integer_MAC

do {wave.do}

view wave
view structure

do {integer_MAC.udo}

run -all

endsim

quit -force
