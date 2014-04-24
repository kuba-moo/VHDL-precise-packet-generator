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

entity mdio is
    Port ( clk 	: in  STD_LOGIC;
           rst 	: in  STD_LOGIC;
			  cnt_5  : in  STD_LOGIC;
			  cnt_23 : in  STD_LOGIC;
           mdc 	: out STD_LOGIC;
           mdio_i	: in  STD_LOGIC;
			  mdio_o	: out STD_LOGIC;
			  mdio_t	: out STD_LOGIC;
           data 	: in  STD_LOGIC_VECTOR (7 downto 0);
           digit 	: out STD_LOGIC_VECTOR (15 downto 0);
           trgr 	: in  STD_LOGIC);
end mdio;

architecture Behavioral of mdio is
	-- MDC is driven by cnt5 (period: 640ns, edge: 320ns | min: 400/180ns)
	-- state changes happen on MDC falling edge
	-- Operation:
	--   1. after each reset wait for at least 50ms (84ms)
	--   2. wait for command -> trgr to go high

	type state_t is  (wait_rst_done_b1, -- wait for cnt_23 to go high
							wait_rst_done_b0, -- wait for cnt_23 to go low
						--	wait_rst_done_b2, -- wait for cnt_23 to go high
							init,					-- exec init sequence
							idle,					-- do nothing, wait for command
							preable,				-- preable	-> 32x '1'
							start_of_frame,	-- sof		-> 	0 1
							op_code,				-- opcode	-> 	1 0 read; 0 1 write
							phy_addr,			-- phy_addr -> 5x 0
							reg_addr,			-- reg_addr -> 5x b
							turn_around,
							read_in);

	constant init_stream 		: STD_LOGIC_VECTOR(0 to 63) := 
   --		 sfd+wr  phy addr(5), reg addr(5), ta(2)
	--	  preamb  \/|| value
	   X"FFFFffff50100181"; --"00" "FFFFffff50003300";
	
	signal state, next_state	: state_t := wait_rst_done_b1;
	signal cnt, next_cnt			: INTEGER range 0 to 255;
	signal value, next_value	: STD_LOGIC_VECTOR(0 to 15);
	
	-- 'mdio_i' value latched on rising edge of MDC 
	-- (falling edge, when state transitions is too far - PHY holds value for 300ns)
	signal mdio_value				: STD_LOGIC;

	signal MDIO_clk, prev_MDIO_clk	: STD_LOGIC := '0';

begin
	digit <= value;

	-- Async state machine
	fsm: process (next_state, state, next_cnt, cnt, mdio_i, trgr, cnt_23, value, data)
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
					next_state	<= init;
				end if;
				
--			when wait_rst_done_b2 =>
--				if cnt_23 = '0' then
--					next_state	<= init;
--					next_cnt		<= 0;
--				end if;
				
			when init =>
				mdio_o <= init_stream(cnt);
			
				if (cnt = init_stream'right) then
					next_state 	<= idle;
					next_cnt		<= 0;					
				end if;
				
			when idle =>
				if trgr = '1' then
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
				mdio_o <= not CONV_std_logic_vector(cnt, 1)(0);
				
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
				mdio_o <= data(4 - cnt);
				
				if cnt = 4 then
					next_state	<= turn_around;	
					next_cnt		<= 0;		
				end if;
				
			when turn_around =>
				mdio_o <= 'Z';
				mdio_t <= '1';
				
				if CONV_std_logic_vector(cnt, 1)(0) = '1' then
					next_state	<= read_in;	
					next_cnt		<= 0;		
				end if;
				
			when read_in =>
				mdio_o <= 'Z';
				mdio_t <= '1';
				next_value(cnt) <= mdio_value;
				
				if cnt = 15 then
					next_state	<= idle;	
				end if;
			
		end case;
	end process;

	fsm_next: process (clk)
	begin
		if RISING_EDGE(clk) then
			if MDIO_clk = '0' and prev_MDIO_clk = '1' then
				state <= next_state;
				cnt 	<= next_cnt;
				value <= next_value;
			end if;
			
			if MDIO_clk = '1' and prev_MDIO_clk = '0' then
				mdio_value <= mdio_i;
			end if;
			
			if rst = '1' then
				state <= wait_rst_done_b1;
				cnt	<= 0;
				value <= ( others => '1' );
			end if;
		end if;
	end process;


	-- Genearate clock
	MDIO_clk <= cnt_5;
	prev_MDIO_clk <= cnt_5 when RISING_EDGE(clk);
	mdc <= MDIO_clk;

end Behavioral;

