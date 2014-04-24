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

entity ctrl_filter is
    port (Clk      : in  std_logic;
          Rst      : in  std_logic;
          PktIn    : in  std_logic;
          DataIn   : in  std_logic_vector (7 downto 0);
          PktOut   : out std_logic;
          DataOut  : out std_logic_vector (7 downto 0);
          CtrlEn   : out std_logic;
          CtrlData : out std_logic_vector (7 downto 0));
end ctrl_filter;

architecture Behavioral of ctrl_filter is

    type state_t is (IDLE, PAST_SFD, PACKET, CTRL);
    type byte_vec is array (0 to 8) of std_logic_vector(7 downto 0);

    signal state, NEXT_state : state_t;
    signal cnt, NEXT_cnt     : integer range 0 to 7;

    signal delayByte : byte_vec;
    signal delayPkt  : std_logic_vector(0 to 8);

begin

    delayByte(0) <= DataIn when rising_edge(Clk);
    delayPkt(0)  <= PktIn  when rising_edge(Clk);

    delay_path : for i in 0 to 7
    generate
        delayByte(i + 1) <= delayByte(i) when rising_edge(Clk);
        delayPkt(i + 1)  <= delayPkt(i)  when rising_edge(Clk);
    end generate delay_path;

    CtrlData <= delayByte(0);
    DataOut  <= delayByte(8);

    NEXT_fsm : process (state, cnt, delayPkt(0), delayPkt(8), delayByte(0))
    begin
        NEXT_state <= state;
        NEXT_cnt   <= cnt;

        CtrlEn <= '0';
        PktOut <= '0';

        case state is
            when IDLE =>
                if delayPkt(0) = '1' and delayByte(0)(7 downto 4) = X"d" then
                    NEXT_state <= PAST_SFD;
                    NEXT_cnt   <= 0;
                end if;

            when PAST_SFD =>
                NEXT_cnt <= cnt + 1;

                if cnt = 7 then
                    NEXT_state <= CTRL;
                end if;

                if delayByte(0) /= X"00" then
                    NEXT_state <= PACKET;
                end if;

            when PACKET =>
                PktOut <= delayPkt(8);

                if delayPkt(0) = '0' and delayPkt(8) = '0' then
                    NEXT_state <= IDLE;
                end if;

            when CTRL =>
                CtrlEn <= delayPkt(0);

                if delayPkt(0) = '0' then
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
                cnt   <= 0;
            end if;
        end if;
    end process;


end Behavioral;
