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
 
ENTITY tb_mem_reader IS
END tb_mem_reader;
 
ARCHITECTURE behavior OF tb_mem_reader IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mem_reader
    PORT(
         Clk : IN  std_logic;
         Rst : IN  std_logic;
         FrameLen : IN  std_logic_vector(10 downto 0);
         FrameIval : IN  std_logic_vector(27 downto 0);
         BusPkt : OUT  std_logic;
         BusData : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal FrameLen : std_logic_vector(10 downto 0) := (others => '0');
   signal FrameIval : std_logic_vector(27 downto 0) := (others => '0');

 	--Outputs
   signal BusPkt : std_logic;
   signal BusData : std_logic_vector(7 downto 0);

	signal Clk_o	: std_logic;

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
	 Clk_o <= transport Clk after 8 ns;
	 
	-- Instantiate the Unit Under Test (UUT)
   uut: mem_reader PORT MAP (
          Clk => Clk,
          Rst => Rst,
          FrameLen => FrameLen,
          FrameIval => FrameIval,
          BusPkt => BusPkt,
          BusData => BusData
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
		FrameLen		<= b"000" & X"4c";
		FrameIval	<= ( 7 => '1', others => '0' );
		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
      wait for Clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
