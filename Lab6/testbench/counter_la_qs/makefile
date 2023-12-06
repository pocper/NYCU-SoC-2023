Target:
	rm -f counter_la_qs.hex

	riscv-none-elf-gcc -Wl,--no-warn-rwx-segments -g \
		--save-temps \
		-Xlinker -Map=output.map \
		-I../../firmware \
		-march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ \
		-Wl,-Bstatic,-T,../../firmware/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o counter_la_qs.elf ../../firmware/crt0_vex.S ../../firmware/isr.c qsort.c counter_la_qs.c
	# -nostartfiles	
	riscv-none-elf-objcopy -O verilog counter_la_qs.elf counter_la_qs.hex
	riscv-none-elf-objdump -D counter_la_qs.elf > counter_la_qs.out

	# to fix flash base address
	sed -ie 's/@10/@00/g' counter_la_qs.hex

	iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
		-f./include.rtl.list -o counter_la_qs.vvp counter_la_qs_tb.v

	vvp counter_la_qs.vvp
	rm -f counter_la_qs.vvp counter_la_qs.elf counter_la_qs.hexe
clean:
	@ rm -rf ./gdb.debug ./gdbwave.debug
	@ rm -f *.vcd *.hex
	@ rm -f *.s *.o *.i *.out *.map *.elf
