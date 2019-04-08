// detect an address or an address range that is aligned and size 2^n
// Example: detect address 0x20000000 to 0x2000FFFF
// AddressDetect inst1 (address, out);
// defparam inst1.base_address = 32'h20000000;
// defparam inst1.address_mask = 32'hFFFF0000;
module AddressDetect(address, out);
	input [31:0] address;
	output out;
	parameter base_address = 32'h00000000; // the address to detect
	parameter address_mask = 32'hFFFFFFFF; // which bits to care about (1 means we care)
	
	assign out = ((address & address_mask) == base_address);
endmodule
