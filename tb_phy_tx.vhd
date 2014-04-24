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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 
ENTITY tb_phy_tx IS
END tb_phy_tx;
 
ARCHITECTURE behavior OF tb_phy_tx IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT phy_tx
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         PhyTxd : OUT  std_logic_vector(3 downto 0);
         PhyTxEn : OUT  std_logic;
         PhyTxClk : IN  std_logic;
         Led : OUT  std_logic_vector(1 downto 0);
         data : IN  std_logic_vector(7 downto 0);
         busPkt : IN  std_logic;
         busDesc : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal PhyTxClk : std_logic := '0';
   signal data : std_logic_vector(7 downto 0) := (others => '0');
   signal busPkt : std_logic := '0';
   signal busDesc : std_logic := '0';

 	--Outputs
   signal PhyTxd : std_logic_vector(3 downto 0);
   signal PhyTxEn : std_logic;
   signal Led : std_logic_vector(1 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant PhyTxClk_period : time := 40 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: phy_tx PORT MAP (
          clk => clk,
          rst => rst,
          PhyTxd => PhyTxd,
          PhyTxEn => PhyTxEn,
          PhyTxClk => PhyTxClk,
          Led => Led,
          data => data,
          busPkt => busPkt,
          busDesc => busDesc
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   PhyTxClk_process :process
   begin
		PhyTxClk <= '0';
		-- F-up the timing slightly
		wait for PhyTxClk_period/2 - 1ns;
		PhyTxClk <= '1';
		wait for PhyTxClk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst <= '1';
		data <= X"00";
		busDesc <= '0';
		busPkt <= '0';
		
      wait for 5 ns;	

		rst <= '0';
		
		wait for clk_period*4;

		data <= X"A5";
		busDesc <= '1';
		busPkt <= '0';

      wait for clk_period*4;

		busDesc <= '0';
		busPkt <= '1';

      -- insert stimulus here 

		wait for clk_period*10;

		data <= X"00";
		busDesc <= '0';
		busPkt <= '0';

      wait;
   end process;

END;
