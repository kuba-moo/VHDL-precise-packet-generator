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

entity ctrl_write_mem is
    port (Clk     : in  std_logic;
          PktIn   : in  std_logic;
          DataIn  : in  std_logic_vector (7 downto 0);
          MemAddr : out std_logic_vector (10 downto 0);
          MemData : out std_logic_vector (7 downto 0);
          MemWe   : out std_logic);
end ctrl_write_mem;

architecture Behavioral of ctrl_write_mem is

    signal cnt : std_logic_vector (10 downto 0);

begin

    MemAddr <= cnt;
    MemData <= DataIn;
    MemWe   <= PktIn;

    count : process (Clk)
    begin
        if rising_edge(Clk) then
            cnt <= cnt + 1;

            if PktIn = '0' then
                cnt <= (3 => '1', others => '0');
            end if;
        end if;
    end process;

end Behavioral;
