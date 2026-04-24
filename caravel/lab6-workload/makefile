CROSS_COMPILE = riscv-none-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
SIM     = iverilog
VVP     = vvp

FW_DIR  = ../firmware
TB_BASE = ./testbench

FIR_DIR   = $(TB_BASE)/counter_la_fir
MM_DIR    = $(TB_BASE)/counter_la_mm
QS_DIR    = $(TB_BASE)/counter_la_qs
UART_DIR  = $(TB_BASE)/uart
INT_DIR   = $(TB_BASE)/counter_la_integrate

INCLUDES = -I $(FW_DIR) -I $(TB_BASE)/$(TARGET)
CFLAGS  = -march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ -ffreestanding -nostartfiles -g --save-temps
LDFLAGS = -Wl,--no-warn-rwx-segments -Wl,-Bstatic,-T,$(FW_DIR)/sections.lds,--strip-discarded -Xlinker -Map=output.map
IVERILOG_FLAGS = -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=\#1 -f$(TB_BASE)/include.rtl.list -g2012

FW_SRCS = $(FW_DIR)/crt0_vex.S $(FW_DIR)/isr.c

define run_sim
	@echo "Simulating $(1)"
	$(CC) $(CFLAGS) $(2) $(LDFLAGS) $(INCLUDES) -o $(1).elf $(FW_SRCS) $(TB_BASE)/$(1)/*.c
	$(OBJCOPY) -O verilog $(1).elf $(1).hex
	sed -ie 's/@10/@00/g' $(1).hex

	$(SIM) $(IVERILOG_FLAGS) -o $(1).vvp $(TB_BASE)/$(1)/$(1)_tb.v
# 	$(VVP) $(1).vvp | tee $(1).log
	$(VVP) $(1).vvp
	$(MAKE) clean
endef

Target:counter_la_integrate.vvp

counter_la_integrate.vvp:counter_la_integrate.hex
	$(SIM) $(IVERILOG_FLAGS) -o $@ $(INT_DIR)/counter_la_integrate_tb.v
	$(VVP) $@
	$(MAKE) clean

counter_la_integrate.hex:counter_la_integrate.elf
	$(OBJCOPY) -O verilog $< $@
	sed -ie 's/@10/@00/g' $@

counter_la_integrate.elf: $(INT_DIR)/*.c $(FIR_DIR)/fir.c $(MM_DIR)/matmul.c $(UART_DIR)/uart.c $(QS_DIR)/qsort.c
	@echo "Simulating Integrated Test (FIR + MM + QS + UART)"
	$(CC) $(CFLAGS) -DUSER_PROJ_IRQ0_EN $(LDFLAGS) \
		-I $(INT_DIR) -I $(FIR_DIR) -I $(MM_DIR) -I $(QS_DIR) -I $(UART_DIR) -I $(FW_DIR) \
		-o $@ $(FW_SRCS) $^
	

.PHONY: sim_fir sim_mm sim_qs sim_uart all clean

sim_fir:
	$(call run_sim,counter_la_fir)

sim_mm:
	$(call run_sim,counter_la_mm)

sim_qs:
	$(call run_sim,counter_la_qs)

sim_uart:
	$(call run_sim,uart,-DUSER_PROJ_IRQ0_EN)

clean:
	@ rm -f *.vvp *.vcd *hexe
	@ rm -f *.s *.o *.i *.out *.elf
