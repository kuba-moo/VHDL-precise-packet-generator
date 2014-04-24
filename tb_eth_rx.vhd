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
 
ENTITY tb_eth_rx IS
END tb_eth_rx;
 
ARCHITECTURE behavior OF tb_eth_rx IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ethernet_receive
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         PhyRxd : IN  std_logic_vector(3 downto 0);
         PhyRxDv : IN  std_logic;
         PhyRxClk : IN  std_logic;
         Led : OUT  std_logic_vector(4 downto 0);
			  -- Some temporary debug stuff
			  value		: out std_logic_vector(15 downto 0);
			  sw			: in  std_logic_vector(7 downto 0);
         data : OUT  std_logic_vector(7 downto 0);
         busPkt : OUT  std_logic;
         busDesc : OUT  std_logic
        );
    END COMPONENT;
	 COMPONENT phy_tx
	 PORT(
			clk : IN std_logic;
			rst : IN std_logic;
			PhyTxClk : IN std_logic;
			data : IN std_logic_vector(7 downto 0);
			busPkt : IN std_logic;
			busDesc : IN std_logic;          
			PhyTxd : OUT std_logic_vector(3 downto 0);
			PhyTxEn : OUT std_logic;
			PhyTxEr : OUT std_logic;
			Led : OUT std_logic_vector(1 downto 0);
			  -- Some temporary debug stuff
			  value		: out std_logic_vector(15 downto 0);
			  sw			: in  std_logic_vector(7 downto 0)
			);
	 END COMPONENT;

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal PhyRxd, PhyTxd : std_logic_vector(3 downto 0) := (others => '0');
   signal PhyRxDv, PhyTxEn : std_logic := '0';
   signal PhyRxClk : std_logic := '0';

 	--Outputs
   signal Led : std_logic_vector(4 downto 0);
   signal data : std_logic_vector(7 downto 0);
   signal busPkt, PhyTxEr : std_logic;
   signal busDesc : std_logic;

	signal LedTx : std_logic_vector(1 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant PhyRxClk_period : time := 42 ns;
 
	signal clk_o : std_logic;
 
BEGIN
	clk_o <= transport clk after 8 ns;
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ethernet_receive PORT MAP (
          clk => clk,
          rst => rst,
          PhyRxd => PhyRxd,
          PhyRxDv => PhyRxDv,
          PhyRxClk => PhyRxClk,
          Led => Led,
          data => data,
          busPkt => busPkt,
          busDesc => busDesc,
			 sw => ( others => '0' )
        );
	Inst_phy_tx: phy_tx PORT MAP(
		clk => clk,
		rst => rst,
		PhyTxd => PhyTxd,
		PhyTxEn => PhyTxEn,
		PhyTxClk => PhyRxClk,
		PhyTxEr => PhyTxEr,
		Led => LedTx,
		data => data,
		busPkt => busPkt,
		busDesc => busDesc,
			 sw => ( others => '0' )
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   PhyRxClk_process :process
   begin
		PhyRxClk <= '0';
		wait for PhyRxClk_period/2;
		PhyRxClk <= '1';
		wait for PhyRxClk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
		rst <= '1';
		wait for PhyRxClk_period * 2;
      -- hold reset state for 100 ns.
		rst <= '0';
		wait for PhyRxClk_period * 10;

		PhyRxDv	<= '1';
		PhyRxd	<= b"0001";
		wait for PhyRxClk_period;
		PhyRxd	<= b"0001";
		wait for PhyRxClk_period;
		for i in 0 to 15 loop
			PhyRxd	<= CONV_std_logic_vector(i, 4);
			wait for PhyRxClk_period;
		end loop;
		PhyRxd	<= b"0001";
		wait for PhyRxClk_period;
		PhyRxd	<= b"0001";
		wait for PhyRxClk_period;
		
		PhyRxDv	<= '0';
		PhyRxd	<= ( others => '0' );

      -- insert stimulus here 

      wait;
   end process;

END;
