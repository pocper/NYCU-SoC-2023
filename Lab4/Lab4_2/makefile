PATH_TB = ./testbench
PATH_FIRMWARE = ../firmware
PATH_LOG = ./log

Target:
	@ riscv-none-elf-gcc -Wl,--no-warn-rwx-segments -g \
		--save-temps \
		-I $(PATH_FIRMWARE) \
		-march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ \
		-Wl,-Bstatic,-T,$(PATH_FIRMWARE)/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o $(PATH_TB)/counter_la_fir.elf $(PATH_FIRMWARE)/crt0_vex.S $(PATH_FIRMWARE)/isr.c $(PATH_TB)/fir.c $(PATH_TB)/fir_control.c
	@ riscv-none-elf-objcopy -O verilog $(PATH_TB)/counter_la_fir.elf $(PATH_TB)/counter_la_fir.hex
	@ sed -ie 's/@10/@00/g' $(PATH_TB)/counter_la_fir.hex
	@ iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
		-f$(PATH_TB)/include.rtl.list -o $(PATH_TB)/counter_la_fir.vvp $(PATH_TB)/counter_la_fir_tb.v
	@ vvp $(PATH_TB)/counter_la_fir.vvp | tee $(PATH_LOG)/simulation.log
	@ rm -f $(PATH_TB)/*.s $(PATH_TB)/*.o $(PATH_TB)/*.i $(PATH_TB)/*.out $(PATH_TB)/*.elf $(PATH_TB)/*.hexe $(PATH_TB)/*.hex $(PATH_TB)/*.vcd $(PATH_TB)/*.vvp