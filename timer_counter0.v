/*
timer.v - Timer peripheral for LEGv8 processor, based on Timer0/2 from ATMEGA328
Andrew Hollabaugh - started 4/11/2019
*/
module timer(clk, rst, data, address, write_en, read_en, OCxA, OCxB);
    input clk, rst, write_en, read_en;
    input [31:0] address;
    inout [63:0] data;
    output OCxA, OCxB;

    wire [11:0] control_reg;
    wire [2:0] int_reg;
	wire [63:0] compA_top, compB_top;
    wire [63:0] timer_value;
    wire timer_clk;

//uncomment stuff below and comment all stuff above to have more timer info in testbench
/*module timer(clk, rst, data, address, write_en, read_en, OCxA, OCxB, control_reg, timer_value, compA_top, compB_top, int_reg, timer_clk);
	input clk, rst, write_en, read_en;
	input [31:0] address;
	inout [63:0] data;
    output [11:0] control_reg;
    output [2:0] int_reg;
    output [63:0] timer_value, compA_top, compB_top;
    output timer_clk;
    output OCxA, OCxB;*/

    wire address_en;
	wire [4:0] reg_select_word;
	wire TCCRx_L, TCNTx_L, OCRxA_L, OCRxB_L, TIFRx_L;
    wire FOCxA, FOCxB;
    wire [1:0] COMxA, COMxB;
    wire [2:0] WGMx, CSx;
    wire OCFxA, OCFxB, TOVx; 
    wire [2:0] int_reg_in;
    wire timer_en, clk_src, ext_clk_edge;
    wire dir, timer_clear;
    wire [1:0] pwm_control_a, pwm_control_b;

    parameter base_address = 32'h00000000;
    parameter TCCRx_address = 32'h00000000;
    parameter TCNTx_address = 32'h00000001;
    parameter OCRxA_address = 32'h00000002;
    parameter OCRxB_address = 32'h00000003;
    parameter TIFRx_address = 32'h00000004;

    AddressDetect address_detect(address, address_en);
    defparam address_detect.base_address = base_address;
    defparam address_detect.address_mask = 32'hFFFFF000;

	reg_write_sel reg_write_sel(address, address_en, write_en, TCCRx_address, TCNTx_address, OCRxA_address, OCRxB_address, TIFRx_address, reg_select_word);
	assign TCCRx_L = reg_select_word[0];
	assign TCNTx_L = reg_select_word[1];
	assign OCRxA_L = reg_select_word[2];
	assign OCRxB_L = reg_select_word[3];
    assign TIFRx_L = reg_select_word[4];

    reg_read_sel reg_read_sel(address, address_en, read_en, data, TCCRx_address, TCNTx_address, OCRxA_address, OCRxB_address, TIFRx_address, {52'b0, control_reg}, timer_value, compA_top, compB_top, {61'b0, int_reg});

    TCCRx TCCRx(clk, timer_clk, rst, TCCRx_L, data, control_reg);

    assign WGMx = control_reg[2:0];
    assign COMxB = control_reg[4:3];
    assign COMxA = control_reg[6:5];
    assign CSx = control_reg[9:7];
    assign FOCxB = control_reg[10];
    assign FOCxA = control_reg[11];

    assign int_reg_in[0] = TOVx;
    assign int_reg_in[1] = OCFxB;
    assign int_reg_in[2] = OCFxA;
    TIFRx TIFRx(clk, timer_clk, rst, TIFRx_L, data, int_reg, int_reg_in);
	
    OCRxn OCRxA(clk, rst, OCRxA_L, data, compA_top);
    OCRxn OCRxB(clk, rst, OCRxB_L, data, compB_top);

    //for external clock functionality that doesn't work yet
    //clk_sel_div clk_sel_div(clk, int_clk, CSx, rst, timer_en, clk_src, ext_clk_edge);
    //ext_clk_edge_detector ext_clk_edge_detector(ext_clk, ext_clk_det, ext_clk_edge);
    //assign timer_clk = clk_src ? ext_clk_det : int_clk;

    clk_sel_div clk_sel_div(clk, timer_clk, CSx, rst, timer_en, clk_src, ext_clk_edge);

    TCNTx TCNTx(clk, timer_clk, dir, timer_clear|rst, timer_en, rst, TCNTx_L, data,  timer_value);
    
    pwm_reg pwm_a(clk, timer_clk, rst, pwm_control_a, OCxA);
    pwm_reg pwm_b(clk, timer_clk, rst, pwm_control_b, OCxB);

    timer_control timer_control(clk, timer_clk, rst, dir, timer_clear, timer_value, WGMx, COMxA, COMxB, FOCxA, FOCxB, compA_top, compB_top, TOVx, OCFxA, OCFxB, pwm_control_a, pwm_control_b);

