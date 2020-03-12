/*=============================================================================
 * Title        : Fibonacci function testbench
 *
 * File Name    : TB_FIB.sv
 * Project      : 
 * Block        : 
 * Tree         : 
 * Designer     : toms74209200 <https://github.com/toms74209200>
 * Created      : 2020/01/29
 * License      : MIT License.
                  http://opensource.org/licenses/mit-license.php
 *============================================================================*/

`timescale 1ns/1ns

`define Comment(sentence) \
$display("%0s(%0d) %0s.", `__FILE__, `__LINE__, sentence)
`define MessageOK(name, value) \
$display("%0s(%0d) OK:Assertion %0s = %0d.", `__FILE__, `__LINE__, name, value)
`define MessageERROR(name, variable, value) \
$error("%0s(%0d) ERROR:Assertion %0s = %0d failed. %0s = %0d", `__FILE__, `__LINE__, name, value, name, variable)
`define ChkValue(name, variable, value) \
    if ((variable)===(value)) \
        `MessageOK(name, value); \
    else \
        `MessageERROR(name, variable, value);

module TB_FIB ;

// Simulation module signal
bit         RESET_n;            //(n) Reset
bit         CLK;                //(p) Clock
bit         ASI_READY = 0;      //(p) Avalon-ST sink data ready
bit         ASI_VALID = 0;      //(p) Avalon-ST sink data valid
bit [31:0]  ASI_DATA  = 0;      //(p) Avalon-ST sink data
bit         ASO_VALID;          //(p) Avalon-ST source data valid
bit [31:0]  ASO_DATA;           //(p) Avalon-ST source data
bit         ASO_ERROR;          //(p) Avalon-ST source error

// Parameter
parameter ClkCyc    = 10;       // Signal change interval(10ns/50MHz)
parameter ResetTime = 20;       // Reset hold time

// Data rom
bit [31:0] fibonacci_data_rom[1:47];

// module
FIB U_FIB(
.*,
.ASI_READY(ASI_READY),
.ASI_VALID(ASI_VALID),
.ASI_DATA(ASI_DATA),
.ASO_VALID(ASO_VALID),
.ASO_DATA(ASO_DATA),
.ASO_ERROR(ASO_ERROR)
);

/*=============================================================================
 * Clock
 *============================================================================*/
always begin
    #(ClkCyc);
    CLK = ~CLK;
end


/*=============================================================================
 * Reset
 *============================================================================*/
initial begin
    #(ResetTime);
    RESET_n = 1;
end 


/*=============================================================================
 * ROM
 *============================================================================*/
initial begin
    fibonacci_data_rom[1]  = 32'd1;
    fibonacci_data_rom[2]  = 32'd1;
    for (int i=3;i<=47;i++) begin
        fibonacci_data_rom[i] = fibonacci_data_rom[i-1] + fibonacci_data_rom[i-2];
    end
end


/*=============================================================================
 * Signal initialization
 *============================================================================*/
initial begin
    #(ResetTime);
    @(posedge CLK);

/*=============================================================================
 * Normal data check
 *============================================================================*/
    `Comment("Normal data check");
    for (int i=1;i<48;i++) begin
        wait(ASI_READY);
        ASI_VALID = 1'b1;
        ASI_DATA = i;
        @(posedge CLK);
        ASI_VALID = 1'b0;
        @(posedge CLK);
        wait(ASO_VALID);
        `ChkValue("ASO_DATA", ASO_DATA, fibonacci_data_rom[i]);
        @(posedge CLK);
    end

/*=============================================================================
 * Error check
 *============================================================================*/
    $display("%0s(%0d)Error check", `__FILE__, `__LINE__);
    wait(ASI_READY);
    ASI_VALID = 1'b1;
    ASI_DATA = 0;
    @(posedge CLK);
    ASI_VALID = 1'b0;
    @(posedge CLK);
    wait(ASO_VALID);
    `ChkValue("ASO_DATA", ASO_DATA, 64'd1);
    @(posedge CLK);

    wait(ASI_READY);
    ASI_VALID = 1'b1;
    ASI_DATA = 49;
    @(posedge CLK);
    ASI_VALID = 1'b0;
    @(posedge CLK);
    wait(ASO_VALID);
    `ChkValue("ASO_ERROR", ASO_ERROR, 1'b1);
    @(posedge CLK);

    wait(ASI_READY);
    ASI_VALID = 1'b1;
    ASI_DATA = 9'h100;
    @(posedge CLK);
    ASI_VALID = 1'b0;
    @(posedge CLK);
    wait(ASO_VALID);
    `ChkValue("ASO_ERROR", ASO_ERROR, 1'b1);
    @(posedge CLK);

    $finish;
end

endmodule
// TB_FIB
