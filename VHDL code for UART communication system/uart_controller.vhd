library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_controller is
	port(
		-- tx ports
		i_clk     : in std_logic;
		i_ena     : in std_logic;
		i_rst     : in std_logic;
		i_load    : in std_logic;
		i_din     : in std_logic_vector(7 downto 0);
		o_tx      : out std_logic;
		o_tx_busy : out std_logic;
		
		-- rx ports
		i_rx      : in std_logic;
		o_rx_err  : out std_logic;
		o_rx_ready: out std_logic;
		o_dout 	 : out std_logic_vector(7 downto 0)
	);
end entity;

architecture reg_mealy_fsm of uart_controller is
	-- tx signals
	signal tx_reg: std_logic_vector(8 downto 0);
	signal tx_bit_cnt: integer range 0 to 9;
	signal reg_din: std_logic_vector(7 downto 0);
	signal tx_ena: std_logic;
	signal tx_div: integer range 0 to 15;
	
	type tx_state_type is (IDLE, LOAD_TX, SHIFT_TX, STOP_TX);
	signal tx_state: tx_state_type;
	
	-- rx signals
	signal rx_ready: std_logic;
	signal rx_reg: std_logic_vector(7 downto 0);
	signal rx_bit_cnt: integer range 0 to 10;
	signal rx_rst: std_logic;
	signal rx_ena: std_logic;
	signal rx_div: integer range 0 to 7;
	
	type rx_state_type is (IDLE, START_RX, EDGE_RX, SHIFT_RX, STOP_RX, OVF_RX);
	signal rx_state: rx_state_type;
begin
	-- tx clock generation
	process(i_rst, i_clk)
	begin
		if i_rst = '1' then
			tx_ena <= '0';
			tx_div <= 0;
		elsif rising_edge(i_clk) then
			tx_ena <= '0';
			if i_ena = '1' then
				if tx_div = 15 then
					tx_div <= 0;
					tx_ena <= '1';
				else
					tx_div <= tx_div + 1;
				end if;
			end if;
		end if;
	end process;

	-- tx fsm
	o_tx <= tx_reg(0);
	
	tx_fsm: process(i_rst, i_clk)
	begin
		if i_rst = '1' then
			tx_reg <= (others => '1');
			tx_bit_cnt <= 0;
			tx_state <= IDLE;
			o_tx_busy <= '0';
			reg_din <= (others => '0');
		elsif rising_edge(i_clk) then
			o_tx_busy <= '1';
			
			case tx_state is
				when IDLE =>
					if i_load = '1' then
						reg_din <= i_din;
						o_tx_busy <= '1';
						tx_state <= LOAD_TX;
					else
						o_tx_busy <= '0';
					end if;
					
				when LOAD_TX =>
					if tx_ena = '1' then
						tx_state <= SHIFT_TX;
						tx_bit_cnt <= 0;
						tx_reg <= reg_din & '0';
					end if;
					
				when SHIFT_TX =>
					if tx_ena = '1' then
						tx_bit_cnt <= tx_bit_cnt + 1;
						tx_reg <= '1' & tx_reg(tx_reg'high downto 1);
						if tx_bit_cnt = 8 then
							tx_state <= STOP_TX;
						end if;
					end if;
					
				when STOP_TX =>
					if tx_ena = '1' then
						tx_state <= IDLE;
					end if;
				when others =>
					tx_state <= IDLE;
			end case;
		end if;
	end process;
	
	-- rx clock generation
	process(i_rst, i_clk)
	begin
		if i_rst = '1' then
			rx_ena <= '0';
			rx_div <= 0;
		elsif rising_edge(i_clk) then
			rx_ena <= '0';
			if rx_rst = '1' then
				rx_div <=0;
			elsif i_ena = '1' then
				if rx_div = 7 then
					rx_div <= 0;
					rx_ena <= '1';
				else
					rx_div <= rx_div + 1;
				end if;
			end if;
		end if;
	end process;
	
	-- rx_fsm
	o_rx_ready <= rx_ready;

	rx_fsm: process(i_rst, i_clk)
	begin
		if i_rst = '1' then
			rx_reg <= (others => '0');
			rx_bit_cnt <= 0;
			rx_state <= IDLE;
			rx_rst <= '0';
			rx_ready <= '0';
			o_rx_err <= '0';
			o_dout <= (others => '0');
		elsif rising_edge(i_clk) then
			rx_rst <= '0';
			
			if rx_ready = '1' then
				o_rx_err <= '0';
				rx_ready <= '0';
			end if;
			
			case rx_state is
				when IDLE =>
					rx_bit_cnt <= 0;
					if i_ena = '1' then
						if i_rx = '0' then
							rx_state <= START_RX;
							rx_rst <= '1';
						end if;
					end if;
				
				when START_RX =>
					if rx_ena = '1' then
						if i_rx = '1' then
							rx_state <= OVF_RX;
						else
							rx_state <= EDGE_RX;
						end if;
					end if;
				
				when EDGE_RX =>
					if rx_ena = '1' then
						if rx_bit_cnt = 8 then
							rx_state <= STOP_RX;
						else
							rx_state <= SHIFT_RX;
						end if;
					end if;
				
				when SHIFT_RX =>
					if rx_ena = '1' then
						rx_bit_cnt <= rx_bit_cnt + 1;
						rx_reg <= i_rx & rx_reg(rx_reg'high downto 1);
						rx_state <= EDGE_RX;
					end if;
				
				when STOP_RX =>
					if rx_ena = '1' then
						o_dout <= rx_reg;
						rx_ready <= '1';
						rx_state <= IDLE;
					end if;
				
				when OVF_RX =>
					o_rx_err <= '1';
					if i_rx = '1' then
						rx_state <= IDLE;
					end if;
				
				when others =>
					rx_state <= IDLE;
			end case;
		end if;
	end process;
end architecture;