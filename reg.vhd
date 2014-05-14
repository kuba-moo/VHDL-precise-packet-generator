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

-- register on a register bus

entity reg is
    generic (REG_BYTES     : integer;
             DEFAULT_VALUE : integer := 0;
             REG_ADDR_BASE : reg_addr_t);

    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          RegBusI : in  reg_bus_t;
          RegBusO : out reg_bus_t;
          Value   : out std_logic_vector(REG_BYTES*8 - 1 downto 0));
end reg;

-- Operation:
-- Hold the @Value. Access it when address on the bus matches @REG_ADDR_BASE.
-- Writes are atomic - @Value is changed only when address on the bus is out of
-- the range of addresses of this register.
-- Writes to register must be 'clock-in-clock' to ensure atomicity of the value.

architecture Behavioral of reg is

    constant OFFSET_LEN : integer := integer(ceil(log2(real(REG_BYTES))));
    constant REG_BITS   : integer := REG_BYTES*8;

    subtype OffsetRange is natural range OFFSET_LEN - 1 downto 0;
    subtype AddrRange   is natural range REG_ADDR_W - 1 downto OFFSET_LEN;

    signal offset             : integer;
    signal bus_addr, reg_addr : std_logic_vector(AddrRange);
    signal v_atomic, v_new    : std_logic_vector(REG_BITS - 1 downto 0) := CONV_std_logic_vector(DEFAULT_VALUE, REG_BITS);

begin
    offset   <= CONV_integer(RegBusI.addr(OffsetRange));
    bus_addr <= RegBusI.addr(AddrRange);
    reg_addr <= REG_ADDR_BASE(AddrRange);

    Value <= v_atomic;

    update : process (Clk)
    begin
        if rising_edge(Clk) then
            RegBusO <= RegBusI;

            if bus_addr = reg_addr then
                if RegBusI.wr = '1' then
                    v_new(7 + offset*8 downto offset*8) <= RegBusI.data;
                else
                    RegBusO.data <= v_atomic(7 + offset*8 downto offset*8);
                end if;
            else
                v_atomic <= v_new;
            end if;

            if Rst = '1' then
                v_new        <= CONV_std_logic_vector(DEFAULT_VALUE, REG_BITS);
                RegBusO.addr <= reg_addr_invl;
            end if;
        end if;
    end process;

end Behavioral;
