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

-- Semaphore N_BITs, should be fair

entity semaphore_cyclic is
    generic (N_BITS : integer);
    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          Request : in  std_logic_vector (N_BITS-1 downto 0);
          Grant   : out std_logic_vector (N_BITS-1 downto 0));
end semaphore_cyclic;

-- Operation:
-- Cycle one-hot around requesters

architecture Behavioral of semaphore_cyclic is

    constant zero_vec        : std_logic_vector (N_BITS-1 downto 0) := (others => '0');
    signal cyclic, saveGrant : std_logic_vector (N_BITS-1 downto 0) := (0      => '1', others => '0');

begin

	 saveGrant <= Request and cyclic;
    Grant     <= saveGrant;

    mutex : process (Clk)
    begin
        if rising_edge(Clk) then
            if saveGrant = zero_vec then
                cyclic <= cyclic(0) & cyclic(N_BITS-1 downto 1);
            end if;
	 
            if Rst = '1' then
                cyclic    <= (0 => '1', others => '0');
            end if;
        end if;
    end process;

end Behavioral;
