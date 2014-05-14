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
use IEEE.math_real.all;
use work.globals.all;

-- single byte register on a register bus

entity reg_byte is
    generic (DEFAULT_VALUE : integer := 0;
             REG_ADDR_BASE : reg_addr_t);

    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          RegBusI : in  reg_bus_t;
          RegBusO : out reg_bus_t;
          Value   : out byte_t);
end reg_byte;

-- Operation:
-- Hold the @Value. Access it when address on the bus matches @REG_ADDR_BASE.
--
-- This version of register is slightly optimised, because there is no need for
-- atomicity and stuff.

architecture Behavioral of reg_byte is

    signal byte : byte_t := CONV_std_logic_vector(DEFAULT_VALUE, 8);

begin

    Value <= byte;

    update : process (Clk)
    begin
        if rising_edge(Clk) then
            RegBusO <= RegBusI;

            if RegBusI.addr = REG_ADDR_BASE then
                if RegBusI.wr = '1' then
                    byte <= RegBusI.data;
                else
                    RegBusO.data <= byte;
                end if;
            end if;

            if Rst = '1' then
                RegBusO.addr <= reg_addr_invl;
                byte        <= CONV_std_logic_vector(DEFAULT_VALUE, 8);
            end if;
        end if;
    end process;

end Behavioral;
