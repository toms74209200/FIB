-- ============================================================================
--  Title       : Fibonacci function
--
--  File Name   : FIB.vhd
--  Project     : Sample
--  Block       :
--  Tree        :
--  Designer    : toms74209200 <https://github.com/toms74209200>
--  Created     : 2019/01/19
--  Copyright   : 2019 toms74209200
--  License     : MIT License.
--                http://opensource.org/licenses/mit-license.php
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FIB is
    generic(
        DW              : integer := 32                             -- Data width
    );
    port(
    -- System --
        RESET_n         : in    std_logic;                          --(n) Reset
        CLK             : in    std_logic;                          --(p) Clock

    -- Control --
        ASI_READY       : out   std_logic;                          --(p) Avalon-ST sink data ready
        ASI_VALID       : in    std_logic;                          --(p) Avalon-ST sink data valid
        ASI_DATA        : in    std_logic_vector(DW-1 downto 0);    --(p) Avalon-ST sink data
        ASO_VALID       : out   std_logic;                          --(p) Avalon-ST source data valid
        ASO_DATA        : out   std_logic_vector(DW-1 downto 0);    --(p) Avalon-ST source data
        ASO_ERROR       : out   std_logic                           --(p) Avalon-ST source error
        );
end FIB;

architecture RTL of FIB is

-- Internal signals --
signal  null_i      : std_logic_vector(DW-1 downto 0);              -- null
signal  first_term  : std_logic_vector(DW-1 downto 0);              -- Fibonacci first term
signal  sum         : std_logic_vector(DW   downto 0);              -- F_n
signal  reg1        : std_logic_vector(DW-1 downto 0);              -- F_n-1
signal  reg2        : std_logic_vector(DW-1 downto 0);              -- F_n-2

signal  calc_n      : std_logic_vector(5 downto 0);                 -- Calculation end count N
signal  n_over      : std_logic;                                    -- Count N overflow
signal  over_check  : std_logic_vector(DW-1 downto 0);              -- Overflow check value
signal  over_flow   : std_logic;                                    -- Bit overflow assert
signal  start_i     : std_logic;                                    -- Calculation start
signal  done_i      : std_logic;                                    -- Calculation done flag
signal  busy_i      : std_logic;                                    -- Calculation enable
signal  cnt         : std_logic_vector(calc_n'range);               -- Calculation count

begin
--
-- ============================================================================
--  First term definition
-- ============================================================================
null_i <= (others => '0');
first_term <= null_i + 1;


-- ============================================================================
--  Fibonacci calculation
-- ============================================================================
sum <= ('0' & reg1) + ('0' & reg2);

process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        reg1 <= (others => '0');
        reg2 <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (busy_i = '0' and ASI_VALID = '1') then
            reg1 <= first_term;
            reg2 <= (others => '0');
        elsif (start_i = '1') then
            reg1 <= first_term;
            reg2 <= (others => '0');
        elsif (busy_i = '1') then
            if (done_i = '1') then
                reg1 <= reg1;
                reg2 <= reg2;
            else
                reg1 <= sum(reg1'range);
                reg2 <= reg1;
            end if;
        end if;
    end if;
end process;

ASO_DATA <= reg1;


-- ============================================================================
--  Calculation end count
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        calc_n <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (busy_i = '0' and ASI_VALID = '1') then
            calc_n <= ASI_DATA(calc_n'range);
        end if;
    end if;
end process;

process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        n_over <= '0';
    elsif (CLK'event and CLK = '1') then
        if (busy_i = '0' and ASI_VALID = '1') then
            if (ASI_DATA > X"3F") then
                n_over <= '1';
            else
                n_over <= '0';
            end if;
        end if;
    end if;
end process;


-- ============================================================================
--  Bit over flow assert
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        over_flow <= '0';
    elsif (CLK'event and CLK = '1') then
        if (start_i = '1') then
            over_flow <= '0';
        elsif (sum(sum'left) = '1') then
            over_flow <= '1';
        end if;
    end if;
end process;

ASO_ERROR <= over_flow or n_over;


-- ============================================================================
--  Calculation start
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        start_i <= '0';
    elsif (CLK'event and CLK = '1') then
        if (busy_i = '0') then
            start_i <= ASI_VALID;
        end if;
    end if;
end process;


-- ============================================================================
--  Calculation end
-- ============================================================================
done_i <= '0' when (start_i = '1') else
          '1' when (cnt = calc_n - 1) else
          '1' when (calc_n = 0) else
          '0';

ASO_VALID <= done_i;


-- ============================================================================
--  Calculation enable
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        busy_i <= '0';
    elsif (CLK'event and CLK = '1') then
        if (done_i = '1') then
            busy_i <= '0';
        elsif (start_i = '1') then
            busy_i <= '1';
        end if;
    end if;
end process;

ASI_READY <= not busy_i;


-- ============================================================================
--  Calculation count
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        cnt <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (start_i = '1') then
            cnt <= (others => '0');
        elsif (busy_i = '1') then
            if (done_i = '1') then
                cnt <= cnt;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end if;
end process;


end RTL;    -- FIB