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

-- Binary wrap-around counter with enable

entity counter_en is
    generic (N_BITS : integer);
    port (Clk    : in  std_logic;
          Rst    : in  std_logic;
          Enable : in  std_logic;
          Cnt    : out std_logic_vector (N_BITS - 1 downto 0));
end counter_en;

-- Operation:
-- Count number of cycles @Enable is up.
-- Increase input from 0 to 2^N_BITS - 1 then start from zero again.

architecture Behavioral of counter_en is

    signal count : std_logic_vector (N_BITS - 1 downto 0);

begin
    Cnt <= count;

    inc : process (Clk)
    begin
        if RISING_EDGE(Clk) then
            if Enable = '1' then
                count <= count + 1;
            end if;

            if Rst = '1' then
                count <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
