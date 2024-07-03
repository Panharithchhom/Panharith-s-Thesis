library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen is
	generic(BAUD_RATE : integer := 9600);
	port(
		i_clk : in std_logic;
		i_rst : in std_logic;
		o_baud_ena: out std_logic
		
	);
end entity;

architecture behavior of baud_gen is
	constant DIVISOR : integer := 50_000_000/16/BAUD_RATE;
	signal baud_div : integer range 0 to DIVISOR;
begin
-- baud clock generation
	process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			baud_div <= 0;
		elsif rising_edge(i_clk) then
			o_baud_ena <= '0';
			baud_div <= baud_div + 1;
			if baud_div = DIVISOR - 1 then
				o_baud_ena <= '1';
				baud_div <= 0;
			end if;
		end if;
	end process;
end architecture;