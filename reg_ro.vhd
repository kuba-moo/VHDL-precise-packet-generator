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

-- read only register

entity reg_ro is
    generic (REG_BYTES     : integer;
             REG_ADDR_BASE : reg_addr_t);

    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          RegBusI : in  reg_bus_t;
          RegBusO : out reg_bus_t;
          Value   : in  std_logic_vector(REG_BYTES*8 - 1 downto 0));
end reg_ro;

-- Operation:
-- Report @Value to the bus when address matches.
-- WARNING: this version of ro-register is NOT atomic.

architecture Behavioral of reg_ro is

    constant OFFSET_LEN : integer := integer(ceil(log2(real(REG_BYTES))));
    constant REG_BITS   : integer := REG_BYTES*8;

    subtype OffsetRange is natural range OFFSET_LEN - 1 downto 0;
    subtype AddrRange is natural range REG_ADDR_W - 1 downto OFFSET_LEN;

    signal offset             : integer;
    signal bus_addr, reg_addr : std_logic_vector(AddrRange);

begin

    offset   <= CONV_integer(RegBusI.addr(OffsetRange));
    bus_addr <= RegBusI.addr(AddrRange);
    reg_addr <= REG_ADDR_BASE(AddrRange);

    read_out : process (Clk)
    begin
        if rising_edge(Clk) then
            RegBusO <= RegBusI;

            if bus_addr = reg_addr and RegBusI.wr = '0' then
                RegBusO.data <= Value(7 + offset*8 downto offset*8);
            end if;

            if Rst = '1' then
                RegBusO.addr <= reg_addr_invl;
            end if;
        end if;
    end process;

end Behavioral;
