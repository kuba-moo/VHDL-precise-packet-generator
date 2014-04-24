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

-- Remove last @N_BYTES from data flying through Bus

entity bus_tail_strip is
    generic (N_BYTES : integer);
    port (Clk     : in  std_logic;
          PktIn   : in  std_logic;
          DataIn  : in  std_logic_vector(7 downto 0);
          PktOut  : out std_logic;
          DataOut : out std_logic_vector(7 downto 0));
end bus_tail_strip;

-- Operation:
-- Delay all signals and "and" incoming @PktIn with @PktOut to cut it early.
-- NOTE: input is registered which may not be necessary. Remove clocking of
--       delay*(0) to stop registering input.

architecture Behavioral of bus_tail_strip is

    type byte_vec is array (0 to N_BYTES) of std_logic_vector(7 downto 0);

    signal delayByte : byte_vec;
    signal delayPkt  : std_logic_vector(0 to N_BYTES);

begin

    delayByte(0) <= DataIn when rising_edge(Clk);
    delayPkt(0)  <= PktIn  when rising_edge(Clk);

    delay_path : for i in 0 to N_BYTES - 1
    generate
        delayByte(i + 1) <= delayByte(i) when rising_edge(Clk);
        delayPkt(i + 1)  <= delayPkt(i)  when rising_edge(Clk);
    end generate delay_path;

    DataOut <= delayByte(N_BYTES);
    PktOut  <= delayPkt(0) and delayPkt(N_BYTES);

end Behavioral;
