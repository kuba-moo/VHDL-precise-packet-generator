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

entity counter64 is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           cnt : out  STD_LOGIC_VECTOR (63 downto 0));
end counter64;

architecture Behavioral of counter64 is
	
	signal count : STD_LOGIC_VECTOR (63 downto 0);
	
begin
	cnt <= count;

	inc: process (clk)
	begin
		if RISING_EDGE(clk) then
			count <= count + 1;
			
			if rst = '1' then
				count <= ( others => '0' );
			end if;
		end if;
	end process;

end Behavioral;

