library ieee;
use ieee.std_logic_1164.all;

entity input_sampler is
	generic (
		SAMPLE_FREQ: integer := 10_000_000
	);
	port(
		i_clk : in std_logic;
		i_rst : in std_logic;
		i_ena : in std_logic;
		i_inp : in std_logic_vector(7 downto 0);
		o_outp: out std_logic_vector(7 downto 0);
		o_outp_ready: out std_logic
	);
end entity;

architecture synchronizer of input_sampler is
	constant N: integer := 50_000_000/SAMPLE_FREQ + 2;
	signal clk_div: integer range 0 to (50_000_000/SAMPLE_FREQ + 2);
	signal q0, q1: std_logic_vector(7 downto 0);
begin
	process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			clk_div <= N;
			o_outp <= (others => '0');
			o_outp_ready <= '0';
		elsif rising_edge(i_clk) then
			o_outp_ready <= '0';
			if i_ena = '1' then
				clk_div <= clk_div - 1;
				if clk_div = N-2 then
					q0 <= i_inp;
				elsif clk_div = 2 then
					q1 <= q0;
				elsif clk_div = 1 then
					clk_div <= N;
					o_outp <= q1;
					o_outp_ready <= '1';
				end if;
			end if;
		end if;
	end process;
	
end architecture;