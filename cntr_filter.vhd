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

entity cntr_filter is
    Port ( Clk : in  STD_LOGIC;
           Rst : in  STD_LOGIC;
           PktIn : in  STD_LOGIC;
           ByteIn : in  STD_LOGIC_VECTOR (7 downto 0);
           PktOut : out  STD_LOGIC;
           ByteOut : out  STD_LOGIC_VECTOR (7 downto 0);
           CtrlEn : out  STD_LOGIC;
           CtrlData : out  STD_LOGIC_VECTOR (7 downto 0));
end cntr_filter;

architecture Behavioral of cntr_filter is

begin


end Behavioral;

