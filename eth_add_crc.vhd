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

--------------------------------------------------------------------------------
-- Csum calculations (the big XOR mapping) copied from:
-- CRC GENERATOR
--
-- @author Peter A Bennett
-- @copyright (c) 2012 Peter A Bennett
-- @version $Rev: 2 $
-- @lastrevision $Date: 2012-03-11 15:19:25 +0000 (Sun, 11 Mar 2012) $
-- @license LGPL
-- @email pab850@googlemail.com
-- @contact www.bytebash.com
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Ethernet CRC module
-- 	Calculate and append CRC of data flowing through Bus
-- 	Data must begin with 802.3 Preamble + SFD, CRC calc start on first byte after SFD
-- 	CRC is glued after data, Pkt signal is continuous
--
-- WARNING: Pkt signal must be (and is kept) continuous

entity eth_add_crc is
    Port ( Clk			:  in  STD_LOGIC;
           Rst 		:  in  STD_LOGIC;
           InPkt 		:  in  STD_LOGIC;
           InData 	:  in  STD_LOGIC_VECTOR (7 downto 0);
           OutPkt		: out  STD_LOGIC;
           OutData	: out  STD_LOGIC_VECTOR (7 downto 0));
end eth_add_crc;

architecture Behavioral of eth_add_crc is

	type state_t is (IDLE, CALC, APPEND);

	signal state					: state_t; 
	signal NEXT_state				: state_t;
	
	signal c, csum, NEXT_csum	: STD_LOGIC_VECTOR (0 to 31);
	signal SHIFT_csum				: STD_LOGIC_VECTOR (0 to 31);
	signal d							: STD_LOGIC_VECTOR (0 to  7);
	
	signal cnt,	NEXT_cnt 		: integer range 0 to 3;
