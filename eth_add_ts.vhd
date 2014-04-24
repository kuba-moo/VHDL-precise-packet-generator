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

entity eth_add_ts is
    Port ( Clk 		:  in  STD_LOGIC;
           Rst 		:  in  STD_LOGIC;
           Cnt64 		:  in  STD_LOGIC_VECTOR (63 downto 0);
           InPkt 		:  in  STD_LOGIC;
           InData 	:  in  STD_LOGIC_VECTOR (7 downto 0);
           OutPkt 	: out  STD_LOGIC;
           OutData 	: out  STD_LOGIC_VECTOR (7 downto 0));
end eth_add_ts;

architecture Behavioral of eth_add_ts is

begin

	main: process (Clk)
		variable delayPkt		: STD_LOGIC;
		variable delayData	: STD_LOGIC_VECTOR(7 downto 0);
		
		variable saveCnt64	: STD_LOGIC_VECTOR (63 downto 0);
		variable write_out	: STD_LOGIC := '0';
		variable write_cnt	: integer range 0 to 7;
	begin
		if RISING_EDGE(Clk) then
			OutPkt	<= delayPkt;
			OutData	<= delayData;
		
			if write_out = '1' then
				OutPkt	<= '1';
				OutData	<= saveCnt64(63 - write_cnt*8 downto 56 - write_cnt*8);				
				
				if write_cnt = 7 then 
					write_out := '0';
				end if;
				write_cnt := write_cnt + 1;
			end if;
		
			if delayPkt = '1' and InPkt = '0' then
				saveCnt64	:= Cnt64;
				write_out	:= '1';
				write_cnt	:= 0;
			end if;
		
			delayPkt			:= InPkt;
			delayData		:= InData;
			
			if rst = '1' then
				write_out	:= '0';
			end if;
		end if;
	end process;

end Behavioral;

