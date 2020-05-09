#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/tools/Xilinx/Vivado/2018.3/ids_lite/ISE/bin/lin64:/tools/Xilinx/Vivado/2018.3/bin
else
  PATH=/tools/Xilinx/Vivado/2018.3/ids_lite/ISE/bin/lin64:/tools/Xilinx/Vivado/2018.3/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=/tools/Xilinx/Vivado/2018.3/ids_lite/ISE/lib/lin64
else
  LD_LIBRARY_PATH=/tools/Xilinx/Vivado/2018.3/ids_lite/ISE/lib/lin64:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/misukee/repositories/MIPS_CPU/wyy/lab3/ucas_CDE_v0.3_20180730/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.runs/inst_ram_synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log inst_ram.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source inst_ram.tcl
