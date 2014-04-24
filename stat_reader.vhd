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

entity stat_reader is
    port (Clk        : in  std_logic;
          Rst        : in  std_logic;
          Trgr       : in  std_logic;
          MemAddr    : out std_logic_vector (8 downto 0);
          MemData    : in  std_logic_vector (35 downto 0);
			 Request   	: OUT std_logic;
          Grant     	: IN  std_logic;
          ByteOut    : out std_logic_vector (7 downto 0);
          ByteEna    : out std_logic;
          ReaderBusy : in  std_logic);
end stat_reader;

architecture Behavioral of stat_reader is

    type state_t is (IDLE, LOCK, WRITE_ADDR, WRITE_DATA);

    signal state           : state_t;
    signal NEXT_state      : state_t;
    signal addr, NEXT_addr : std_logic_vector (8 downto 0);
    signal cnt, NEXT_cnt   : integer range 0 to 7;

begin
    MemAddr <= addr;

    NEXT_fsm : process (state, cnt, addr, Grant, Trgr, MemData, ReaderBusy)
    begin
        NEXT_state <= state;
        NEXT_addr  <= addr;
        NEXT_cnt   <= cnt;

        ByteEna <= '1';
        Request <= '1';
        ByteOut <= addr(7 downto 0);  -- default to one of the values for opt.

        if ReaderBusy = '0' then
            NEXT_cnt <= cnt + 1;
        end if;

        case state is
            when IDLE =>
                NEXT_cnt  <= 0;
                NEXT_addr <= (others => '-');

                Request <= '0';
                ByteEna <= '0';

                if Trgr = '1' then
                    NEXT_state <= LOCK;
                end if;
                -- no need to wait for mem, we data will be in
                -- when we are done with address anyway

            when LOCK =>
                NEXT_cnt   <= 0;
                NEXT_addr 	<= (others => '0');
					 
                ByteEna <= '0';
					 
                if Grant = '1' then
                    NEXT_state <= WRITE_ADDR;
                end if;
					 
            when WRITE_ADDR =>
                if cnt = 0 then
                    ByteOut <= addr(7 downto 0);
                else
                    ByteOut <= b"0000000" & addr(8);
                end if;

                if cnt = 1 and ReaderBusy = '0' then
                    NEXT_state <= WRITE_DATA;
                    NEXT_cnt   <= 0;
                end if;

            when WRITE_DATA =>
                if cnt = 4 then
                    ByteOut <= X"0" & MemData(35 downto 32);
                else
                    ByteOut <= MemData(7 + cnt*8 downto cnt*8);
                end if;

                if cnt = 5 then
                    NEXT_state <= WRITE_ADDR;
                    NEXT_addr  <= addr + 1;
                    NEXT_cnt   <= 0;

                    if addr = b"1" & X"FF" then
                        NEXT_state <= IDLE;
                    end if;
                end if;

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            state <= NEXT_state;
            addr  <= NEXT_addr;
            cnt   <= NEXT_cnt;

            if Rst = '1' then
                state <= IDLE;
            end if;
        end if;
    end process;

end Behavioral;
