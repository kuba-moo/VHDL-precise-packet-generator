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
 
ENTITY tb_ctrl_regs IS
END tb_ctrl_regs;
 
ARCHITECTURE behavior OF tb_ctrl_regs IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ctrl_regs
    PORT(
         Clk : IN  std_logic;
         PktIn : IN  std_logic;
         DataIn : IN  std_logic_vector(7 downto 0);
         PktOut : OUT  std_logic;
         DataOut : OUT  std_logic_vector(7 downto 0);
         Regs : OUT  std_logic_vector(79 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal PktIn : std_logic := '0';
   signal DataIn : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal PktOut : std_logic;
   signal DataOut : std_logic_vector(7 downto 0);
   signal Regs : std_logic_vector(79 downto 0);

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ctrl_regs PORT MAP (
          Clk => Clk,
          PktIn => PktIn,
          DataIn => DataIn,
          PktOut => PktOut,
          DataOut => DataOut,
          Regs => Regs
        );

   -- Clock process definitions
   Clk_process :process
   begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 200 ns;	
		
		PktIn <= '1';
		wait for Clk_period * 8;
		for i in 1 to 1 loop
			DataIn <= CONV_std_logic_vector(i, 8);
			wait for Clk_period;
		end loop;
		PktIn <= '0';
      wait for Clk_period*20;
	
		PktIn <= '1';
		for i in 1 to 15 loop
			DataIn <= CONV_std_logic_vector(i, 8);
			wait for Clk_period;
		end loop;
		PktIn <= '0';
      wait for Clk_period*20;
		
		PktIn <= '1';
		DataIn <= X"00";
		wait for Clk_period * 7;
		for i in 1 to 15 loop
			DataIn <= CONV_std_logic_vector(i, 8);
			wait for Clk_period;
		end loop;
		PktIn <= '0';
      wait for Clk_period*20;

      wait;
   end process;

END;
