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
 
ENTITY tb_eth_add_ts IS
END tb_eth_add_ts;
 
ARCHITECTURE behavior OF tb_eth_add_ts IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
	COMPONENT bus_append	
	GENERIC ( N_BYTES : integer );
	PORT( Clk 			:  IN std_logic;
			Rst 			:  IN std_logic;
			Value 		:  in STD_LOGIC_VECTOR (N_BYTES*8 - 1 downto 0);
			InPkt 		:  IN std_logic;
			InData 		:  IN std_logic_vector(7 downto 0);          
			OutPkt 		: OUT std_logic;
			OutData 		: OUT std_logic_vector(7 downto 0));
	END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal Cnt64 : std_logic_vector(63 downto 0) := (others => '0');
   signal InPkt : std_logic := '0';
   signal InData : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal OutPkt : std_logic;
   signal OutData : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bus_append
	GENERIC MAP ( N_BYTES <= 8 )
	PORT MAP (
          Clk => Clk,
          Rst => Rst,
          Value => Cnt64,
          InPkt => InPkt,
          InData => InData,
          OutPkt => OutPkt,
          OutData => OutData
        );

   -- Clock process definitions
   Clk_process :process
   begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		Cnt64 <= Cnt64 + 1;
		wait for Clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for Clk_period*10;

		InPkt	<= '1';
		for i in 0 to 6 loop
			InData	<= X"55";
			wait for Clk_period;		
		end loop;
		InData	<= X"d5";
		wait for Clk_period;
		for i in 0 to 63 loop
			InData	<= CONV_std_logic_vector(i, 8);
			wait for Clk_period;
		end loop;
--		InData	<= x"00";
--		wait for Clk_period;
		InPkt	<= '0';
		
      -- insert stimulus here 

      wait;
   end process;

END;
