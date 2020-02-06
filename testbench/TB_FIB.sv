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

`define MessageOK(variable) \
$messagelog("%:S %:F(%:L) OK:Assertion %:O.", "Note", `__FILE__, `__LINE__, variable);
`define MessageERROR(variable) \
$messagelog("%:S %:F(%:L) ERROR:Assertion %:O failed.", "Error", `__FILE__, `__LINE__, variable);
`define ChkValue(variable, value) \
    if ((variable)===(value)) \
        `MessageOK(variable) \
    else \
        `MessageERROR(variable)

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
    fibonacci_data_rom[3]  = 32'd2;
    fibonacci_data_rom[4]  = 32'd3;
    fibonacci_data_rom[5]  = 32'd5;
    fibonacci_data_rom[6]  = 32'd8;
    fibonacci_data_rom[7]  = 32'd13;
    fibonacci_data_rom[8]  = 32'd21;
    fibonacci_data_rom[9]  = 32'd34;
    fibonacci_data_rom[10] = 32'd55;
    fibonacci_data_rom[11] = 32'd89;
    fibonacci_data_rom[12] = 32'd144;
    fibonacci_data_rom[13] = 32'd233;
    fibonacci_data_rom[14] = 32'd377;
    fibonacci_data_rom[15] = 32'd610;
    fibonacci_data_rom[16] = 32'd987;
    fibonacci_data_rom[17] = 32'd1597;
    fibonacci_data_rom[18] = 32'd2584;
    fibonacci_data_rom[19] = 32'd4181;
    fibonacci_data_rom[20] = 32'd6765;
    fibonacci_data_rom[21] = 32'd10946;
    fibonacci_data_rom[22] = 32'd17711;
    fibonacci_data_rom[23] = 32'd28657;
    fibonacci_data_rom[24] = 32'd46368;
    fibonacci_data_rom[25] = 32'd75025;
    fibonacci_data_rom[26] = 32'd121393;
    fibonacci_data_rom[27] = 32'd196418;
    fibonacci_data_rom[28] = 32'd317811;
    fibonacci_data_rom[29] = 32'd514229;
    fibonacci_data_rom[30] = 32'd832040;
    fibonacci_data_rom[31] = 32'd1346269;
    fibonacci_data_rom[32] = 32'd2178309;
    fibonacci_data_rom[33] = 32'd3524578;
    fibonacci_data_rom[34] = 32'd5702887;
    fibonacci_data_rom[35] = 32'd9227465;
    fibonacci_data_rom[36] = 32'd14930352;
    fibonacci_data_rom[37] = 32'd24157817;
    fibonacci_data_rom[38] = 32'd39088169;
    fibonacci_data_rom[39] = 32'd63245986;
    fibonacci_data_rom[40] = 32'd102334155;
    fibonacci_data_rom[41] = 32'd165580141;
    fibonacci_data_rom[42] = 32'd267914296;
    fibonacci_data_rom[43] = 32'd433494437;
    fibonacci_data_rom[44] = 32'd701408733;
    fibonacci_data_rom[45] = 32'd1134903170;
    fibonacci_data_rom[46] = 32'd1836311903;
    fibonacci_data_rom[47] = 32'd2971215073;
end


/*=============================================================================
 * Signal initialization
 *============================================================================*/
initial begin
    ASI_VALID = 1'b0;
    ASI_DATA = 32'd0;

    #(ResetTime);
    @(posedge CLK);

/*=============================================================================
 * Normal data check
 *============================================================================*/
    $display("%0s(%0d)Normal data check", `__FILE__, `__LINE__);
    for (int i=1;i<48;i++) begin
        wait(ASI_READY);
        ASI_VALID = 1'b1;
        ASI_DATA = i;
        @(posedge CLK);
        ASI_VALID = 1'b0;
        @(posedge CLK);
        wait(ASO_VALID);
        assert (ASO_DATA == fibonacci_data_rom[i])
            $display("%0s(%0d)OK:Assertion ASO_DATA = %0d.", `__FILE__, `__LINE__, fibonacci_data_rom[i]);
        else
            $error("%0s(%0d)ERROR:Assertion ASO_DATA = %0d failed. ASO_DATA = %0d.", `__FILE__, `__LINE__, fibonacci_data_rom[i], ASO_DATA);
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
    assert (ASO_DATA == 1)
            $display("%0s(%0d)OK:Assertion ASO_DATA = %0d.", `__FILE__, `__LINE__, 1);
        else
            $error("%0s(%0d)ERROR:Assertion ASO_DATA = %0d failed. ASO_DATA = %0d.", `__FILE__, `__LINE__, 1, ASO_DATA);
        @(posedge CLK);

    wait(ASI_READY);
    ASI_VALID = 1'b1;
    ASI_DATA = 48;
    @(posedge CLK);
    ASI_VALID = 1'b0;
    @(posedge CLK);
    wait(ASO_VALID);
    assert (ASO_ERROR == 1'b1)
            $display("%0s(%0d)OK:Assertion ASO_ERROR = %0d.", `__FILE__, `__LINE__, 1'b1);
        else
            $error("%0s(%0d)ERROR:Assertion ASO_ERROR = %0d failed. ASO_ERROR = %0d.", `__FILE__, `__LINE__, 1'b1, ASO_ERROR);
    @(posedge CLK);

    wait(ASI_READY);
    ASI_VALID = 1'b1;
    ASI_DATA = 9'h100;
    @(posedge CLK);
    ASI_VALID = 1'b0;
    @(posedge CLK);
    wait(ASO_VALID);
    assert (ASO_ERROR == 1'b1)
            $display("%0s(%0d)OK:Assertion ASO_ERROR = %0d.", `__FILE__, `__LINE__, 1'b1);
        else
            $error("%0s(%0d)ERROR:Assertion ASO_ERROR = %0d failed. ASO_ERROR = %0d.", `__FILE__, `__LINE__, 1'b1, ASO_ERROR);
    @(posedge CLK);

    $finish;
end

endmodule
// TB_FIB
