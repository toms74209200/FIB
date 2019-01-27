-- =====================================================================
--  Title		: Fibonacci function
--
--  File Name	: FIB.vhd
--  Project		: Sample
--  Block		:
--  Tree		:
--  Designer	: toms74209200
--  Created		: 2019/01/19
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FIB is
	generic(
		AW			: integer := 16;								-- Address width 
		DW			: integer := 32									-- Data width
		
	);
	port(
	-- System --
		nRST		: in	std_logic;							--(n) Reset
		CLK			: in	std_logic;							--(p) Clock

	-- Control --
		CS			: in	std_logic;							--(p) Chip select
		RD			: in	std_logic;							--(p) Bus master read
		WR			: in	std_logic;							--(p) Bus master write
		ADDR		: in	std_logic_vector(AW-1 downto 0);	--(p) Bus address
		RDAT		: out	std_logic_vector(DW-1 downto 0);	--(p) Bus read data
		WDAT		: in	std_logic_vector(DW-1 downto 0);	--(p) Bus write data
	
	-- Register address --
		CtrlAddr	: in	std_logic_vector(AW-1 downto 0);	-- Control register address
		DataAddr	: in	std_logic_vector(AW-1 downto 0)		-- Data register address
		);
end FIB;

architecture RTL of FIB is

-- Register data --
signal	ctrl_reg	: std_logic_vector(DW-1 downto 0);			-- Control register data
signal	data_reg	: std_logic_vector(DW-1 downto 0);			-- Data register data

-- Internal signals --
signal	null_i		: std_logic_vector(DW-1 downto 0);			-- null
signal	frst_trm	: std_logic_vector(DW-1 downto 0);			-- Fibonacci first term
signal	sum			: std_logic_vector(DW-1 downto 0);			-- F_n
signal	reg1		: std_logic_vector(DW-1 downto 0);			-- F_n-1
signal	reg2		: std_logic_vector(DW-1 downto 0);			-- F_n-2

signal	arg_n		: std_logic_vector(7 downto 0);				-- Argument n
signal	reg_rst		: std_logic;								-- Register reset
signal	over_flow	: std_logic;								-- Bit over flow assert
signal	go_i		: std_logic;								-- Calculation start
signal	done_i		: std_logic;								-- Calculation done flag
signal	ena_i		: std_logic;								-- Calculation enable
signal	cnt			: std_logic_vector(arg_n'range);			-- Calculation count

begin
--
-- ***********************************************************
--	First term definition
-- ***********************************************************
null_i <= (others => '0');
frst_trm <= null_i + 1;


-- ***********************************************************
--	Fibonacci calculation
-- ***********************************************************
sum <= reg1 + reg2;


process (CLK, nRST) begin
	if (nRST = '0') then
		reg1 <= (others => '0');
		reg2 <= (others => '0');
	elsif (CLK'event and CLK = '1') then
		if (reg_rst = '1') then
			reg1 <= frst_trm;
			reg2 <= (others => '0');
		elsif (go_i = '1') then
			reg1 <= frst_trm;
			reg2 <= (others => '0');
		elsif (ena_i = '1') then
			if (done_i = '1') then
				reg1 <= reg1;
				reg2 <= reg2;
			else
				reg1 <= sum;
				reg2 <= reg1;
			end if;
		end if;
	end if;
end process;


-- ***********************************************************
--	Argument write
-- ***********************************************************
process (CLK, nRST) begin
	if (nRST = '0') then
		arg_n <= (others => '0');
	elsif (CLK'event and CLK = '1') then
		if (reg_rst = '1') then
			arg_n <= (others => '0');
		elsif (CS = '1' and WR = '1' and ADDR = CtrlAddr) then
			arg_n <= WDAT(15 downto 8);
		end if;
	end if;
end process;


-- ***********************************************************
--	Register reset
-- ***********************************************************
reg_rst <= WDAT(2) when (CS = '1' and WR = '1' and ADDR = CtrlAddr) else '0';


-- ***********************************************************
--	Bit over flow assert
-- ***********************************************************
process (CLK, nRST) begin
	if (nRST = '0') then
		over_flow <= '0';
	elsif (CLK'event and CLK = '1') then
		if (reg_rst = '1') then
			over_flow <= '0';
		elsif (go_i = '1') then
			over_flow <= '0';
		elsif (reg1(reg1'left) = '1' and reg2(reg2'left) = '1') then
			over_flow <= '1';
		end if;
	end if;
end process;


-- ***********************************************************
--	Calculation start
-- ***********************************************************
go_i <= WDAT(0) when (CS = '1' and WR = '1' and ADDR = CtrlAddr) else '0';


-- ***********************************************************
--	Calculation done flag
-- ***********************************************************
done_i <= '0' when (go_i = '1') else
		  '1' when (cnt = arg_n - 1) else
		  '1' when (arg_n = 0) else
		  '0';


-- ***********************************************************
--	Calculation enable
-- ***********************************************************
process (CLK, nRST) begin
	if (nRST = '0') then
		ena_i <= '0';
	elsif (CLK'event and CLK = '1') then
		if (reg_rst = '1') then
			ena_i <= '0';
		elsif (done_i = '1') then
			ena_i <= '0';
		elsif (go_i = '1') then
			ena_i <= '1';
		end if;
	end if;
end process;


-- ***********************************************************
--	Calculation count
-- ***********************************************************
process (CLK, nRST) begin
	if (nRST = '0') then
		cnt <= (others => '0');
	elsif (CLK'event and CLK = '1') then
		if (reg_rst = '1') then
			cnt <= (others => '0');
		elsif (go_i = '1') then
			cnt <= (others => '0');
		elsif (ena_i = '1') then
			if (done_i = '1') then
				cnt <= cnt;
			else
				cnt <= cnt + 1;
			end if;
		end if;
	end if;
end process;


-- ***********************************************************
--	Contorl regiser
-- ***********************************************************
ctrl_reg <= (X"0000" & arg_n & B"0000_00" & over_flow & done_i)
			when (CS = '1' and RD = '1' and ADDR = CtrlAddr) else (others => '0');


-- ***********************************************************
--	Data regiser
-- ***********************************************************
data_reg <= reg1
			when (CS = '1' and RD = '1' and ADDR = DataAddr) else (others => '0');


-- ***********************************************************
--	Register read
-- ***********************************************************
RDAT <= ctrl_reg or data_reg;


end RTL;	-- FIB
