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

entity mem_reader is
    Port ( Clk 		:  in  STD_LOGIC;
           Rst 		:  in  STD_LOGIC;
			  Enable		:	in	 STD_LOGIC;
			  
			  FrameLen	: 	in	 STD_LOGIC_VECTOR(10 downto 0);
			  FrameIval	:	in	 STD_LOGIC_VECTOR(27 downto 0);
			  
			  MemAddr	: out  STD_LOGIC_VECTOR (10 downto 0);
			  MemData	:  in  STD_LOGIC_VECTOR (7 downto 0);
			  
           BusPkt	 	: out  STD_LOGIC;
           BusData 	: out  STD_LOGIC_VECTOR (7 downto 0));
end mem_reader;

architecture Behavioral of mem_reader is
	
	signal time_cnt, NEXT_time_cnt	: STD_LOGIC_VECTOR(27 downto 0)	:= ( others => '0' );
	
begin
	NEXT_time_cnt	<= time_cnt + 1;
	
	MemAddr		<= time_cnt(10 downto 0);
	BusData		<= MemData;

	counter : process (Clk)
		variable frameSent	: STD_LOGIC	:= '0';
		variable saveEna		: STD_LOGIC	:= '0';
	begin
		if RISING_EDGE(Clk) then
			time_cnt			<= NEXT_time_cnt;
			BusPkt			<= '0';
			
			if time_cnt(10 downto 0) < FrameLen and frameSent = '0' then
				BusPkt		<= saveEna;
			else
				frameSent	:= '1';
			end if;
			
			if rst = '1' or NEXT_time_cnt >= FrameIval then
				time_cnt		<= ( others => '0' );
				frameSent	:= '0';
				saveEna		:= Enable;
			end if;
		end if;
	end process;

end Behavioral;

