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
  
ENTITY tb_mdio IS
END tb_mdio;
 
ARCHITECTURE behavior OF tb_mdio IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mdio
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
			cnt_5  : in  STD_LOGIC;
         cnt_23 : IN  std_logic;
         mdc : OUT  std_logic;
         mdio_i : IN  std_logic;
         mdio_o : OUT  std_logic;
         mdio_t : OUT  std_logic;
         data : IN  std_logic_vector(7 downto 0);
         digit : OUT  std_logic_vector(15 downto 0);
         trgr : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal cnt64 : std_logic_vector(63 downto 0) := ( others => '0' );
   signal mdio_i : std_logic := '0';
   signal data : std_logic_vector(7 downto 0) := (others => '0');
   signal trgr : std_logic := '0';

 	--Outputs
   signal mdc : std_logic;
   signal mdio_o : std_logic;
   signal mdio_t : std_logic;
   signal digit : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mdio PORT MAP (
          clk => clk,
          rst => rst,
			 cnt_5 => cnt64(5),
          cnt_23 => cnt64(8),
          mdc => mdc,
          mdio_i => mdio_i,
          mdio_o => mdio_o,
          mdio_t => mdio_t,
          data => data,
          digit => digit,
          trgr => trgr
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
	cnt_64_p :process
	begin
		cnt64 <= cnt64 + 1;
		wait for clk_period;		
	end process;

   -- Stimulus process
   stim_proc: process
   begin	
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		rst <= '0';
		
		wait for 10 us;
		trgr <= '1';
		wait for 1 us;
		trgr <= '0';
      -- insert stimulus here 

      wait;
   end process;

END;
