# 1. Clean up (delete old library)
if {[file exists work]} {
    vdel -lib work -all
}

# 2. Create new library
vlib work

# 3. Compile the Design & Verification Environment
#    Order: Interface -> Design -> Testbench
vlog -sv src/fifo_if.sv
vlog -sv src/fifo.sv
vlog -sv tb/fifo_tb.sv

# 4. Load the Simulation
#    -voptargs=+acc is required to see waveforms
vsim -voptargs=+acc work.fifo_tb

# 5. Add Waves
#    Add all signals from the interface so we can see what's happening
add wave -position insertpoint sim:/fifo_tb/intf/*

# 6. Run the simulation
#    It will run until the $finish in the testbench
run -all