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

entity stat_calc is
    port (Time64  : in  std_logic_vector (63 downto 0);
          Delay   : in  std_logic_vector (31 downto 0);
          Value   : in  std_logic_vector (63 downto 0);
          KickIn  : in  std_logic;
          Output  : out std_logic_vector (63 downto 0);
          KickOut : out std_logic;
			 Underflow : out std_logic);
end stat_calc;

architecture Behavioral of stat_calc is

    signal valuePlusDelay : std_logic_vector (63 downto 0);
    signal subResult      : std_logic_vector(64 downto 0);
    signal noUnderflow    : std_logic;

begin

    valuePlusDelay <= Value + Delay;

    subResult <= ('1' & Time64) - ('0' & valuePlusDelay);

    noUnderflow <= subResult(64);
    Output      <= subResult(63 downto 0);

    KickOut <= KickIn and noUnderflow;
	 Underflow <= KickIn and not noUnderflow;

end Behavioral;
