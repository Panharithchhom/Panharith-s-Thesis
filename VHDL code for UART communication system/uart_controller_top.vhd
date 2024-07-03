library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_controller_top is
	port(
		CLOCK_50_B5B: in std_logic;
		CPU_RESET_n : in std_logic;
		
		KEY         : in std_logic_vector(3 downto 0);
		SW          : in std_logic_vector(9 downto 0);
		LEDR        : out std_logic_vector(7 downto 0);
		
		UART_TX: out std_logic;
		UART_RX: in std_logic
	);
end entity;

architecture top of uart_controller_top is
	signal baud_ena : std_logic;
	signal load, busy, rx_ready, tx: std_logic;
	signal din, dout: std_logic_vector(7 downto 0);
	signal clk, rst: std_logic;
	
begin
	
	-- input assignments
	clk <= CLOCK_50_B5B;
	rst <= not CPU_RESET_n;
	
	-- output assignments
	UART_TX <= tx;
	LEDR(7 downto 0) <= dout when rising_edge(clk) and rx_ready = '1';
	
	inst_baud_gen_0: entity work.baud_gen
	port map(
		i_clk => clk,
		i_rst => rst,
		o_baud_ena => baud_ena
	);
	
	inst_uart_controller_0: entity work.uart_controller
	port map(
		-- tx ports
		i_clk => clk,
		i_ena => baud_ena,
		i_rst => rst,
		i_load => load,
		i_din => din,
		o_tx => tx,
		o_tx_busy => open,
		
		-- rx ports
		i_rx => UART_RX,
		o_rx_err => open,
		o_rx_ready => rx_ready,
		o_dout => dout
	);
		
	inst_input_sample_0: entity work.input_sampler
	generic map (SAMPLE_FREQ => 2)
	port map(
		i_clk => clk,
		i_rst => rst,
		i_ena => SW(9),
		i_inp => SW(7 downto 0),
		o_outp => din,
		o_outp_ready => load
	);
		
end architecture;