module matrix_peripheral(CLOCK_50, mem_write, address, data, clock, reset, GPIO0_D, GPIO1_D);

	input CLOCK_50;
	input mem_write, clock, reset;
	input [15:0] data;
	input [31:0] address;
	output [31:0] GPIO0_D, GPIO1_D;
	
	wire M0E, M1E, M2E, M3E, M4E, M5E, M6E, M7E;
	wire M0A, M1A, M2A, M3A, M4A, M5A, M6A, M7A;
	

	wire [15:0]R0, R1, R2, R3, R4, R5, R6, R7;
	
	AddressDetect matrix0address (address, M0A);
	defparam matrix0address.base_address = 32'hFFFFFF00;
	defparam matrix0address.address_mask = 32'hFFFFFFFF;
	assign M0E = M0A & mem_write;
	
	AddressDetect matrix1address (address, M1A);
	defparam matrix1address.base_address = 32'hFFFFFF10;
	defparam matrix1address.address_mask = 32'hFFFFFFFF;
	assign M1E = M1A & mem_write;
	
	AddressDetect matrix2address (address, M2A);
	defparam matrix2address.base_address = 32'hFFFFFF20;
	defparam matrix2address.address_mask = 32'hFFFFFFFF;
	assign M2E = M2A & mem_write;
	
	AddressDetect matrix3address (address, M3A);
	defparam matrix3address.base_address = 32'hFFFFFF30;
	defparam matrix3address.address_mask = 32'hFFFFFFFF;
	assign M3E = M3A & mem_write;
	
	AddressDetect matrix4address (address, M4A);
	defparam matrix4address.base_address = 32'hFFFFFF40;
	defparam matrix4address.address_mask = 32'hFFFFFFFF;
	assign M4E = M4A & mem_write;
	
	AddressDetect matrix5address (address, M5A);
	defparam matrix5address.base_address = 32'hFFFFFF50;
	defparam matrix5address.address_mask = 32'hFFFFFFFF;
	assign M5E = M5A & mem_write;
	
	AddressDetect matrix6address (address, M6A);
	defparam matrix6address.base_address = 32'hFFFFFF60;
	defparam matrix6address.address_mask = 32'hFFFFFFFF;
	assign M6E = M6A & mem_write;
	
	AddressDetect matrix7address (address, M7A);
	defparam matrix7address.base_address = 32'hFFFFFF70;
	defparam matrix7address.address_mask = 32'hFFFFFFFF;
	assign M7E = M7A & mem_write;
	
	
	RegisterNbit MATRIX0(R0, data, M0E, reset, clock);
	defparam MATRIX0.N = 16;

	RegisterNbit MATRIX1(R1, data, M1E, reset, clock);
	defparam MATRIX1.N = 16;
	
	RegisterNbit MATRIX2(R2, data, M2E, reset, clock);
	defparam MATRIX2.N = 16;
	
	RegisterNbit MATRIX3(R3, data, M3E, reset, clock);
	defparam MATRIX3.N = 16;
	
	RegisterNbit MATRIX4(R4, data, M4E, reset, clock);
	defparam MATRIX4.N = 16;
	
	RegisterNbit MATRIX5(R5, data, M5E, reset, clock);
	defparam MATRIX5.N = 16;
	
	RegisterNbit MATRIX6(R6, data, M6E, reset, clock);
	defparam MATRIX6.N = 16;
	
	RegisterNbit MATRIX7(R7, data, M7E, reset, clock);
	defparam MATRIX7.N = 16;

		GPIO_Board gpio_board (
		CLOCK_50, // connect to CLOCK_50 of the DE0
		R0, R1, R2, R3, R4, R5, R6, R7, // row display inputs
		R0, 1'b0, R1, 1'b0, // hex display inputs
		R2, 1'b0, R3, 1'b0, // 0 connected to decimal point inputs
		R4, 1'b0, R5, 1'b0, 
		R6, 1'b0, R7, 1'b0, 
		DIP_SW, // 32x DIP switch output
		instruction, // 32x LED input (show the IR output)
		GPIO0_D, // (output) connect to GPIO0_D
		GPIO1_D // (input/output) connect to GPIO1_D
	);
	
	endmodule
	