endmodule

//TCCRx - timer control register - auto reset FOCxn bits functionality
module TCCRx(clk, timer_clk, rst, load, D, Q);
    input clk, timer_clk, rst, load;
    input [11:0] D;
    output reg [11:0] Q;
    
    //check both clocks
    always @(negedge clk or posedge timer_clk) begin
        if(clk == 1'b0) begin //clk is negedge
            if(rst) Q <= 11'b0;
            else if(load) Q <= D;
        end
        else if(timer_clk == 1'b1) begin //timer_clk is posedge
            Q[11] <= 1'b0; //automatically clear FOCxn
            Q[10] <= 1'b0;
            Q[9:0] <= Q[9:0];
        end
    end
endmodule

//OCRxn - output compare register(s) - just a normal reg
module OCRxn(clk, rst, load, D, Q);
    input clk, rst, load;
    input [63:0] D;
    output reg [63:0] Q;
    
    always @(negedge clk) begin
        if(rst) Q <= 64'b0;
        else if(load) Q <= D;
    end
endmodule

//TIFRx - timer interrupt flag register - internal set functionality
module TIFRx(clk, timer_clk, rst, load, D, Q, int_reg_in);
    input clk, timer_clk, rst, load;
    input [2:0] int_reg_in;
    input [63:0] D;
    output reg [2:0] Q;
    
    //check both clocks
    always @(negedge clk or posedge timer_clk) begin
        if(clk == 1'b0) begin //clk is negedge
            if(rst) Q <= 3'b0;
            else if(load) Q <= D[2:0];
        end
        if(timer_clk == 1'b1) begin //timer_clk is posedge
            Q <= int_reg_in;
        end
    end
endmodule

//TCNTx - timer counter register - internal clear and inc/dec functionality
module TCNTx(clk, timer_clk, dir, clear, timer_en, rst, load, D, Q);
    input clk, timer_clk, dir, clear, rst, load, timer_en;
    input [63:0] D;
    output reg [63:0] Q;

    //check both clocks
    always @(negedge clk or posedge timer_clk) begin
        if(clk == 1'b0) begin //clk is negedge
            if(rst) Q <= 64'b0;
            else if(load) Q <= D;
        end
        if(timer_clk == 1'b1) begin //timer_clk is posedge
            if(clear) Q <= 64'b0;
            else begin
                if(dir) Q <= Q + 1'b1;
                else Q <= Q - 1'b1;
            end
        end
    end
endmodule

//pwm_reg - stores OCxn bits - not memory addressable, meant to be connected
//to an I/O pin
module pwm_reg(clk, timer_clk, rst, control, Q);
    input clk, timer_clk, rst;
    input [1:0] control;
    output reg Q;

    //check both clocks
    always@(negedge clk or posedge timer_clk) begin
        if(clk == 1'b0) begin //clk is negedge
            if(rst) Q <= 1'b0;
        end
        if(timer_clk == 1'b1) begin //timer_clk is posedge
            case(control) //set bit OCxn bit based on control signal
                2'b00: Q <= 1'b0;
                2'b01: Q <= 1'b1;
                2'b10: Q <= ~Q;
                2'b11: Q <= Q;
            endcase 
        end
    end
endmodule

//timer controller block - all combinational logic
module timer_control(clk, timer_clk, rst, dir, clear, timer_value, WGMx, COMxA, COMxB, FOCxA, FOCxB, OCRxA, OCRxB, TOVx, OCFxA, OCFxB, pwm_control_a, pwm_control_b);
    input clk, timer_clk, rst, FOCxA, FOCxB;
    input [1:0] COMxA, COMxB;
    input [2:0] WGMx;
    input [63:0] timer_value, OCRxA, OCRxB;
    output reg dir, clear, TOVx, OCFxA, OCFxB;
    output reg [1:0] pwm_control_a, pwm_control_b;

    always @* begin
        //do compare and set output compare flag bits
        if(timer_value == OCRxA)
            OCFxA <= 1'b1;
        else
            OCFxA <= 1'b0;
        if(timer_value == OCRxB)
            OCFxB <= 1'b1;
        else
            OCFxB <= 1'b0;

        //set pwm control bits for one COMxn possibility pertaining to all
        //modes
        if(COMxA == 2'b00)
            pwm_control_a <= 2'b00;
        if(COMxB == 2'b00)
            pwm_control_b <= 2'b00;

        //normal/CTC modes
        if(WGMx == 3'b000 || WGMx == 3'b001) begin
            dir <= 1'b1;
            if(WGMx == 3'b000) begin //normal mode, top=0xFF
                if(timer_value == 64'hFFFFFFFFFFFFFFFF) begin
                    clear <= 1'b1;
                    TOVx <= 1'b1;
                end
                else begin
                    clear <= 1'b0;
                    TOVx <= 1'b0;
                end
            end
            else if(WGMx == 3'b001) begin //CTC mode, top=OCRxA
                if(timer_value == OCRxA) begin
                    clear <= 1'b1;
                    TOVx <= 1'b1;
                end
                else begin
                    clear <= 1'b0;
                    TOVx <= 1'b0;
                end
            end

            //do compare and set pwm_a control bits based on COMxA, or if
            //compare is forced (FOCxn)
            if(timer_value == OCRxA || FOCxA) begin
                case(COMxA)
                    2'b01: pwm_control_a <= 2'b10; //toggle OCxA
                    2'b10: pwm_control_a <= 2'b00; //OCxA <= 0
                    2'b11: pwm_control_a <= 2'b01; //OCxA <= 1
                    default: pwm_control_a <= 2'b00;
                endcase
            end
            else if(timer_clk == 1'b0 && COMxA == 2'b01) //if in toggle mode, set to do nothing to ensure toggle happens exactly once
                pwm_control_a <= 2'b11; //OCxA does nothing
            
            //same for pwm_b
            if(timer_value == OCRxB || FOCxB) begin
                case(COMxB)
                    2'b01: pwm_control_b <= 2'b10; 
                    2'b10: pwm_control_b <= 2'b00;
                    2'b11: pwm_control_b <= 2'b01;
                    default: pwm_control_b <= 2'b00;
                endcase
            end
            else if(timer_clk == 1'b0 && COMxA == 2'b01)
                pwm_control_b <= 2'b11;
        end

        //PWM modes
        if(WGMx == 3'b010 || WGMx == 3'b011) begin
            if(WGMx == 3'b010) begin //PWM, top=0xFF
                if(timer_value == 64'hFFFFFFFFFFFFFFFF) begin
                    dir <= 1'b0;
                end
                else if(timer_value == 64'b0) begin
                    dir <= 1'b1;
                    TOVx <= 1'b1;
                end
                else
                    TOVx <= 1'b0;
            end
            else if(WGMx == 3'b011) begin //PWM, top=OCRxA
                if(timer_value == OCRxA) begin
                    dir <= 1'b0;
                end
                else if(timer_value == 64'b0) begin
                    dir <= 1'b1;
                    TOVx <= 1'b1;
                end
                else
                    TOVx <= 1'b0;
            end
            
            //do compare and set pwm_a control bits based on COMxA
            if(timer_value == OCRxA) begin
                case(COMxA)
                    2'b01: begin
                        if(WGMx == 3'b011) pwm_control_a <= 2'b10; //toggle OCxA
                        else pwm_control_a <= 2'b00; //OCxA <= 0
                    end
                    2'b10: begin //clear if timer is increasing, set if timer is decreasing
                        if(dir) pwm_control_a <= 2'b00; 
                        else pwm_control_a <= 2'b01;
                    end
                    2'b11: begin //set if timer is increasing, clear if timer is decreasing
                        if(dir) pwm_control_a <= 2'b01;
                        else pwm_control_a <= 2'b00;
                    end
                    default: pwm_control_a <= 2'b00;
                endcase
            end
            else if(timer_clk == 1'b0 && COMxA == 2'b01 && WGMx == 3'b011) //if in toggle mode, set to do nothing to ensure toggle happens exactly once
                pwm_control_a <= 2'b11;

            //same for pwm_b except it cannot toggle
            if(timer_value == OCRxB) begin
                case(COMxB)
                    2'b01: pwm_control_b <= 2'b00;
                    2'b10: begin
                        if(dir) pwm_control_b <= 2'b00;
                        else pwm_control_b <= 2'b01;
                    end
                    2'b11: begin
                        if(dir) pwm_control_b <= 2'b01;
                        else pwm_control_b <= 2'b00;
                    end
                    default: pwm_control_b <= 2'b00;
                endcase
            end
            
        end
    end

endmodule

//clock selector and divider
module clk_sel_div(clk_in, clk_out, clk_select, rst, clk_en, clk_src, ext_clk_edge);
    input clk_in, rst;
    input [2:0] clk_select;
    output clk_out;
    output reg clk_en; //0=disabled, 1=enabled
    output reg clk_src; //0=internal, 1=external
    output reg ext_clk_edge; //0=falling, 1=rising

    reg [10:0] prescaler;
    //reg clk_src; //0=internal, 1=external
    reg clk_same; //is timer_clk same as clk
    //reg ext_clk_edge; //0=falling, 1=rising

    always @(clk_select) begin
        case(clk_select)
            3'b000: begin 
                clk_en <= 1'b0;
                clk_same <= 1'b0;
                clk_src <= 1'b0;
                prescaler <= 11'd1;
                ext_clk_edge <= 1'b0;
            end
            3'b001: begin
                clk_en <= 1'b1;
                clk_same <= 1'b1;
                clk_src <= 1'b0;
                prescaler <= 11'd1;
                ext_clk_edge <= 1'b0;
            end
            3'b010: begin
                clk_en <= 1'b1;
                clk_same <= 1'b0;
                clk_src <= 1'b0;
                prescaler <= 11'd8;
                ext_clk_edge <= 1'b0;
            end
            3'b011: begin
                clk_en <= 1'b1;
                clk_same <= 1'b0;
                clk_src <= 1'b0;
                prescaler <= 11'd64;
                ext_clk_edge <= 1'b0;
            end
            3'b100: begin
                clk_en <= 1'b1;
                clk_same <= 1'b0;
                clk_src <= 1'b0;
                prescaler <= 11'd256;
                ext_clk_edge <= 1'b0;
            end
            3'b101: begin
                clk_en <= 1'b1;
                clk_same <= 1'b0;
                clk_src <= 1'b0;
                prescaler <= 11'd1024;
                ext_clk_edge <= 1'b0;
            end
            3'b110: begin //DO NOT USE, for external clock mode that doesn't work yet
                clk_en <= 1'b1;
                clk_same <= 1'b0;
                clk_src <= 1'b1;
                prescaler <= 11'd1;
                ext_clk_edge <= 1'b0;
            end
            3'b111: begin //DO NOT USE, for external clock mode that doesn't work yet
                clk_en <= 1'b1;
                clk_same <= 1'b0;
                clk_src <= 1'b1;
                prescaler <= 11'd1;
                ext_clk_edge <= 1'b1;
            end
        endcase
    end
    
    reg clk_dvd; //divided clock
    assign clk_out = clk_same ? clk_in : clk_dvd; //if clk is same as timer_clk, set clk_out to clk_in, otherwise set it do the divided clock

    reg [10:0] count;
    wire [10:0] divider = prescaler / 2'd2 - 1'b1;

    initial
        clk_dvd <= 1'b0;

    //clock divider -  basically just a counter
    always @(posedge clk_in or posedge rst) begin
        if(rst) begin
            count <= 11'b0;
            clk_dvd <= 1'b0;
        end
        else if(clk_en && !clk_same && !clk_src) begin
            if(count == divider) begin
                count <= 11'b0;
                clk_dvd <= ~clk_dvd;
            end
            else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule

module ext_clk_edge_detector(ext_clk, clk_out, ext_clk_edge);
    input ext_clk, ext_clk_edge;
    output clk_out;

    reg clk_out_pos, clk_out_neg;

    initial begin
        clk_out_pos <= 1'b0;
        clk_out_neg <= 1'b0;
    end

    always @(posedge ext_clk)
        clk_out_pos <= ~clk_out_pos;
    
    always @(negedge ext_clk)
        clk_out_neg <= ~clk_out_neg;

    assign clk_out = ext_clk_edge ? clk_out_pos : clk_out_neg;

endmodule

//determines if address corresponds to the timer - currently unused,
//AddressDetect is used instead
module address_select(address, base_address, address_en);
    input [31:0] address, base_address;
    output reg address_en;

    always @* begin
        if(address[31:3] == base_address[31:3])
            address_en = 1'b1;
        else
            address_en = 1'b0;
    end
endmodule

//register write selector - selects which register load signal is 1 based on
//lower 3 bits of address
module reg_write_sel(address, address_en, write_en, TCCRx_address, TCNTx_address, OCRxA_address, OCRxB_address, TIFRx_address, reg_select_word);
	input [31:0] address, TCCRx_address, TCNTx_address, OCRxA_address, OCRxB_address, TIFRx_address;
    input address_en, write_en;
	output reg [4:0] reg_select_word;
	
	/* reg_select_word:
	0: TCCRx
	1: TCNTx
	2: OCRxA
	3: OCRxB
	4: TIFRx*/
	
    always @* begin
        if(address_en && write_en) begin
		    case(address)
			    TCCRx_address: reg_select_word <= 5'b00001;
			    TCNTx_address: reg_select_word <= 5'b00010;
			    OCRxA_address: reg_select_word <= 5'b00100;
			    OCRxB_address: reg_select_word <= 5'b01000;
			    TIFRx_address: reg_select_word <= 5'b10000;
                default: reg_select_word <= 5'b00000;
		    endcase
        end
        else
            reg_select_word <= 5'b00000;
	end
endmodule

//register read selector - selects which register should be read from and sets
//data to it based on lower 3 bits of address
module reg_read_sel(address, address_en, read_en, data, TCCRx_address, TCNTx_address, OCRxA_address, OCRxB_address, TIFRx_address, TCCRx, TCNTx, OCRxA, OCRxB, TIFRx);
    input [31:0] address, TCCRx_address, TCNTx_address, OCRxA_address, OCRxB_address, TIFRx_address;
    input address_en, read_en;
    input [63:0] TCCRx, TCNTx, OCRxA, OCRxB, TIFRx;
    output reg [63:0] data;

    always @* begin
        if(address_en && read_en) begin
            case(address)
			    TCCRx_address: data <= TCCRx;
			    TCNTx_address: data <= TCNTx;
			    OCRxA_address: data <= OCRxA;
			    OCRxB_address: data <= OCRxB;
			    TIFRx_address: data <= TIFRx;
                default: data <= 64'bz;
		    endcase
        end
        else
            data <= 64'bz;
    end
endmodule

