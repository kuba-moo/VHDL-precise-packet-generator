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
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity enable_to_kick is
    Port ( Clk : in  STD_LOGIC;
           Enable : in  STD_LOGIC;
           Kick : out  STD_LOGIC);
end enable_to_kick;

architecture Behavioral of enable_to_kick is

	signal delayEnable : std_logic;

begin

	delayEnable <= Enable when rising_edge(Clk);
	Kick			<= '1' when delayEnable = '0' and Enable = '1' else '0';

end Behavioral;

