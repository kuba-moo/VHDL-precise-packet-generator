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

entity ethernet_receive is
    Port ( clk : in  STD_LOGIC;
           rst : in STD_LOGIC;
			  PhyRxd		: in STD_LOGIC_VECTOR(3 downto 0);
			  PhyRxDv	: in STD_LOGIC;
			  PhyRxClk	: in STD_LOGIC;
			  Led 		: OUT std_logic_vector(4 downto 0);			  
			  data		: out STD_LOGIC_VECTOR(7 downto 0);
			  busPkt		: out STD_LOGIC;
			  busDesc	: out STD_LOGIC
			  );
end ethernet_receive;

architecture Behavioral of ethernet_receive is

	signal len_fifo_din, len_fifo_dout : STD_LOGIC_VECTOR(10 DOWNTO 0);
	signal len_fifo_we, len_fifo_re, len_fifo_full, len_fifo_empty : STD_LOGIC;

	COMPONENT packet_len_fifo
	  PORT (
		 rst : IN STD_LOGIC;
		 wr_clk : IN STD_LOGIC;
		 rd_clk : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		 wr_en : IN STD_LOGIC;
		 rd_en : IN STD_LOGIC;
		 dout : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
		 full : OUT STD_LOGIC;
		 empty : OUT STD_LOGIC
	  );
	END COMPONENT;

	signal fifo_re, fifo_full, fifo_empty, fifo_underflow, fifo_valid : STD_LOGIC;
	signal fifo_dout : STD_LOGIC_VECTOR(7 downto 0);
	COMPONENT async_fifo_rx
	  PORT (
		 rst : IN STD_LOGIC;
		 wr_clk : IN STD_LOGIC;
		 rd_clk : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 wr_en : IN STD_LOGIC;
		 rd_en : IN STD_LOGIC;
		 dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 full : OUT STD_LOGIC;
		 empty : OUT STD_LOGIC;
		 valid : OUT STD_LOGIC;
		 underflow : OUT STD_LOGIC
	  );
	END COMPONENT;
	
	-- Fifo has nibbles swapped
	signal pktData, pktDataX	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal oldValid				: STD_LOGIC;

	type ro_state_t is (RO_IDLE, 
							  RO_READ_LEN, RO_WRITE_DESC_0, RO_WRITE_DESC_1,
							  RO_READ_PKT);

	signal ro_state				: ro_state_t := RO_IDLE;
	signal NEXT_ro_state			: ro_state_t;
	signal ro_len					: STD_LOGIC_VECTOR(10 DOWNTO 0);
	signal ro_cnt, NEXT_ro_cnt	: STD_LOGIC_VECTOR(10 DOWNTO 0);

begin		
	underflowTest : process (clk)
		variable prev : STD_LOGIC := '0';
	begin
		if RISING_EDGE(clk) then
			prev := prev or fifo_underflow;
			led(4) <= prev;
			
			if rst = '1' then
				prev := '0';
			end if;
		end if;
	end process;
		
	
	packet_lens : packet_len_fifo
		  PORT MAP (
			 rst		=> rst,
			 
			 rd_clk	=> clk,
			 rd_en	=> len_fifo_re,
			 dout		=> len_fifo_dout,
			 empty	=> len_fifo_empty,
			 
			 wr_clk	=> PhyRxClk,
			 wr_en	=> len_fifo_we,
			 din		=> len_fifo_din,
			 full		=> len_fifo_full
		  );

	Led(2) <= len_fifo_full;
	Led(3) <= not len_fifo_empty;

	-- Processes in Phy clock domain that count frame lengths
	oldValid <= PhyRxDv when RISING_EDGE(PhyRxClk);

	eth_count_len: process (PhyRxClk)
		variable counter : STD_LOGIC_VECTOR(11 downto 0);
	begin
		if RISING_EDGE(PhyRxClk) then
			-- No need for reset here 
			--  Phy reset will cause Dv to drop low
			--  FIFO will be in reset so it will not take the length in
			len_fifo_we		<= '0';

			-- Add to fifo
			if oldValid = '1' and PhyRxDv = '0' then
				len_fifo_we	<= '1';
			end if;

			-- Count Dv = '1' cycles
			if PhyRxDv = '1' then
				counter	:= counter + 1;
			end if;	
			
			len_fifo_din	<= counter(11 downto 1);
						
			if PhyRxDv = '0' then
				counter 	:= (others => '0');
			end if;
		end if;
	end process;
	
	xclk_fifo : async_fifo_rx
		  PORT MAP (
			 rst		=> rst,
			 
			 rd_clk	=> clk,
			 rd_en	=> fifo_re,
			 dout		=> fifo_dout,
			 empty	=> fifo_empty,
			 valid	=> fifo_valid,
			 underflow => fifo_underflow,
			 
			 wr_clk	=> PhyRxClk,
			 din		=> PhyRxd,
			 wr_en	=> PhyRxDv,
			 full		=> fifo_full
		  );

	busPkt	<= fifo_valid;
	pktDataX	<= fifo_dout;
	pktData	<= pktDataX(3 downto 0) & pktDataX(7 downto 4);
	Led(0)	<= fifo_full;
	Led(1)	<= not fifo_empty;

	fsm : process (ro_state, ro_cnt, ro_len, pktData, len_fifo_empty, NEXT_ro_cnt)
	begin
		NEXT_ro_state	<= ro_state;
		NEXT_ro_cnt		<= ro_cnt + 1;
		
		len_fifo_re 	<= '0';
		fifo_re			<= '0';
		
		busDesc			<= '0';
		data				<= pktData;
		
		case ro_state is 
			when RO_IDLE =>
				if len_fifo_empty = '0' then
					NEXT_ro_state	<= RO_READ_LEN;
					len_fifo_re		<= '1';				
				end if;
									
			when RO_READ_LEN =>
				NEXT_ro_state	<= RO_WRITE_DESC_0;
				
			when RO_WRITE_DESC_0 =>
				NEXT_ro_state	<= RO_WRITE_DESC_1;			
				
				busDesc <= '1';
				data <= "00000" & ro_len(10 downto 8);
				
			when RO_WRITE_DESC_1 =>
				NEXT_ro_state	<= RO_READ_PKT;
				NEXT_ro_cnt		<= ( others => '0' );
				
				busDesc <= '1';
				data <= ro_len(7 downto 0);	

			when RO_READ_PKT =>
				fifo_re	<= '1';
					
				if NEXT_ro_cnt = ro_len then
					NEXT_ro_state	<= RO_IDLE;
				end if;
		end case;
				
	end process;
	
	NEXT_fsm : process (clk)
	begin
		if RISING_EDGE(clk) then
			ro_state <= NEXT_ro_state;
			ro_cnt	<= NEXT_ro_cnt;

			if ro_state = RO_READ_LEN then
				ro_len	<= len_fifo_dout;
			end if;
						
			if rst = '1' then
				ro_state <= RO_IDLE;
			end if;
		end if;
	end process;
	
end Behavioral;

