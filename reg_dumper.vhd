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

entity reg_dumper is
    generic (N_BYTES : integer);
    port (Clk        : in  std_logic;
          Rst        : in  std_logic;
          Trgr       : in  std_logic;
          Regs       : in  std_logic_vector (N_BYTES * 8 - 1 downto 0);
          Request    : out std_logic;
          Grant      : in  std_logic;
          Byte       : out std_logic_vector (7 downto 0);
          ByteEna    : out std_logic;
          ReaderBusy : in  std_logic);
end reg_dumper;

architecture Behavioral of reg_dumper is

    type state_t is (IDLE, LOCK, WRITE_ADDR, WRITE_DATA, WAIT_RELEASE);

    signal state, NEXT_state : state_t;
    signal cnt, NEXT_cnt     : integer range 0 to N_BYTES;

begin

    NEXT_fsm : process (state, cnt, Trgr, Grant, ReaderBusy, Regs)
    begin
        NEXT_state <= state;
        NEXT_cnt   <= cnt;

        ByteEna <= '0';
        Byte    <= X"00";
        Request <= '1';
        if ReaderBusy = '0' then
            NEXT_cnt <= cnt + 1;
        end if;

        case state is
            when IDLE =>
                Request <= '0';
                if Trgr = '1' then
                    NEXT_state <= LOCK;
                end if;

            when LOCK =>
                if Grant = '1' and ReaderBusy = '0' then
                    NEXT_state <= WRITE_ADDR;
                    NEXT_cnt   <= 0;
                end if;

            when WRITE_ADDR =>
                ByteEna <= '1';
                Byte    <= X"FF";

                -- when cnt goes up txer is still busy, so he won't xmit even
                -- though we give him kick and new data for the third time
                if cnt = 2 then
                    NEXT_state <= WRITE_DATA;
                    NEXT_cnt   <= 0;
                end if;

            when WRITE_DATA =>
                ByteEna <= '1';
                Byte    <= Regs(7 + cnt*8 downto cnt*8);

                if cnt = N_BYTES then
                    NEXT_state <= WAIT_RELEASE;
                end if;

            when WAIT_RELEASE =>
                Request <= '0';
                if Trgr = '0' then
                    NEXT_state <= IDLE;
                end if;

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            state <= NEXT_state;
            cnt   <= NEXT_cnt;

            if Rst = '1' then
                state <= IDLE;
            end if;
        end if;
    end process;

end Behavioral;
