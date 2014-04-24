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

entity stat_compress is
    port (Clk       : in  std_logic;
          Value     : in  std_logic_vector (63 downto 0);
          KickIn    : in  std_logic;
          Statistic : out std_logic_vector (8 downto 0);
          KickOut   : out std_logic);
end stat_compress;

architecture Behavioral of stat_compress is

    signal compressLogic : std_logic_vector (8 downto 0);

begin

    compressLogic <= b"1" & X"FF"               when Value(63 downto 24) /= X"00000" else
                     b"1" & Value(23 downto 16) when Value(23 downto 16) /= X"00" else
                     b"0" & Value(15 downto 8);

    Statistic <= compressLogic when rising_edge(Clk);
    KickOut   <= KickIn        when rising_edge(Clk);

end Behavioral;
