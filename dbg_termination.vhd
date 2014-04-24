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

entity dbg_termination is
    Port ( clk 	: in  STD_LOGIC;
           rst 	: in  STD_LOGIC;
           data 	: in  STD_LOGIC_VECTOR (7 downto 0);
           pkt 	: in  STD_LOGIC;
           desc 	: in  STD_LOGIC;
           sw 		: in  STD_LOGIC_VECTOR (7 downto 0);
           led 	: out STD_LOGIC_VECTOR(1 downto 0);
           value 	: out STD_LOGIC_VECTOR(15 downto 0));
end dbg_termination;

architecture Behavioral of dbg_termination is
	signal ctrl, oldPkt : STD_LOGIC;
begin
	ctrl <=	pkt when sw(7) = '0'
				else desc;
	oldPkt	<= pkt when RISING_EDGE(clk);

	bothTest : process (clk)
		variable prev : STD_LOGIC := '0';
	begin
		if RISING_EDGE(clk) then
			prev := prev or (pkt and desc);
			led(0) <= prev;
			
			if rst = '1' then
				prev := '0';
			end if;
		end if;
	end process;

	zeroTest : process (clk)
		variable prev : STD_LOGIC := '0';
	begin
		if RISING_EDGE(clk) then
--			if desc = '1' and data = "00000000" then
			if pkt = '1' and sw = "1111" then
				prev := '1';
			else
				prev := prev;
			end if;
			led(1) <= prev;
			
			if rst = '1' then
				prev := '0';
			end if;
		end if;
	end process;

	main: process (clk)
		variable cnt : STD_LOGIC_VECTOR(7 downto 0);
	begin
		if RISING_EDGE(clk) then
			if ctrl = '1' then
				if cnt(7 downto 1) = sw(6 downto 0) then
					if cnt(0) = '0' then
						value(15 downto 8) <= data;
					else
						value(7 downto 0) <= data;
					end if;
				end if;
				
				cnt := cnt + 1;
			end if;		
						
			if oldPkt = '1' and pkt = '0' then
   			cnt := (others => '0');
			end if;
						
			if rst = '1' then
				value <= (others => '0');
			end if;
		end if;
	end process;

end Behavioral;

