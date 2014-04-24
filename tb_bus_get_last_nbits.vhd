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
 
ENTITY tb_bus_get_last_nbits IS
END tb_bus_get_last_nbits;
 
ARCHITECTURE behavior OF tb_bus_get_last_nbits IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
	COMPONENT bus_get_last_nbits
   GENERIC (N_BITS : integer);
   PORT( Clk     		: in  std_logic;
			Rst			: in  std_logic;
         PktIn   		: in  std_logic;
         DataIn  		: in  std_logic_vector(7 downto 0);
         Value   		: out std_logic_vector(N_BITS - 1 downto 0);
         ValueEn 		: out std_logic);
	END COMPONENT;
	
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal PktIn : std_logic := '0';
   signal DataIn : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal Value : std_logic_vector(8 downto 0);
   signal ValueEn : std_logic;

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bus_get_last_nbits 
	GENERIC MAP ( N_BITS => 9 )
	PORT MAP (
          Clk => Clk,
          Rst => Rst,
          PktIn => PktIn,
          DataIn => DataIn,
          Value => Value,
          ValueEn => ValueEn
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
      wait for 100 ns;	

		PktIn <= '1';
		for i in 1 to 10 loop
			DataIn <= CONV_std_logic_vector(i, 8);
			wait for Clk_period;
		end loop;
		PktIn <= '0';

      -- insert stimulus here 

      wait;
   end process;

END;
