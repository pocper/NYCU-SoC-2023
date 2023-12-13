Target:
	@ rm -f integrate.hex
	@ riscv-none-elf-gcc -Wl,--no-warn-rwx-segments -g \
		--save-temps \
		-Xlinker -Map=output.map \
		-I../../firmware \
		-march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ -DUSER_PROJ_IRQ0_EN \
		-Wl,-Bstatic,-T,../../firmware/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o integrate.elf ../../firmware/crt0_vex.S ../../firmware/isr.c matmul.c qsort.c fir.c uart.c counter_la_integrate.c
	@ riscv-none-elf-objcopy -O verilog integrate.elf integrate.hex
	@ rm -f *.s *.o *.i *.map
	@ sed -ie 's/@10/@00/g' integrate.hex

	# @ iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
	# 	-f./include.rtl.list -o integrate.vvp counter_la_integrate_tb.v 

	# @ vvp -l simulation.log integrate.vvp
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe *.vvp

.PHONY: clean wv
clean:
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe *.vvp *.vcd *.hex *.log
wv:
	@ gtkwave integrate.vcd  waveform.gtkw  --autosavename