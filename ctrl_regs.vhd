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

entity ctrl_regs is
    port (Clk     : in  std_logic;
          PktIn   : in  std_logic;
          DataIn  : in  std_logic_vector (7 downto 0);
          PktOut  : out std_logic;
          DataOut : out std_logic_vector (7 downto 0);
          Regs    : out std_logic_vector (79 downto 0));
end ctrl_regs;

architecture Behavioral of ctrl_regs is

    type byte_vec is array (0 to 11) of std_logic_vector(7 downto 0);

    signal delayByte : byte_vec;
    signal delayPkt  : std_logic_vector(0 to 11);

begin

    PktOut  <= delayPkt(1) and delayPkt(11);
    DataOut <= delayByte(11);

    assign_reg : for i in 0 to 79 generate
        Regs(i) <= delayByte(1 + i/8)(i mod 8);
    end generate assign_reg;

    delayPkt(0) <= PktIn when rising_edge(Clk);
    pkt_path : for i in 0 to 10 generate
        delayPkt(i + 1) <= delayPkt(i) when rising_edge(Clk);
    end generate;

    path : process (Clk)
    begin
        if rising_edge(Clk) then
            delayByte(0) <= DataIn;

            if delayPkt(0) = '1' then
                -- No generate inside process? VHDL sucks;
                delayByte(1)  <= delayByte(0);
                delayByte(2)  <= delayByte(1);
                delayByte(3)  <= delayByte(2);
                delayByte(4)  <= delayByte(3);
                delayByte(5)  <= delayByte(4);
                delayByte(6)  <= delayByte(5);
                delayByte(7)  <= delayByte(6);
                delayByte(8)  <= delayByte(7);
                delayByte(9)  <= delayByte(8);
                delayByte(10) <= delayByte(9);
                delayByte(11) <= delayByte(10);
            end if;
        end if;
    end process;

end Behavioral;
