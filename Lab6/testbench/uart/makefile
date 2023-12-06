Target:
	@ rm -f uart.hex

	@ riscv-none-elf-gcc -Wl,--no-warn-rwx-segments -g \
		--save-temps \
		-Xlinker -Map=output.map \
		-I../../firmware \
		-march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ -DUSER_PROJ_IRQ0_EN \
		-Wl,-Bstatic,-T,../../firmware/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o uart.elf ../../firmware/crt0_vex.S ../../firmware/isr.c uart.c counter_la_uart.c
	# -nostartfiles	
	@ riscv-none-elf-objcopy -O verilog uart.elf uart.hex
	@ riscv-none-elf-objdump -D uart.elf > uart.out

	# to fix flash base address
	@ sed -ie 's/@10/@00/g' uart.hex

	@ iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
		-f./include.rtl.list -o uart.vvp uart_tb.v 

	@ vvp -l simulation.log uart.vvp
	@ rm -f uart.vvp uart.elf uart.hexe

.PHONY: clean wv
clean:
	@ rm -rf ./gdb.debug ./gdbwave.debug
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe *.vvp *.vcd *.hex
wv:
	@ gtkwave uart.vcd  waveform.gtkw  --autosavename