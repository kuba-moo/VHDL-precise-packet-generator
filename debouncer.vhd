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

-- Input debouncer and stabilisation circuit
--      use to make sure inputs from buttons don't jump around

entity debouncer is
    port (Clk    : in  std_logic;
          Input  : in  std_logic;
          Output : out std_logic);
end debouncer;

-- Operation:
-- There are two stages of input flop-flops followed by a counter
-- signal must stay high for 128 cycles of @Clk to make @Output
-- go high as well.
-- Output goes low as soon as output of second stage (@Input after
-- two clock cycles) goes low.

architecture Behavioral of debouncer is
    signal stage_1, stage_2 : std_logic;
    signal counter          : std_logic_vector(7 downto 0);
begin
    Output <= counter(7);

    stage_1 <= Input   when RISING_EDGE(Clk);
    stage_2 <= stage_1 when RISING_EDGE(Clk);

    cnt : process (Clk)
    begin
        if RISING_EDGE(Clk) then
            if stage_2 = '1' and counter(7) = '0' then
                counter <= counter + 1;
            end if;

            if stage_2 = '0' then
                counter <= ( others => '0' );
            end if;
        end if;
    end process;

end Behavioral;
