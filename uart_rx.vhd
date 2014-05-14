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

use work.globals.all;

-- UART receive

entity uart_rx is
    generic (FREQUENCY     : integer);

    port (Clk   : in  std_logic;
          Rst   : in  std_logic;
          RsRx  : in  std_logic;
          Byte  : out byte_t;
          Valid : out std_logic);
end uart_rx;

-- Operation:
-- When @RsRx goes down start counting bit time, sample on half of bit time.
-- To rule out spurious starts wait for @RsRx to go low for a few cycles.

architecture Behavioral of uart_rx is

    constant CLK_MAX    : integer := FPGA_CLK_FREQ/FREQUENCY;
    constant CLK_SAMPLE : integer := CLK_MAX/2;
    type a2_byte is array(1 downto 0) of byte_t;
    type state_t is (IDLE, START, RX, STOP);

    signal bit_no, NEXT_bit_no : integer range 0 to 8;
    signal value, NEXT_value   : byte_t;
    signal cnt, NEXT_cnt       : integer range 0 to CLK_MAX;
    signal state, NEXT_state   : state_t;

    signal rx_d : std_logic_vector(1 downto 0);

begin

    Byte <= value;

    rx_d(0) <= RsRx when rising_edge(Clk);
    rx_d(1) <= rx_d(0) when rising_edge(Clk);

    NEXT_fsm : process (state, cnt, value, bit_no, rx_d(1))
    begin
        NEXT_state  <= state;
        NEXT_cnt    <= cnt + 1;
        NEXT_value  <= value;
        NEXT_bit_no <= bit_no;

        Valid <= '0';

        case state is
            when IDLE =>
                if rx_d(1) = '0' then -- waiting for a stable low input will
                                      -- offset the sampling time by 8, but it
                                      -- should be ok for UART rates
                    NEXT_bit_no <= bit_no + 1;
                    if CONV_std_logic_vector(bit_no, 4)(3) = '1' then
                        NEXT_state <= START;
                        NEXT_cnt   <= 0;
                    end if;
                else
                    NEXT_bit_no <= 0;
                end if;

            when START =>
                if cnt = CLK_MAX then
                    NEXT_state  <= RX;
                    NEXT_cnt    <= 0;
                    NEXT_bit_no <= 0;
                end if;

            when RX =>
                if CONV_std_logic_vector(bit_no, 4)(3) = '1' then
                    NEXT_state <= STOP;
                    Valid      <= '1';
                end if;

                if cnt = CLK_SAMPLE then
                    NEXT_value(bit_no) <= rx_d(1);
                end if;

                if cnt = CLK_MAX then
                    NEXT_state  <= RX;
                    NEXT_cnt    <= 0;
                    NEXT_bit_no <= bit_no + 1;
                end if;

            when STOP =>
                if cnt = CLK_SAMPLE then -- go to IDLE early, if we wait full
                                         -- bit time, delays from IDLE might
                                         -- accumulate
                    NEXT_state <= IDLE;
                end if;

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            state  <= NEXT_state;
            cnt    <= NEXT_cnt;
            value  <= NEXT_value;
            bit_no <= NEXT_bit_no;

            if Rst = '1' then
                state <= IDLE;
            end if;
        end if;
    end process;

end Behavioral;
