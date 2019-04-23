/**
 * 16-bit Timer Peripheral by Thomas Schofield
 *
 * Features:
 * 3 Registers - PERIODX, TCONX, TIMERX
 * 
 * PERIODX:
 * Address - 16 relative to the base address 
 * EX: 32'h80000010
 * Description - Holds a 16-bit value that acts as a maximum (if passed, count will reset to zero)
 *
 * TCONX:
 * Address - 8 relative to the base address
 * EX: 32'h80000008
 * Description - Holds an 8-bit value, where only the lower three bits are used
 * Bit 0 - Enable (1) / Disable (0) Timer
 * Bit 1 - 1 if timer passed period / overflowed
 * Bit 2 - Enables or disables resetting the counter based on the period
 * Bit 3 - Resets the counter and timer_conditions_out
 *
 * TMRX:
 * Address - 0 relative to the base address
 * EX: 32'h80000000;
 * Description - 16-bit counter with period and reset checks from TCONX
 */

module Timer_TS (data, address, mem_write, mem_read, size, clock, reset);
    parameter BASE_ADDR = 32'h80000000; // Can be set when the timer is initialized
    localparam ADDR_WIDTH = 8; // The timer will always use only one hex digit of address space

    inout [63:0] data;
    input [31:0] address;
    input mem_write, mem_read;
    input [1:0] size; // 00 - 8-bit, 01 - 16-bit, 10 - 32-bit, 11 - 64-bit
    input clock, reset;

    wire chip_select;

    AddressDetect detect_timer (address, chip_select);
    defparam detect_timer.base_address = BASE_ADDR;
    defparam detect_timer.address_mask = 32'hFFFFFFFF << ADDR_WIDTH;

    Timer16bit timer (data, address[ADDR_WIDTH-1:0], chip_select, mem_read, mem_write, size, clock, reset);
    defparam timer.ADDR_WIDTH = ADDR_WIDTH;

endmodule

module Timer16bit (data, address, chip_select, mem_read, mem_write, size, clock, reset);
    parameter ADDR_WIDTH = 8;

    inout [63:0] data;
    input [ADDR_WIDTH-1:0] address;
    input chip_select, mem_write, mem_read;
    input [1:0] size; // 00 - 8-bit, 01 - 16-bit, 10 - 32-bit, 11 - 64-bit
    input clock, reset;

    wire [15:0] period;
    wire [15:0] count;
    
    wire [7:0] conditions;

    wire [63:0] data_out;
    Mux4to1Nbit data_mux (
        .F(data_out),
        .S(address[4:3]),
        .I0({ 48'b0, count }),
        .I1({ 56'b0, conditions }),
        .I2({ 48'b0, period }),
        .I3(64'bz)
    );
    defparam data_mux.N = 64;
    assign data = (chip_select & mem_read & ~mem_write) ? data_out : 64'bz;

    wire period_load;
    assign period_load = (address[4:3] == 2'b10 && chip_select && mem_write && ~mem_read) ? 1'b1 : 1'b0;
                       // Q, D, L, R, clock
    RegisterNbit PERIODX (period, data[15:0], period_load, reset, clock);
    defparam PERIODX.N = 16;
    
    wire [7:0] conditions_in;
    wire [7:0] timer_conditions_out;
    assign conditions_in = (address[4:3] == 2'b01 && chip_select && mem_write && ~mem_read) ? data[7:0] : timer_conditions_out;

    /**
     * List of different conditions:
     * conditions[0] - TCONX.ON: Enable or disable the timer
     * conditions[1] - TCONX.FLAG: Flag to indicate that the timer rolled over
     * conditions[2] - TCONX.USE_PERIOD: Enables or disables period checking
     * conditions[3] - TCONX.RESET: Resets the counter and timer_conditions_out
     */

    RegisterNbit TCONX (conditions, conditions_in, 1'b1, reset, ~clock);
    defparam TCONX.N = 8;

    Counter16bit TMRX (count, period, timer_conditions_out, conditions, clock, reset);
endmodule

module Counter16bit (count, period, conditions_out, conditions, clk, rst);
    output reg [15:0] count;
    output reg [7:0] conditions_out;
    input [7:0] conditions;
    
    input [15:0] period;
    
    input clk, rst;

    reg [15:0] previous_value;

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            count <= 0;
            conditions_out <= 0;
        end
        else if (conditions[3]) begin
            count <= 0;
            conditions_out <= 0;
        end
        else begin
            previous_value <= count;
            if (conditions[0]) begin
                for (i = 0; i < 8; i = i + 1) begin
                    /**
                     * This for block mainly just prevents the flag from returning to zero if it encounters an unusual case.
                     * Allows the condition bits to pass through.
                     */
                    if (i == 1 && conditions[1] == 1'b1)
                        conditions_out[i] <= 1;
                    else begin 
                        conditions_out[i] <= conditions[i];
                    end
                end
                count <= count + 1;
                if (count[15] != previous_value[15]) begin
                    // Checks for overflow
                    conditions_out[1] <= 1;
                end
                if (conditions[2] && (count >= period)) begin
                    // Checks for period
                    count <= 0;
                    conditions_out[1] <= 1;
                end
            end
            else begin
                count <= count;
            end
        end
    end
endmodule
