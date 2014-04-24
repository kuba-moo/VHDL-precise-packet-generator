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
 
ENTITY tb_stat_reader IS
END tb_stat_reader;
 
ARCHITECTURE behavior OF tb_stat_reader IS 
 
    COMPONENT stat_reader
    PORT(
         Clk 			:  IN  std_logic;
         Rst 			:  IN  std_logic;
         Trgr 			:  IN  std_logic;
         MemAddr 		: OUT  std_logic_vector(8 downto 0);
         MemData	 	:  IN  std_logic_vector(35 downto 0);
         ByteOut		: OUT  std_logic_vector(7 downto 0);
         ByteEna 		: OUT  std_logic;
         ReaderBusy	:  IN  std_logic
        );
    END COMPONENT;
    
	 COMPONENT uart_tx
    PORT(
         Clk : IN  std_logic;
         Rst : IN  std_logic;
         FreqEn : IN  std_logic;
         Byte : IN  std_logic_vector(7 downto 0);
         Kick : IN  std_logic;
         RsTx : OUT  std_logic;
         Busy : OUT  std_logic
        );
    END COMPONENT;

   --Inputs
   signal Clk 			: std_logic := '0';
   signal Rst 			: std_logic := '1';
   signal Trgr 		: std_logic := '0';
   signal MemData 	: std_logic_vector(35 downto 0) := X"582ABCDEF";
   signal ReaderBusy : std_logic := '0';

   signal FreqEn 		: std_logic := '0';
   signal Byte 		: std_logic_vector(7 downto 0) := X"AA";
   signal Kick 		: std_logic := '0';
	
 	--Outputs
   signal MemAddr 	: std_logic_vector(8 downto 0);
   signal ByteOut 	: std_logic_vector(7 downto 0);
   signal ByteEna 	: std_logic;

   signal RsTx 		: std_logic;
   signal Busy 		: std_logic;

   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
	Byte			<= ByteOut;
	Kick			<= ByteEna;
	ReaderBusy 	<= Busy;
 
	-- Instantiate the Unit Under Test (UUT)
   uut: stat_reader PORT MAP (
          Clk => Clk,
          Rst => Rst,
          Trgr => Trgr,
          MemAddr => MemAddr,
          MemData => MemData,
          ByteOut => ByteOut,
          ByteEna => ByteEna,
          ReaderBusy => ReaderBusy
        );

   uut2: uart_tx PORT MAP (
          Clk => Clk,
          Rst => Rst,
          FreqEn => FreqEn,
          Byte => Byte,
          Kick => Kick,
          RsTx => RsTx,
          Busy => Busy
        );

   -- Clock process definitions
   Clk_process :process 
   begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
   end process;
	
	-- Frequenct enable process
   Freq_process :process
   begin
		FreqEn <= '0';
		wait for Clk_period * 2;
		FreqEn <= '1';
		wait for Clk_period;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      wait for 100 ns;	
      Rst <= '0';
		
		Trgr <= '1';
		wait for 100 ns;	
		Trgr <= '0';
		wait for Clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
