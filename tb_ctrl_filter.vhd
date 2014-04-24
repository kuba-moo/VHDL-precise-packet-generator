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
 
ENTITY tb_ctrl_filter IS
END tb_ctrl_filter;
 
ARCHITECTURE behavior OF tb_ctrl_filter IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ctrl_filter
    port (Clk      : in  std_logic;
          Rst      : in  std_logic;
          PktIn    : in  std_logic;
          DataIn   : in  std_logic_vector (7 downto 0);
          PktOut   : out std_logic;
          DataOut  : out std_logic_vector (7 downto 0);
          CtrlEn   : out std_logic;
          CtrlData : out std_logic_vector (7 downto 0));
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Rst : std_logic := '0';
   signal PktIn : std_logic := '0';
   signal ByteIn : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal PktOut : std_logic;
   signal ByteOut : std_logic_vector(7 downto 0);
   signal CtrlEn : std_logic;
   signal CtrlData : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ctrl_filter PORT MAP (
          Clk => Clk,
          Rst => Rst,
          PktIn => PktIn,
          DataIn => ByteIn,
          PktOut => PktOut,
          DataOut => ByteOut,
          CtrlEn => CtrlEn,
          CtrlData => CtrlData
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

      wait for Clk_period*10;
	
		for j in 0 to 15 loop
		
			PktIn <= '1';
			for i in 1 to 7 loop
				ByteIn <= x"55";
				wait for Clk_period;
			end loop;
			ByteIn <= x"d5";
			wait for Clk_period;
			ByteIn <= x"00";
			wait for Clk_period * 9;
			for i in 1 to 15 loop
				ByteIn <= CONV_std_logic_vector(i, 8);
				wait for Clk_period;
			end loop;
			PktIn <= '0';
			wait for Clk_period*10;
		
		end loop;
		
      wait;
   end process;

END;
