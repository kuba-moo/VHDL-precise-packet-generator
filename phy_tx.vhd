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

-- Simple ethernet TX
-- 	takes data from bus, puts it into a async FIFO, kicks it onto the wire

entity phy_tx is
    Port ( clk 		: in  STD_LOGIC;
           rst 		: in  STD_LOGIC;
           PhyTxd 	: out STD_LOGIC_VECTOR (3 downto 0);
           PhyTxEn 	: out STD_LOGIC;
           PhyTxClk 	: in  STD_LOGIC;
			  PhyTxEr 	: out STD_LOGIC;
			  Led 		: out std_logic_vector(1 downto 0);
			  -- Some temporary debug stuff
			  value		: out std_logic_vector(15 downto 0);
			  sw			: in  std_logic_vector(7 downto 0);
			  
           data 		: in  STD_LOGIC_VECTOR (7 downto 0);
           busPkt 	: in  STD_LOGIC;
           busDesc 	: in  STD_LOGIC
			  );
end phy_tx;

architecture Behavioral of phy_tx is
	signal fifo_full, fifo_re, fifo_empty, fifo_valid : STD_LOGIC;
	signal fifo_dout	: std_logic_vector(3 downto 0);
	
	COMPONENT async_fifo_tx
	  PORT (
		 rst : IN STD_LOGIC;
		 wr_clk : IN STD_LOGIC;
		 rd_clk : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 wr_en : IN STD_LOGIC;
		 rd_en : IN STD_LOGIC;
		 dout : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 full : OUT STD_LOGIC;
		 empty : OUT STD_LOGIC;
		 valid : OUT STD_LOGIC
	  );
	END COMPONENT;
		
	-- Fifo has nibbles swapped
	signal pktDataX	: STD_LOGIC_VECTOR(7 DOWNTO 0);
begin
	PhyTxEr	<= '0';
	PhyTxEn	<= fifo_valid;
	PhyTxd	<= fifo_dout;
	pktDataX <= data(3 downto 0) & data(7 downto 4);
	fifo_re	<= not fifo_empty;

	Led(1)	<= not fifo_empty;
	Led(0)	<= fifo_full;

	xclk_fifo : async_fifo_tx
	  PORT MAP (
		 rst => rst,
		 wr_clk => clk,
		 rd_clk => PhyTxClk,
		 din => pktDataX,
		 wr_en => busPkt,
		 rd_en => fifo_re,
		 dout => fifo_dout,
		 full => fifo_full,
		 empty => fifo_empty,
		 valid => fifo_valid
	  );
	  
	main: process (PhyTxClk)
		variable cnt : STD_LOGIC_VECTOR(9 downto 0);
	begin
		if RISING_EDGE(PhyTxClk) then
			if fifo_valid = '1' then
				if cnt(9 downto 2) = sw then
					case cnt(1 downto 0) is
						when b"10" =>
							value( 3 downto  0) <= fifo_dout;
						when b"11" =>
							value( 7 downto  4) <= fifo_dout;
						when b"00" =>
							value(11 downto  8) <= fifo_dout;
						when b"01" =>
							value(15 downto 12) <= fifo_dout;
						when others =>
							value <= ( others => '0' );
					end case;
				end if;
				
				cnt := cnt + 1;
			else
   			cnt := (others => '0');
			end if;
						
			if rst = '1' then
				value <= (others => '0');
			end if;
		end if;
	end process;
	  
end Behavioral;

