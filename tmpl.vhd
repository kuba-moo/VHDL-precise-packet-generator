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

entity __TMPL__ is
    port (Clk : in std_logic;
          Rst : in std_logic);
end __TMPL__;

architecture Behavioral of __TMPL__ is

    type state_t is (IDLE);

    signal state, NEXT_state : state_t;

begin

    NEXT_fsm : process (state)
    begin
        NEXT_state <= state;

        case state is
            when IDLE =>

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            state <= NEXT_state;

            if Rst = '1' then
                state <= IDLE;
            end if;
        end if;
    end process;

end Behavioral;
