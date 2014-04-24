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

entity stat_writer is
    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          MemWe   : out std_logic_vector(0 downto 0);
          MemAddr : out std_logic_vector(8 downto 0);
          MemDin  : out std_logic_vector(35 downto 0);
          MemDout : in  std_logic_vector(35 downto 0);
          Value   : in  std_logic_vector(8 downto 0);
          Kick    : in  std_logic);
end stat_writer;

architecture Behavioral of stat_writer is

    type state_t is (ZERO_OUT, IDLE, READ_OLD, WRITE_NEW);

    signal state, NEXT_state : state_t;
    signal addr, NEXT_addr   : std_logic_vector(8 downto 0);

begin

    MemAddr <= addr;

    NEXT_fsm : process (state, addr, MemDout, Value, Kick)
    begin
        NEXT_state <= state;
        NEXT_addr  <= addr;

        MemDin <= MemDout + 1;
        MemWe  <= "0";

        case state is
            when ZERO_OUT =>
                NEXT_addr <= addr + 1;

                MemWe  <= "1";
                MemDin <= (others => '0');

                if addr = b"1" & X"FF" then
                    NEXT_state <= IDLE;
                end if;

            when IDLE =>
                if Kick = '1' then
                    NEXT_state <= READ_OLD;
                    NEXT_addr  <= Value;
                end if;

            when READ_OLD =>
                NEXT_state <= WRITE_NEW;

            when WRITE_NEW =>
                NEXT_state <= IDLE;

                MemWe <= "1";

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            state <= NEXT_state;
            addr  <= NEXT_addr;

            if Rst = '1' then
                state <= ZERO_OUT;
                addr  <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
