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
 
ENTITY tb_semaphore_cyclic IS
END tb_semaphore_cyclic;
 
ARCHITECTURE behavior OF tb_semaphore_cyclic IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT semaphore_cyclic
    generic (N_BITS : integer);
    port (Clk     : in  std_logic;
          Rst     : in  std_logic;
          Request : in  std_logic_vector (N_BITS-1 downto 0);
          Grant   : out std_logic_vector (N_BITS-1 downto 0));
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal Request : std_logic_vector(2 downto 0) := (others => '0');

 	--Outputs
   signal Grant : std_logic_vector(2 downto 0);

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: semaphore_cyclic 
	GENERIC MAP (N_BITS => 3)
	PORT MAP (
          Clk => Clk,
          Rst => Rst,
          Request => Request,
          Grant => Grant
        );

   -- Clock process definitions
   Clk_process :process
   begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
   end process;
 
   a1 :process
   begin
		Request(0) <= not Request(0);
		wait for Clk_period * 5;
   end process;
	
	a2 :process
   begin
		Request(1) <= not Request(1);
		wait for Clk_period * 6;
   end process;

   a3 :process
   begin
		Request(2) <= not Request(2);
		wait for Clk_period * 7;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for Clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
