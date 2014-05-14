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
use IEEE.math_real.all;
use work.globals.all;

-- UART interface for registers

entity reg_master_uart is
    generic (REQ_SIZE : integer);       -- #bytes per req

    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          RxByte  : in  byte_t;
          RxValid : in  std_logic;
          TxByte  : out byte_t;
          TxKick  : out std_logic;
          TxBusy  : in  std_logic;
          BusO    : out reg_bus_t;
          BusI    : in  reg_bus_t);
end reg_master_uart;

-- Operation:
--   1. receive Request from UART;
--   2. convert Request to reg_bus_t format;
--   3. send Request onto bus;
--   4. read Response from the bus (bus is looped);
--   5. convert Response to Request format;
--   6. send Response to UART.
--
-- All UART frames have identical format.
--  - in read requests data is treated as default value (value which will
--    be returned if no register matches the address
--  - in write responses data is just an echo of the request and should NOT
--    be treated as new value of the register
--
-- Request bit format:
--      offset    |       field
-- ---------------+------------------------------
--        0       |  read(0)/write(1)
-- 1 - REG_ADDR_W |      address
-- ------------align-to-byte-boundary------------
--  REQ_SIZE * 8  | data (default value for read)
--
--
-- WARNING: generating ny operation targeting invalid address (read or write
--          that encompasses address with all 1's) will HUNG the bus master!!!

architecture Behavioral of reg_master_uart is

    constant REQ_HDR_LEN : integer := integer(ceil(real(1 + REG_ADDR_W)/8.0));
    constant REQ_MAX_LEN : integer := REQ_HDR_LEN + REQ_SIZE;

    type state_t is (WAIT_REQ, EMIT, WAIT_LOOP, RESPOND, WAIT_UART);

    subtype req_buffer_t is std_logic_vector(REQ_MAX_LEN*8 - 1 downto 0);
    constant ReqRWBit : integer := 0;
    subtype ReqAddr is natural range REG_ADDR_W downto 1;

    signal state, NEXT_state     : state_t;
    signal cnt, NEXT_cnt         : integer range 0 to REQ_MAX_LEN := 0;
    signal req_buf, NEXT_req_buf : req_buffer_t;
    signal res_cnt, NEXT_res_cnt : integer range 0 to REQ_MAX_LEN;

begin

    NEXT_fsm : process (state, cnt, req_buf, res_cnt, RxValid, RxByte, TxBusy, BusI, NEXT_cnt)
    begin
        NEXT_state   <= state;
        NEXT_cnt     <= cnt;
        NEXT_req_buf <= req_buf;
        NEXT_res_cnt <= res_cnt;

        TxByte <= req_buf(cnt*8 + 7 downto cnt*8);
        TxKick <= '0';

        BusO.wr   <= req_buf(ReqRWBit);
        BusO.addr <= reg_addr_invl;
        BusO.data <= (others => '0');

        if BusI.addr /= reg_addr_invl then  -- data coming back
            NEXT_req_buf((res_cnt + REQ_HDR_LEN)*8 + 7 downto
                         (res_cnt + REQ_HDR_LEN)*8) <= BusI.data;
            NEXT_res_cnt <= res_cnt + 1;
        end if;

        case state is
            when WAIT_REQ =>
                if RxValid = '1' then
                    NEXT_req_buf(cnt*8 + 7 downto cnt*8) <= RxByte;
                    NEXT_cnt                             <= cnt + 1;
                end if;

                if cnt = REQ_MAX_LEN then
                    NEXT_state   <= EMIT;
                    NEXT_cnt     <= 0;
                    NEXT_res_cnt <= 0;
                end if;

            when EMIT =>
                NEXT_cnt  <= cnt + 1;
                BusO.addr <= CONV_std_logic_vector(cnt + CONV_integer(req_buf(ReqAddr)), REG_ADDR_W);
                BusO.data <= req_buf((cnt + REQ_HDR_LEN)*8 + 7 downto (cnt + REQ_HDR_LEN)*8);

                if NEXT_cnt = REQ_SIZE then  -- wait until data loops back
                    NEXT_state <= WAIT_LOOP;
                end if;

            when WAIT_LOOP =>
                if res_cnt = REQ_SIZE then
                    NEXT_state <= RESPOND;
                    NEXT_cnt   <= 0;
                end if;

            when RESPOND =>
                NEXT_state <= WAIT_UART;
                NEXT_cnt   <= cnt + 1;
                TxKick     <= '1';

            when WAIT_UART =>
                if TxBusy = '0' then
                    NEXT_state <= RESPOND;
                end if;

                if cnt = REQ_MAX_LEN then
                    NEXT_state <= WAIT_REQ;
                    NEXT_cnt   <= 0;
                end if;

        end case;
    end process;

    fsm : process (Clk)
    begin
        if rising_edge(Clk) then
            state   <= NEXT_state;
            cnt     <= NEXT_cnt;
            req_buf <= NEXT_req_buf;
            res_cnt <= NEXT_res_cnt;

            if Rst = '1' then
                state <= WAIT_REQ;
                cnt   <= 0;
            end if;
        end if;
    end process;

end Behavioral;
