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

-- bundle of uart rx/tx and reg master

entity mod_uart_regs is
    generic (UART_RATE : integer;
             REQ_SIZE  : integer);

    port (Clk         : in  std_logic;
          Rst         : in  std_logic;
          RsRx        : in  std_logic;
          RsTx        : out std_logic;
          RegBusStart : out reg_bus_t;
          RegBusEnd   : in  reg_bus_t);
end mod_uart_regs;

-- Dependencies:
-- uart_rx, freq_generator, uart_tx, reg_master_uart
--
-- Operation:
-- Create register bus master on UART.
-- This is a bundle created for convenience.

architecture Behavioral of mod_uart_regs is

    component uart_rx is
        generic (FREQUENCY : integer);

        port (Clk   : in  std_logic;
              Rst   : in  std_logic;
              RsRx  : in  std_logic;
              Byte  : out byte_t;
              Valid : out std_logic);
    end component;
    signal RxByte  : byte_t;
    signal RxValid : std_logic;

    component freq_generator is
        generic (FREQUENCY     : integer;  -- target freq
                 CLK_FREQUENCY : integer := FPGA_CLK_FREQ);

        port (Clk    : in  std_logic;
              Rst    : in  std_logic;
              Output : out std_logic);
    end component;
    signal enTxFreq : std_logic;

    component uart_tx is
        port (Clk    : in  std_logic;
              Rst    : in  std_logic;
              FreqEn : in  std_logic;
              Byte   : in  std_logic_vector(7 downto 0);
              Kick   : in  std_logic;
              RsTx   : out std_logic;
              Busy   : out std_logic);
    end component;
    signal TxKick, TxBusy : std_logic;
    signal TxByte         : byte_t;

    component reg_master_uart is
        generic (REQ_SIZE : integer);   -- #bytes per req

        port (Clk     : in  std_logic;
              Rst     : in  std_logic;
              RxByte  : in  byte_t;
              RxValid : in  std_logic;
              TxByte  : out byte_t;
              TxKick  : out std_logic;
              TxBusy  : in  std_logic;
              BusO    : out reg_bus_t;
              BusI    : in  reg_bus_t);
    end component;

begin

    rx : uart_rx
        generic map(FREQUENCY => UART_RATE)
        port map(Clk   => Clk,
                 Rst   => Rst,
                 RsRx  => RsRx,
                 Byte  => RxByte,
                 Valid => RxValid);

    tx_freq : freq_generator
        generic map(FREQUENCY => UART_RATE)
        port map(Clk, Rst, enTxFreq);

    tx : uart_tx
        port map(Clk    => Clk,
                 Rst    => Rst,
                 FreqEn => enTxFreq,
                 Byte   => TxByte,
                 Kick   => TxKick,
                 RsTx   => RsTx,
                 Busy   => TxBusy);

    master : reg_master_uart
        generic map(REQ_SIZE => REQ_SIZE)
        port map(Clk     => Clk,
                 Rst     => Rst,
                 RxByte  => RxByte,
                 RxValid => RxValid,
                 TxByte  => TxByte,
                 TxKick  => TxKick,
                 TxBusy  => TxBusy,
                 BusO    => RegBusStart,
                 BusI    => RegBusEnd);

end Behavioral;
