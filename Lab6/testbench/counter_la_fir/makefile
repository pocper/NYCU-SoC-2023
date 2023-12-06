Target:
	@rm -f counter_la_fir.hex

	@riscv-none-elf-gcc -Wl,--no-warn-rwx-segments -g \
		--save-temps \
		-Xlinker -Map=output.map \
		-I../../firmware \
		-march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ \
		-Wl,-Bstatic,-T,../../firmware/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o counter_la_fir.elf ../../firmware/crt0_vex.S ../../firmware/isr.c fir.c counter_la_fir.c
	@riscv-none-elf-objcopy -O verilog counter_la_fir.elf counter_la_fir.hex

	@sed -ie 's/@10/@00/g' counter_la_fir.hex

	@iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
		-f./include.rtl.list -o counter_la_fir.vvp counter_la_fir_tb.v

	@vvp counter_la_fir.vvp
	@rm -f *.vvp *.elf *.hexe *.s *.o *.i *.out *.map
clean:
	@ rm -rf ./gdb.debug ./gdbwave.debug
	@ rm -f *.vcd *.hex
	@ rm -f *.s *.o *.i *.out *.map