begin
	c <= csum;
	d <= InData;
					
	fsm: process (state, cnt, InData, InPkt, d, c, csum, SHIFT_csum)
	begin		
		SHIFT_csum(0)  <= d(6) xor d(0) xor c(24) xor c(30);
		SHIFT_csum(1)  <= d(7) xor d(6) xor d(1) xor d(0) xor c(24) xor c(25) xor c(30) xor c(31);
		SHIFT_csum(2)  <= d(7) xor d(6) xor d(2) xor d(1) xor d(0) xor c(24) xor c(25) xor c(26) xor c(30) xor c(31);
		SHIFT_csum(3)  <= d(7) xor d(3) xor d(2) xor d(1) xor c(25) xor c(26) xor c(27) xor c(31);
		SHIFT_csum(4)  <= d(6) xor d(4) xor d(3) xor d(2) xor d(0) xor c(24) xor c(26) xor c(27) xor c(28) xor c(30);
		SHIFT_csum(5)  <= d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(24) xor c(25) xor c(27) xor c(28) xor c(29) xor c(30) xor c(31);
		SHIFT_csum(6)  <= d(7) xor d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30) xor c(31);
		SHIFT_csum(7)  <= d(7) xor d(5) xor d(3) xor d(2) xor d(0) xor c(24) xor c(26) xor c(27) xor c(29) xor c(31);
		SHIFT_csum(8)  <= d(4) xor d(3) xor d(1) xor d(0) xor c(0) xor c(24) xor c(25) xor c(27) xor c(28);
		SHIFT_csum(9)  <= d(5) xor d(4) xor d(2) xor d(1) xor c(1) xor c(25) xor c(26) xor c(28) xor c(29);
		SHIFT_csum(10) <= d(5) xor d(3) xor d(2) xor d(0) xor c(2) xor c(24) xor c(26) xor c(27) xor c(29);
		SHIFT_csum(11) <= d(4) xor d(3) xor d(1) xor d(0) xor c(3) xor c(24) xor c(25) xor c(27) xor c(28);
		SHIFT_csum(12) <= d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor d(0) xor c(4) xor c(24) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30);
		SHIFT_csum(13) <= d(7) xor d(6) xor d(5) xor d(3) xor d(2) xor d(1) xor c(5) xor c(25) xor c(26) xor c(27) xor c(29) xor c(30) xor c(31);
		SHIFT_csum(14) <= d(7) xor d(6) xor d(4) xor d(3) xor d(2) xor c(6) xor c(26) xor c(27) xor c(28) xor c(30) xor c(31);
		SHIFT_csum(15) <= d(7) xor d(5) xor d(4) xor d(3) xor c(7) xor c(27) xor c(28) xor c(29) xor c(31);
		SHIFT_csum(16) <= d(5) xor d(4) xor d(0) xor c(8) xor c(24) xor c(28) xor c(29);
		SHIFT_csum(17) <= d(6) xor d(5) xor d(1) xor c(9) xor c(25) xor c(29) xor c(30);
		SHIFT_csum(18) <= d(7) xor d(6) xor d(2) xor c(10) xor c(26) xor c(30) xor c(31);
		SHIFT_csum(19) <= d(7) xor d(3) xor c(11) xor c(27) xor c(31);
		SHIFT_csum(20) <= d(4) xor c(12) xor c(28);
		SHIFT_csum(21) <= d(5) xor c(13) xor c(29);
		SHIFT_csum(22) <= d(0) xor c(14) xor c(24);
		SHIFT_csum(23) <= d(6) xor d(1) xor d(0) xor c(15) xor c(24) xor c(25) xor c(30);
		SHIFT_csum(24) <= d(7) xor d(2) xor d(1) xor c(16) xor c(25) xor c(26) xor c(31);
		SHIFT_csum(25) <= d(3) xor d(2) xor c(17) xor c(26) xor c(27);
		SHIFT_csum(26) <= d(6) xor d(4) xor d(3) xor d(0) xor c(18) xor c(24) xor c(27) xor c(28) xor c(30);
		SHIFT_csum(27) <= d(7) xor d(5) xor d(4) xor d(1) xor c(19) xor c(25) xor c(28) xor c(29) xor c(31);
		SHIFT_csum(28) <= d(6) xor d(5) xor d(2) xor c(20) xor c(26) xor c(29) xor c(30);
		SHIFT_csum(29) <= d(7) xor d(6) xor d(3) xor c(21) xor c(27) xor c(30) xor c(31);
		SHIFT_csum(30) <= d(7) xor d(4) xor c(22) xor c(28) xor c(31);
		SHIFT_csum(31) <= d(5) xor c(23) xor c(29);

		NEXT_state		<= state;
		NEXT_cnt			<= cnt + 1;
		NEXT_csum		<= SHIFT_csum;
		
		OutData			<= InData;
		OutPkt			<=	InPkt;	
	
		case state is
			when IDLE =>
				NEXT_csum		<= X"FFffFFff";
				if InPkt = '1' and InData(7 downto 4) = X"d" then
					NEXT_state	<= CALC;
				end if;
		
			when CALC =>
				NEXT_cnt			<= 0;
				
				if InPkt = '0' then
					NEXT_state	<= APPEND;
					
					NEXT_cnt		<= 1;
					OutPkt		<= '1';	
					NEXT_csum	<= csum;				
					OutData		<= not csum(24 to 31);
				end if;
			
			when APPEND =>
				NEXT_csum		<= csum;
				
				OutData			<= not csum(24 - cnt*8 to 31 - cnt*8);
				OutPkt			<= '1';
		
				if cnt = 3 then
					NEXT_state	<= IDLE;
				end if;			
			
			when others =>
				NEXT_state	<= IDLE;
			
		end case;
	end process;
	
	fsm_next: process (Clk)
	begin
		if RISING_EDGE(Clk) then
			state 	<= NEXT_state;
			cnt		<= NEXT_cnt;
			csum		<= NEXT_csum;
			
			if rst = '1' then
				state <= IDLE;
			end if;
		end if;
	end process;


end Behavioral;

