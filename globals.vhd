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

-- globals for projects using my modules

package globals is
    constant FPGA_CLK_FREQ : integer := 100000000; -- 100 MHz

    subtype byte_t is std_logic_vector(7 downto 0);

    -- register interface
    constant REG_ADDR_W : integer := 5;

    subtype reg_addr_t is std_logic_vector(REG_ADDR_W - 1 downto 0);
    constant reg_addr_invl : std_logic_vector(REG_ADDR_W - 1 downto 0) := ( others => '1' );

    type reg_bus_t is record
        wr   : std_logic;
        data : byte_t;
        addr : reg_addr_t;
    end record reg_bus_t;
end globals;

package body globals is
end globals;
