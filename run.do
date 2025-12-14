if {[file exists work]} {
    vdel -lib work -all
}
vlib work

vlog -sv src/fifo_if.sv
vlog -sv src/fifo.sv
vlog -sv tb/fifo_tb.sv

# Note the -c here!
vsim -c -voptargs=+acc work.fifo_tb

run -all

# THIS LINE IS MANDATORY
#quit -f