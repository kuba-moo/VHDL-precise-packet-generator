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

-- UART transmission module

entity uart_tx is
    port (Clk    : in  std_logic;
          Rst    : in  std_logic;
          FreqEn : in  std_logic;
          Byte   : in  std_logic_vector(7 downto 0);
          Kick   : in  std_logic;
          RsTx   : out std_logic;
          Busy   : out std_logic);
end uart_tx;

-- Operation:
-- Wait for @Kick, save values of @Kick and @Byte when it's high.
-- Transition between states when @FreqEn is high.

architecture Behavioral of uart_tx is

    type state_t is (IDLE, START, XMIT, STOP);

    signal state, NEXT_state : state_t;
    signal cnt, NEXT_cnt     : integer range 0 to 7;

    signal saveByte : std_logic_vector(7 downto 0);
    signal saveKick : std_logic;

begin
    Busy <= saveKick;

    NEXT_fsm : process (state, cnt, saveByte, saveKick)
    begin
        NEXT_state <= state;
        NEXT_cnt   <= cnt + 1;

        RsTx <= '1';                    -- high is idle

        case state is
            when IDLE =>
                if saveKick = '1' then
                    NEXT_state <= START;
                end if;

            when START =>
                NEXT_state <= XMIT;
                NEXT_cnt   <= 0;

                RsTx <= '0';

            when XMIT =>
                RsTx <= saveByte(cnt);

                if cnt = 7 then
                    NEXT_state <= STOP;
                end if;

            when STOP =>  -- UART wants at least two stop bits - STOP, IDLE
                NEXT_state <= IDLE;

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            if FreqEn = '1' then
                state <= NEXT_state;
                cnt   <= NEXT_cnt;

                if state = STOP then
                    saveKick <= '0';
                end if;
            end if;

            if saveKick = '0' and Kick = '1' then
                saveKick <= Kick;
                saveByte <= Byte;
            end if;

            if Rst = '1' then
                state    <= IDLE;
                saveKick <= '0';
            end if;
        end if;
    end process;

end Behavioral;
