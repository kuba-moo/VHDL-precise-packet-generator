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

entity ethernet_control is
    Port ( clk		: in  STD_LOGIC;
           rst 	: in STD_LOGIC;
			  cnt_23 : in STD_LOGIC;
			  cnt_22 : in STD_LOGIC;
			  
			  PhyRstn : out STD_LOGIC);
end ethernet_control;

architecture Behavioral of ethernet_control is

begin

	-- PHY requires reset to be asserted for 100 uS
	phy_reset: process (clk)
		variable done : STD_LOGIC := '0';
	begin
		if RISING_EDGE(clk) then			
			if done = '0' then
				PhyRstn <= not cnt_22;
			end if;
			
			done := done or cnt_23;
			
			if rst = '1' then
				done := '0';
				PhyRstn <= '0';
			end if;
		end if;
	end process;

end Behavioral;

