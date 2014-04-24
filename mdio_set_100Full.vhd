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

entity mdio_set_100Full is
    Port ( clk 		:  in  STD_LOGIC;
           rst 		:  in  STD_LOGIC;
           mdio_op 	: out  STD_LOGIC;
           mdio_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           data_i 	:  in  STD_LOGIC_VECTOR (15 downto 0);
           data_o 	: out  STD_LOGIC_VECTOR (15 downto 0);
           mdio_busy :  in  STD_LOGIC;
           mdio_kick : out  STD_LOGIC;
			  
			  mnl_addr	:	in	 STD_LOGIC_VECTOR (4 downto 0);
			  mnl_trgr	:	in	 STD_LOGIC;
			  cfg_busy	: out	 STD_LOGIC);
end mdio_set_100Full;

architecture Behavioral of mdio_set_100Full is
	type state_t is (wait_rdy, write_caps, read_status, check_status, retry, done);
	-- wait rdy
	-- write abilities
	-- loop reading autoneg done
	-- restart autoneg, go back one
	-- Initial setting to kick off state machine
	signal state			: state_t	:= wait_rdy;
	signal trgt				: state_t	:= write_caps;
	
	signal NEXT_state, NEXT_trgt	: state_t;
begin
	cfg_busy <= '0' when state = done else '1';

	fsm: process (state, mdio_busy, data_i, trgt, mnl_addr, mnl_trgr)
	begin
		NEXT_state	<= state;
		NEXT_trgt	<= trgt;
		mdio_op		<= '0';
		mdio_addr	<= ( others => '0' );
		mdio_kick	<= '0';
		data_o		<= ( others => '0' );
		
		case state is
			when wait_rdy =>
				if mdio_busy = '0' then
					NEXT_state	<= trgt;
				end if;
				
			when write_caps =>
				NEXT_state	<= wait_rdy;
				NEXT_trgt	<= read_status;
				
				mdio_op		<= '1';
				mdio_addr	<= b"00100";
				data_o		<= X"0181";
				mdio_kick	<= '1';
				
			when read_status =>
				NEXT_state	<= wait_rdy;
				NEXT_trgt	<= check_status;
				
				mdio_op		<= '0';
				mdio_addr	<= b"11111";
				mdio_kick	<= '1';
				
			when check_status =>
				if data_i(12) = '0' then -- autoneg not done
					NEXT_state	<= read_status;
				else
					if data_i(4 downto 2) = b"110" then
						NEXT_state <= done;
					else
						NEXT_state <= retry;
					end if;
				end if;
			
			when retry =>
				NEXT_state	<= wait_rdy;
				NEXT_trgt	<= read_status;
				
				mdio_op		<= '1';
				mdio_addr	<= b"00000";
				data_o		<= X"8000";
				mdio_kick	<= '1';
							
			when done =>
				mdio_addr	<= mnl_addr;
				mdio_kick	<= mnl_trgr;
								
		end case;
	end process;

	fsm_next: process (clk)
	begin
		if RISING_EDGE(clk) then
			state <= NEXT_state;
			trgt	<= NEXT_trgt;
			
			if rst = '1' then
				state <= wait_rdy;
				trgt	<=	write_caps;
			end if;
		end if;
	end process;

end Behavioral;

