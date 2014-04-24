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
 
ENTITY tb_eth_add_crc IS
END tb_eth_add_crc;
 
ARCHITECTURE behavior OF tb_eth_add_crc IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT eth_add_crc
    PORT(
         Clk : IN  std_logic;
         Rst : IN  std_logic;
         InPkt : IN  std_logic;
         InData : IN  std_logic_vector(7 downto 0);
         OutPkt : OUT  std_logic;
         OutData : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    
	 function reversed(slv: std_logic_vector) return std_logic_vector is
        variable result: std_logic_vector(slv'reverse_range);
    begin
        for i in slv'range loop
            result(i) := slv(i);
        end loop;
        return result;
    end reversed;

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal InPkt : std_logic := '0';
   signal InData : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal OutPkt : std_logic;
   signal OutData : std_logic_vector(7 downto 0);
	signal not_out, rev, rev_not	: std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
 
BEGIN
	not_out	<= not OutData;
	rev		<= reversed(OutData);
	rev_not	<= not rev;
 
	-- Instantiate the Unit Under Test (UUT)
   uut: eth_add_crc PORT MAP (
          Clk => Clk,
          Rst => Rst,
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
		wait for Clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 104 ns;	

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
