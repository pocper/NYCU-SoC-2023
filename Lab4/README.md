# 112_SOC_Lab4

## Target
### Lab4-1
- fir.c calucates y[t] = Σ (h[i] * x[t-i])  
- The compiled fir.hex is loaded into bram in user project area
### Lab4-2
- y[t] = Σ (h[i] * x[t-i]) is calucated in hardware accelerator fir.v
- fir_control.c is the firmware
    - Control the hardware accelerator fir.v
    - Communicate with testbench

## Startup
### Lab4-1
1. ```cd ./Lab4/Lab4_1/```
2. ```makefile```
3. You will see the result on the screen

### Lab4-2
1. ```cd ./Lab4/Lab4_2/```
2. ```makefile```
3. You will see the result on the screen

## Result
### Lab4-1
1. [Simulation Result](./Lab4_1/log/simulation.log)
2. [Timing Constraint](./Lab4_1/log/time-pic.png)
3. [Timing Report](./Lab4_1/log/timing_report.txt)
4. [Synthesis](./Lab4_1/log/user_project_wrapper_utilization_synth.rpt)
5. [Report](./Lab4_1/report/report.pdf)
### Lab4-2
1. [Simulation Result](./Lab4_2/log/simulation.log)
2. [Timing Constraint](./Lab4_2/log/time-pic.png)
3. [Timing Report](./Lab4_2/log/timing_report.txt)
4. [Synthesis](./Lab4_2/log/user_project_wrapper_utilization_synth.rpt)
5. [Report](./Lab4_2/report/report.pdf)