#include <defs.h>
#include <stub.c>
#include <caravel.h>
#define N 11
#define data_length 64
int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};

#define addr_WB_AXI      0x30000000
#define addr_fir_exmem   0x38000000
#define addr_fir_control 0x00
#define addr_data_length 0x10
#define addr_coeff       0x40
#define addr_fir_x       0x80
#define addr_fir_y       0x84

#define bits_control_ap_start     0x00 // r/w
#define bits_control_ap_done      0x01 // r
#define bits_control_ap_idle      0x02 // r
#define bits_control_reserved     0x03 // r
#define bits_control_x_readyWrite 0x04 // r/w
#define bits_control_y_readyRead  0x05 // r

// Send data to mprj_io
#define reg_fir_exmem  (*(volatile uint32_t *) addr_fir_exmem)

// Send data to verilog - FIR
#define reg_fir_control        (*(volatile uint32_t *) addr_WB_AXI)
#define reg_fir_data_length    (*(volatile uint32_t *) (addr_WB_AXI | addr_data_length))
#define reg_fir_coeff(n)       (*(volatile uint32_t *) (addr_WB_AXI | (addr_coeff + 4*n)))
#define reg_fir_x              (*(volatile uint32_t *) (addr_WB_AXI | addr_fir_x))
#define reg_fir_y              (*(volatile uint32_t *) (addr_WB_AXI | addr_fir_y))

void __attribute__ ((section(".mprjram"))) fir()
{
	// The upper GPIO pins are configured to be output
	// and accessble to the management SoC.
	// Used to flad the start/end of a test 
	// The lower GPIO pins are configured to be output
	// and accessible to the user project.  They show
	// the project count value, although this test is
	// designed to read the project count through the
	// logic analyzer probes.
	// I/O 6 is configured for the UART Tx line

	reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

	reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

	reg_mprj_io_6  = GPIO_MODE_MGMT_STD_OUTPUT;

	reg_uart_enable = 1;

	// Now, apply the configuration
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1);

	// Set User Project Slaves Enable
	reg_wb_enable = 1;

	// Flag - Start latency-timer (in testbench)
	reg_mprj_datal = (0xA5<<16);

	// FIR - data length
	reg_fir_data_length = data_length;

	// FIR - tap coefficient
	for(int n = 0; n < N; n++)
		reg_fir_coeff(n) = taps[n];
	
	// AXI-lite(Write/Read) - Correct

	// FIR - ap_start
	reg_fir_control = (1 << bits_control_ap_start);

	int y = 0;
	for (int n = 0; n < data_length; n++)
	{
		// Wait for FIR ready to write x
		while((reg_fir_control & (1 << bits_control_x_readyWrite)) != (1 << bits_control_x_readyWrite)) ;

		// Send x[n] to FIR
		reg_fir_x = n;

		// Wait for FIR ready to read y
		while((reg_fir_control & (1 << bits_control_y_readyRead)) != (1 << bits_control_y_readyRead)) ;

		// Receive y[n] from FIR
		y = reg_fir_y;
	}

	// FIR - ap_idle
	while((reg_fir_control & (1 << bits_control_ap_idle)) != (1 << bits_control_ap_idle)) ;

	// Flag - Stop latency-timer (in testbench)
	reg_mprj_datal = (y<<24) | (0x5A<<16);
}

