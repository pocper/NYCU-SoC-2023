# WorkLoad Optimize SOC (WLOS) Baseline

### Simulation for matrix multiplication
```sh
cd ~/Lab6/testbench/counter_la_mm
make
```

### Simulation for FIR
```sh
cd ~/Lab6/testbench/counter_la_fir
make
```

### Simulation for qsort
```sh
cd ~/Lab6/testbench/counter_la_qs
make
```

### Simulation for uart
```sh
cd ~/Lab6/testbench/uart
make
```

### Simulation for matmul/qsort/FIR/uart
```sh
cd ~/Lab6/testbench/integrate
make
```

## Verification with Vivado
### Synthesis and Generate bitstream
```sh
cp ~/Lab6/rtl/user/*.v ~/Lab6/vivado/vvd_srcs/caravel_soc/rtl/user/
cd ~/Lab6/vivado
make
cp ~/Lab6/testbench/integrate/integrate.hex ~/Lab6/vivado/jupyter_notebook
```


