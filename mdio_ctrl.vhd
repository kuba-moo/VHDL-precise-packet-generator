-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>
--
-- Copyright (C) 2014 Jakub Kicinski <kubakici@wp.pl>

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Theory of operation:
-- 1. set input values
-- 2. wait for busy to go '0'
-- 3. set kick to '1'
-- 4. wait for busy to go '0'; for reads data_o is valid on the same clock; for writes MDIO is done

entity mdio_ctrl is
    Port ( clk		:  in STD_LOGIC;
           rst		:  in STD_LOGIC;
			  -- counter bits
			  cnt_5  :  in STD_LOGIC;
			  cnt_23 :  in STD_LOGIC;
           -- external I/O
			  mdc 	: out STD_LOGIC;
           mdio_i	:  in STD_LOGIC;
			  mdio_o	: out STD_LOGIC;
			  mdio_t	: out STD_LOGIC;
			  -- client interface
			  op		:  in STD_LOGIC;							 -- '0' - read; '1' - write
			  addr	:  in STD_LOGIC_VECTOR( 4 downto 0); -- address of register
			  data_i	:  in STD_LOGIC_VECTOR(15 downto 0); -- register value for write
			  data_o	: out STD_LOGIC_VECTOR(15 downto 0); -- register value for read
			  busy	: out STD_LOGIC;							 -- core is busy
			  kick	:  in STD_LOGIC							 -- start processing the operation
			  );
end mdio_ctrl;

architecture Behavioral of mdio_ctrl is
	-- MDC is driven by cnt5 (period: 640ns, edge: 320ns | min: 400/180ns)
	-- state changes happen on MDC falling edge
	-- Operation:
	--   1. after each reset wait for at least 50ms (we wait at least 84ms - cnt_23)
	--   2. wait for command -> kick to go high

	type state_t is  (wait_rst_done_b1, -- wait for cnt_23 to go high
							wait_rst_done_b0, -- wait for cnt_23 to go low
							idle,					-- do nothing, wait for command
							preable,				-- preable	-> 32x '1'
							start_of_frame,	-- sof		-> 	0 1
							op_code,				-- opcode	-> 	1 0 read; 0 1 write
							phy_addr,			-- phy_addr -> 5x 0
							reg_addr,			-- reg_addr -> 5x b
							turn_around,
							read_in,				
							write_out);

	signal state, next_state	: state_t := wait_rst_done_b1;
	signal cnt,   next_cnt		: integer range 0 to 31;
	signal value, next_value	: STD_LOGIC_VECTOR(0 to 15);
	
	-- 'mdio_i' value latched on rising edge of MDC 
	-- (state transitions on falling edge which is too far - PHY holds value for 300ns only)
	signal bit_in					: STD_LOGIC;
	-- detection of falling edge of MDC
	signal MDIO_clk, prev_MDIO_clk	: STD_LOGIC := '0';

	-- latched inputs
	signal m_op		: STD_LOGIC;
	signal m_addr	: STD_LOGIC_VECTOR(0 to 4);  -- swap direction here to make it easier
	signal m_data	: STD_LOGIC_VECTOR(0 to 15); --   to iterate over the vector with cnt
	signal m_kick	: STD_LOGIC;
	
begin	
	busy 		<= '0' when state = idle and m_kick = '0' else '1';
	data_o 	<= value;

	-- Async state machine
	NEXT_fsm: process (next_state, state, next_cnt, cnt, mdio_i, cnt_23, value, bit_in,
							 m_kick, m_op, m_addr, m_data)
	begin
		mdio_o 		<= '0';
		mdio_t 		<= '0';
		next_state	<= state;
		next_cnt		<= cnt + 1;
		next_value	<= value;
				
		case state is
			when wait_rst_done_b1 =>
				if cnt_23 = '1' then
					next_state	<= wait_rst_done_b0;
				end if;
				
			when wait_rst_done_b0 =>
				if cnt_23 = '0' then
					next_state	<= idle;
				end if;
				
			when idle =>
				if m_kick = '1' then
					next_state 	<= preable;
					next_cnt		<= 0;
				end if;
				
			when preable =>
				if cnt = 31 then
					next_state	<= start_of_frame;
					next_cnt		<= 0;
				end if;
			
				mdio_o <= '1';
				
			when start_of_frame =>
				mdio_o <= CONV_std_logic_vector(cnt, 1)(0);
				
				if CONV_std_logic_vector(cnt, 1)(0) = '1' then
					next_state	<= op_code;	
					next_cnt		<= 0;				
				end if;
				
			when op_code =>
				mdio_o <= not m_op xor CONV_std_logic_vector(cnt, 1)(0);
				
				if CONV_std_logic_vector(cnt, 1)(0) = '1' then
					next_state	<= phy_addr;	
					next_cnt		<= 0;				
				end if;
				
			when phy_addr =>
				mdio_o <= '0';
				
				if cnt = 4 then
					next_state	<= reg_addr;	
					next_cnt		<= 0;				
				end if;
				
			when reg_addr =>
				mdio_o <= m_addr(cnt);
				
				if cnt = 4 then
					next_state	<= turn_around;	
					next_cnt		<= 0;		
				end if;
				
			when turn_around =>
				mdio_o <= 'Z';
				mdio_t <= '1';
				
				if CONV_std_logic_vector(cnt, 1)(0) = '1' then
					if m_op = '0' then
						next_state	<= read_in;
					else 
						next_state <= write_out;	
					end if;
					next_cnt		<= 0;	
				end if;
				
			when read_in =>
				mdio_o <= 'Z';
				mdio_t <= '1';
				next_value(cnt) <= bit_in;
				
				if cnt = 15 then
					next_state	<= idle;	
				end if;
						
			when write_out =>
				mdio_o <= m_data(cnt);
				
				if cnt = 15 then
					next_state	<= idle;	
				end if;	
		end case;
	end process;

	fsm: process (clk)
	begin
		if RISING_EDGE(clk) then
			if state = idle and kick = '1' then
				m_op		<= op;
				m_addr	<= addr;
				m_data	<= data_i;
				m_kick	<= '1';
			end if;
			
			if MDIO_clk = '0' and prev_MDIO_clk = '1' then
				state 	<= next_state;
				cnt 		<= next_cnt;
				value 	<= next_value;
				m_kick	<= '0';
			end if;
			
			if MDIO_clk = '1' and prev_MDIO_clk = '0' then
				bit_in <= mdio_i;
			end if;
			
			if rst = '1' then
				state <= wait_rst_done_b1;
				cnt	<= 0;
			end if;
		end if;
	end process;


	-- Genearate clock
	MDIO_clk <= cnt_5;
	prev_MDIO_clk <= cnt_5 when RISING_EDGE(clk);
	mdc <= MDIO_clk;
	
end Behavioral;

