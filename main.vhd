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

Library UNISIM;
use UNISIM.vcomponents.all;

entity main is
    Port ( clk : 	in  STD_LOGIC;
			  seg : 	out STD_LOGIC_VECTOR(6 downto 0);
			  an : 	out STD_LOGIC_VECTOR(3 downto 0);
			  Led : 	out STD_LOGIC_VECTOR(7 downto 0);
			  sw : 	in	 STD_LOGIC_VECTOR(7 downto 0);
           btn : 	in  STD_LOGIC_VECTOR(4 downto 0);
			  PhyMdc	:		out STD_LOGIC;
			  PhyMdio :		inout STD_LOGIC;
			  PhyRstn : 	out STD_LOGIC;
			  PhyRxd : 		in  STD_LOGIC_VECTOR(3 downto 0);
			  PhyRxDv : 	in  STD_LOGIC;
			  PhyRxClk : 	in  STD_LOGIC;
			  PhyTxd : 		out STD_LOGIC_VECTOR(3 downto 0);
			  PhyTxEn : 	out STD_LOGIC;
			  PhyTxClk :	in  STD_LOGIC;
			  PhyTxEr	:	out STD_LOGIC;
			  RsTx		:	out STD_LOGIC);
end main;

architecture Behavioral of main is
	-- Turn button into reset - active '1'
	signal rst	: STD_LOGIC;
	signal btnD	: std_logic;
	
	component debouncer is
	PORT( clk 			: in  STD_LOGIC;
			input 		: in  STD_LOGIC;
			output		: out  STD_LOGIC);
	end component;
	
	COMPONENT enable_to_kick
	PORT(	Clk			: IN std_logic;
			Enable 		: IN std_logic;          
			Kick 			: OUT std_logic);
	END COMPONENT;
	
	-- General purpose counters
	COMPONENT counter
   GENERIC (N_BITS : integer);
	PORT(	Clk			: IN std_logic;
			Rst			: IN std_logic;          
			Cnt		 	: OUT std_logic_vector(63 downto 0));
	END COMPONENT;
	signal cnt64 : std_logic_vector(63 downto 0);
	
	COMPONENT counter_en
   GENERIC (N_BITS : integer);
	PORT(	Clk 			: IN std_logic;
			Rst 			: IN std_logic;  
			Enable 		: in std_logic;
			Cnt 			: OUT std_logic_vector(N_BITS - 1 downto 0));
	END COMPONENT;
	signal cnt_underflow_en, cnt_rx_pkt_en, cnt_rx_ctrl_en, cnt_tx_pkt_en : std_logic;
	signal cnt_underflow, cnt_rx_pkt, cnt_rx_ctrl, cnt_tx_pkt : std_logic_vector(35 downto 0);

	COMPONENT disp
	PORT(	clk_i 		: IN std_logic;
			rst_i 		: IN std_logic;
			data_i 		: IN std_logic_vector(15 downto 0);          
			led_an_o		: OUT std_logic_vector(3 downto 0);
			led_seg_o 	: OUT std_logic_vector(6 downto 0));
	END COMPONENT;
	signal digit, d_tx : std_logic_vector(15 downto 0);

	-- Ethernet control module
	COMPONENT ethernet_control
	PORT(
		clk 				: IN std_logic;
		rst 				: IN std_logic;
		cnt_23 			: IN std_logic;
		cnt_22 			: IN std_logic;          
		PhyRstn 			: OUT std_logic
		);
	END COMPONENT;

	-- MDIO programming
	
	COMPONENT mdio_ctrl
	PORT(	clk 			: IN std_logic;
			rst			: IN std_logic;
			cnt_5 		: IN std_logic;
			cnt_23 		: IN std_logic;
			mdio_i 		: IN std_logic;
			op 			: IN std_logic;
			addr 			: IN std_logic_vector(4 downto 0);
			data_i 		: IN std_logic_vector(15 downto 0);
			kick 			: IN std_logic;          
			mdc 			: OUT std_logic;
			mdio_o 		: OUT std_logic;
			mdio_t 		: OUT std_logic;
			data_o 		: OUT std_logic_vector(15 downto 0);
			busy 			: OUT std_logic);
	END COMPONENT;
	signal mdio_trgr	: STD_LOGIC;
	signal mdio_i, mdio_o, mdio_t : STD_LOGIC;
	signal mdio_op, mdio_kick, mdio_busy : STD_LOGIC;
	signal mdio_addr				: STD_LOGIC_VECTOR(4 downto 0);
	signal mdio_in, mdio_out	: STD_LOGIC_VECTOR(15 downto 0);
	COMPONENT mdio_set_100Full
	PORT( clk 			:  in  STD_LOGIC;
			rst 			:  in  STD_LOGIC;
			mdio_op 		: out  STD_LOGIC;
			mdio_addr 	: out  STD_LOGIC_VECTOR (4 downto 0);
			data_i 		:  in  STD_LOGIC_VECTOR (15 downto 0);
			data_o 		: out  STD_LOGIC_VECTOR (15 downto 0);
			mdio_busy 	:  in  STD_LOGIC;
			mdio_kick	: out  STD_LOGIC;
				  
			mnl_addr		:	in	 STD_LOGIC_VECTOR (4 downto 0);
			mnl_trgr		:	in	 STD_LOGIC;
			cfg_busy		: out	 STD_LOGIC);
	END COMPONENT;
	signal mdio_cfg_busy			: STD_LOGIC;

	-- RX: Ethernet receive path
	
	COMPONENT ethernet_receive
	PORT( clk 			: IN	std_logic;
			rst 			: IN	std_logic;
			PhyRxd 		: IN	std_logic_vector(3 downto 0);
			PhyRxDv 		: IN	std_logic;
			PhyRxClk 	: IN	std_logic;
			Led 			: out std_logic_vector(4 downto 0);
			data			: out STD_LOGIC_VECTOR(7 downto 0);
			busPkt		: out STD_LOGIC;
			busDesc		: out STD_LOGIC);
	END COMPONENT;
	signal phyPkt, phyDesc : STD_LOGIC;
	signal phyData		: std_logic_vector(7 downto 0);
	
	COMPONENT bus_tail_strip
   GENERIC (N_BYTES 	: integer);
   PORT( Clk     		: in  std_logic;
         PktIn   		: in  std_logic;
         DataIn  		: in  std_logic_vector(7 downto 0);
         PktOut  		: out std_logic;
         DataOut 		: out std_logic_vector(7 downto 0));
	END COMPONENT;
	signal rxCrcPkt	: STD_LOGIC;
	signal rxCrcData	: std_logic_vector(7 downto 0);

	COMPONENT bus_get_last_nbits
   GENERIC (N_BITS : integer);
   PORT( Clk     		: in  std_logic;
			Rst			: in  std_logic;
         PktIn   		: in  std_logic;
         DataIn  		: in  std_logic_vector(7 downto 0);
         Value   		: out std_logic_vector(N_BITS - 1 downto 0);
         ValueEn 		: out std_logic);
	END COMPONENT;
	signal rxPktTs		: std_logic_vector(63 downto 0);
	signal rxPktTsKick: std_logic;

	-- CONTROL path
	
	COMPONENT ctrl_filter
	PORT(	Clk 			: IN std_logic;
			Rst 			: IN std_logic;
			PktIn 		: IN std_logic;
			DataIn 		: IN std_logic_vector(7 downto 0);          
			PktOut 		: OUT std_logic;
			DataOut 		: OUT std_logic_vector(7 downto 0);
			CtrlEn 		: OUT std_logic;
			CtrlData 	: OUT std_logic_vector(7 downto 0));
	END COMPONENT;
	signal ctrl_dout, ctrl_cout	: std_logic_vector(7 downto 0); 
	signal ctrl_de, ctrl_ce 		: std_logic;

	COMPONENT ctrl_regs
	PORT(	Clk 			: IN std_logic;
			PktIn			: IN std_logic;
			DataIn 		: IN std_logic_vector(7 downto 0);          
			PktOut 		: OUT std_logic;
			DataOut 		: OUT std_logic_vector(7 downto 0);
			Regs 			: OUT std_logic_vector(79 downto 0));
	END COMPONENT;
	signal ctrl_pout	: std_logic_vector(7 downto 0); 
	signal ctrl_pe		: std_logic;
	signal regs	: std_logic_vector(79 downto 0);
	
	signal reg_delay	: std_logic_vector(31 downto 0);
	signal reg_fival	: std_logic_vector(31 downto 0);
	signal reg_flen	: std_logic_vector(15 downto 0);
		
	COMPONENT ctrl_write_mem
	PORT(	Clk 			: IN std_logic;
			PktIn 		: IN std_logic;
			DataIn		: IN std_logic_vector(7 downto 0);          
			MemAddr 		: OUT std_logic_vector(10 downto 0);
			MemData 		: OUT std_logic_vector(7 downto 0);
			MemWe 		: OUT std_logic);
	END COMPONENT;
	signal ctrl_mem_addr : std_logic_vector(10 downto 0);
	signal ctrl_mem_data : std_logic_vector(7 downto 0);
	signal ctrl_mem_we	: std_logic;
	
	COMPONENT packet_mem
	PORT( clka 			: IN STD_LOGIC;
			wea 			: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra 		: IN STD_LOGIC_VECTOR(10 DOWNTO 0);
			dina 			: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
				
	-- TX: Ethernet tramsmit path
			
			clkb 			: IN STD_LOGIC;
			addrb 		: IN STD_LOGIC_VECTOR(10 DOWNTO 0);
			doutb 		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;
	signal pkt_mem_addr : std_logic_vector(10 downto 0);
	signal pkt_mem_dout : std_logic_vector(7 downto 0);
	
	COMPONENT mem_reader
	PORT(	Clk 			:  IN std_logic;
			Rst 			:  IN std_logic;
			Enable		:	IN	std_logic;
			FrameLen 	:  IN std_logic_vector(10 downto 0);
			FrameIval	:  IN std_logic_vector(27 downto 0);    
			MemAddr		: out STD_LOGIC_VECTOR (10 downto 0);
			MemData		:  IN STD_LOGIC_VECTOR (7 downto 0);      
			BusPkt 		: OUT std_logic;
			BusData 		: OUT std_logic_vector(7 downto 0));
	END COMPONENT;	
	signal memPkt		: STD_LOGIC;
	signal memData		: std_logic_vector(7 downto 0);
	signal TX_en		: std_logic;
	
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
	signal tsPkt		: STD_LOGIC;
	signal tsData		: std_logic_vector(7 downto 0);
	
	COMPONENT eth_add_crc
	PORT(	Clk 			: IN std_logic;
			Rst 			: IN std_logic;
			InPkt 		: IN std_logic;
			InData 		: IN std_logic_vector(7 downto 0);          
			OutPkt 		: OUT std_logic;
			OutData 		: OUT std_logic_vector(7 downto 0));
	END COMPONENT;
	signal crcPkt		: STD_LOGIC;
	signal crcData		: std_logic_vector(7 downto 0);

	COMPONENT phy_tx is
    Port ( clk 		: in  STD_LOGIC;
           rst 		: in  STD_LOGIC;
           PhyTxd 	: out STD_LOGIC_VECTOR (3 downto 0);
           PhyTxEn 	: out STD_LOGIC;
           PhyTxClk 	: in  STD_LOGIC;
			  PhyTxEr 	: out STD_LOGIC;
			  Led 		: out std_logic_vector(1 downto 0);
			  
			  value		: out std_logic_vector(15 downto 0);
			  sw			: in  std_logic_vector(7 downto 0);
			  
           data 		: in  STD_LOGIC_VECTOR (7 downto 0);
           busPkt 	: in  STD_LOGIC;
           busDesc 	: in  STD_LOGIC);
	end COMPONENT;

	-- Statistics path

	COMPONENT stat_calc
	PORT(	Time64			: IN std_logic_vector(63 downto 0);
			Delay 			: IN std_logic_vector(31 downto 0);
			Value 			: IN std_logic_vector(63 downto 0);
			KickIn 			: IN std_logic;          
			Output 			: OUT std_logic_vector(63 downto 0);
			KickOut 			: OUT std_logic;
			Underflow		: out std_logic);
	END COMPONENT;
	
	COMPONENT stat_compress
	PORT(	Clk 			: IN std_logic;
			Value 		: IN std_logic_vector(63 downto 0);
			KickIn 		: IN std_logic;          
			Statistic 	: OUT std_logic_vector(8 downto 0);
			KickOut 		: OUT std_logic);
	END COMPONENT;
	signal stat_cprs_val						: std_logic_vector(63 downto 0);
	signal stat_cprs_kick					: std_logic;

	COMPONENT stat_writer
	PORT( Clk     		: in  std_logic;
         Rst     		: in  std_logic;
         MemWe   		: out std_logic_vector(0 downto 0);
         MemAddr 		: out std_logic_vector(8 downto 0);
         MemDin  		: out std_logic_vector(35 downto 0);
         MemDout 		: in  std_logic_vector(35 downto 0);
         Value  		: in  std_logic_vector(8 downto 0);
         Kick    		: in  std_logic);
	END COMPONENT;
	signal stat_wr_kick						: std_logic;
	signal stat_wr_we							: std_logic_vector(0 downto 0);
	signal stat_wr_dout, stat_wr_din		: std_logic_vector(35 downto 0);
	signal stat_wr_addr, stat_wr_value	: std_logic_vector(8 downto 0);

	COMPONENT stat_mem
	PORT( clka 			:  IN STD_LOGIC;
			wea 			:  IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra 		:  IN STD_LOGIC_VECTOR(8 DOWNTO 0);
			dina 			:  IN STD_LOGIC_VECTOR(35 DOWNTO 0);
			douta 		: OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
			clkb 			:  IN STD_LOGIC;
			web 			:  IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addrb 		:  IN STD_LOGIC_VECTOR(8 DOWNTO 0);
			dinb 			:  IN STD_LOGIC_VECTOR(35 DOWNTO 0);
			doutb 		: OUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	END COMPONENT;

	signal dump_autokick_en, dump_autokick : std_logic;
	signal stat_dump_kick, regs_dump_kick : std_logic;

	COMPONENT stat_reader
	PORT(	Clk 			:  IN std_logic;
			Rst 			:  IN std_logic;
			Trgr	 		:  IN std_logic;
			MemData 		:  IN std_logic_vector(35 downto 0);  
			MemAddr 		: OUT std_logic_vector(8 downto 0);
			ByteOut 		: OUT std_logic_vector(7 downto 0);
         Request    	: OUT std_logic;
         Grant      	:  IN std_logic;
         ByteEna  	: OUT std_logic;
         ReaderBusy	:  IN std_logic);
	END COMPONENT;
	signal stat_reader_trgr	: std_logic;
	signal stat_read_dout	: std_logic_vector(35 downto 0);
	signal stat_read_addr	: std_logic_vector(8 downto 0);	
	signal stat_uart_byte	: std_logic_vector(7 downto 0);
	signal stat_uart_kick	: std_logic;
	
	COMPONENT reg_dumper is
   GENERIC (N_BYTES : integer);
   PORT( Clk        	: in  std_logic;
         Rst        	: in  std_logic;
         Trgr       	: in  std_logic;
         Regs       	: in  std_logic_vector (N_BYTES * 8 - 1 downto 0);
         Request    	: out std_logic;
         Grant      	: in  std_logic;
         Byte       	: out std_logic_vector (7 downto 0);
         ByteEna    	: out std_logic;
         ReaderBusy 	: in  std_logic);
	END COMPONENT;
	signal regs_to_dump		: std_logic_vector(223 downto 0);
	signal reg_uart_byte		: std_logic_vector(7 downto 0);
	signal reg_uart_kick		: std_logic;
	
	COMPONENT semaphore_cyclic IS
   GENERIC (N_BITS : integer);
   PORT( Clk     		: in  std_logic;
         Rst     		: in  std_logic;
         Request 		: in  std_logic_vector (N_BITS-1 downto 0);
         Grant   		: out std_logic_vector (N_BITS-1 downto 0));
	END COMPONENT;
	signal req_uart : std_logic_vector(1 downto 0);
	signal grt_uart : std_logic_vector(1 downto 0);
	
	signal uart_byte			: std_logic_vector(7 downto 0);
	signal uart_kick, uart_busy : std_logic;
	
	COMPONENT uart_tx
	PORT( Clk : IN std_logic;
			Rst : IN std_logic;
			FreqEn : IN std_logic;
			Byte : IN std_logic_vector(7 downto 0);
			Kick : IN std_logic;          
			RsTx : OUT std_logic;
			Busy : OUT std_logic);
	END COMPONENT;	
	
	COMPONENT freq_generator
	GENERIC (FREQUENCY : integer );
	PORT( Clk : IN std_logic;
			Rst : IN std_logic;          
			Output : OUT std_logic);
	END COMPONENT;
	signal uart_freq_en : std_logic;
	
	signal LinkUp		: STD_LOGIC;
	
BEGIN
	
	LinkUp	<=	not mdio_cfg_busy;
	
	btnC_db : debouncer port map (clk, btn(0), rst);
	btnU_db : debouncer port map (clk, btn(1), mdio_trgr);
	
	btnD_db : debouncer PORT MAP (clk, btn(3), btnD);
	btnR_db : debouncer PORT MAP (clk, btn(4), stat_reader_trgr);
		
	counter64: counter 
	GENERIC MAP( N_BITS => 64 )
	PORT MAP(
		Clk 		=> clk,
		Rst		=> rst,
		Cnt 		=> cnt64
	);
	Inst_ethernet_control: ethernet_control PORT MAP(
		clk		=> clk,
		rst		=> rst,
		cnt_23	=> cnt64(23),
		cnt_22	=> cnt64(22),
		PhyRstn	=> PhyRstn
	);
	
	Inst_disp: disp PORT MAP(
		clk_i		=> clk,
		rst_i		=> rst,
		data_i	=> digit,
		led_an_o	=> an,
		led_seg_o=> seg
	);
	
	mdio_iobuf : IOBUF 
	generic map (IOSTANDARD => "LVCMOS33")
	port map (
           O	=> mdio_i,
           IO	=> PhyMdio,
           I	=> mdio_o,
           T	=> mdio_t
          );
	Inst_mdio_ctrl: mdio_ctrl PORT MAP(
		clk 		=> clk,
		rst 		=> rst,
		cnt_5 	=> cnt64(5),
		cnt_23 	=> cnt64(23),
		mdc 		=> PhyMdc,
		mdio_i	=> mdio_i,
		mdio_o	=> mdio_o,
		mdio_t	=> mdio_t,
		op 		=> mdio_op,
		addr 		=> mdio_addr,
		data_i 	=> mdio_in,
		data_o 	=> mdio_out,
		busy 		=> mdio_busy,
		kick 		=> mdio_kick
	);
	Inst_mdio_set_100Full: mdio_set_100Full PORT MAP(
		clk		=> clk,
		rst 		=> rst,
		mdio_op 	=> mdio_op,
		mdio_addr => mdio_addr,
		data_i 	=> mdio_out,
		data_o 	=> mdio_in,
		mdio_busy => mdio_busy,
		mdio_kick => mdio_kick,
		mnl_addr	=> sw(4 downto 0),
		mnl_trgr	=> mdio_trgr,
		cfg_busy => mdio_cfg_busy
	);
	Led(7) <= mdio_cfg_busy;

	-- RX path

	eth_rx : ethernet_receive PORT MAP(
		clk 		=> clk,
		rst 		=> rst,
		Led 		=> Led(4 downto 0),
		PhyRxd 	=> PhyRxd,
		PhyRxDv 	=> PhyRxDv,
		PhyRxClk => PhyRxClk,	
		busPkt 	=> phyPkt,
		busDesc 	=> phyDesc,
		data 		=> phyData
	);
	
	strip_crc: bus_tail_strip GENERIC MAP (N_BYTES => 4)
	PORT MAP(
		Clk 		=> clk,
		PktIn 	=> phyPkt,
		DataIn 	=> phyData,
		PktOut 	=> rxCrcPkt,
		DataOut 	=> rxCrcData
	);
	
	get_tail : bus_get_last_nbits GENERIC MAP (N_BITS => 64)
	PORT MAP(
		Clk 		=> clk,
		Rst		=> rst,
		PktIn 	=> ctrl_de,
		DataIn 	=> ctrl_dout,
		Value		=> rxPktTs,
		ValueEn	=> rxPktTsKick
	);
	
	-- CONTROL path
	
	CONTROL_filter: ctrl_filter PORT MAP(
		Clk 		=> clk,
		Rst 		=> rst,
		PktIn 	=> rxCrcPkt,
		DataIn 	=> rxCrcData,
		PktOut 	=> ctrl_de,
		DataOut 	=> ctrl_dout,
		CtrlEn 	=> ctrl_ce,
		CtrlData => ctrl_cout
	);
		
	CONTROL_regs: ctrl_regs PORT MAP(
		Clk 		=> clk,
		PktIn 	=> ctrl_ce,
		DataIn 	=> ctrl_cout,
		PktOut 	=> ctrl_pe,
		DataOut 	=> ctrl_pout,
		Regs 		=> regs
	);

	reg_delay	<= regs(79 downto 48);
	reg_fival	<= regs(47 downto 16);
	reg_flen		<= regs(15 downto 0);
	
	CONTROL_write_mem: ctrl_write_mem PORT MAP(
		Clk 		=> clk,
		PktIn 	=> ctrl_pe,
		DataIn 	=> ctrl_pout,
		MemAddr 	=> ctrl_mem_addr,
		MemData 	=> ctrl_mem_data,
		MemWe 	=> ctrl_mem_we
	);

	pkt_mem : packet_mem port map (
		clka		=> clk,
		wea(0)	=> ctrl_mem_we,
		addra		=> ctrl_mem_addr,
		dina		=>	ctrl_mem_data,

	-- TX path				

		clkb		=> clk,
		addrb		=> pkt_mem_addr,
		doutb		=> pkt_mem_dout
	);
	
	TX_mem_reader: mem_reader PORT MAP(
		Clk		=> clk,
		Rst		=> rst,
		Enable	=>	TX_en,
		FrameLen => reg_flen(10 downto 0), -- b"001" & X"22",
		FrameIval=> reg_fival(27 downto 0), -- ( 14 => '1', others => '0' ),
		MemAddr	=> pkt_mem_addr,
		MemData	=> pkt_mem_dout,
		BusPkt 	=> memPkt,
		BusData 	=> memData
	);
	TX_en <= LinkUp and sw(7);
	
	TX_eth_add_ts: bus_append 
	GENERIC MAP ( N_BYTES => 8 )
	PORT MAP(
		Clk 		=> Clk,
		Rst 		=> Rst,
		Value		=> cnt64,
		InPkt 	=> memPkt,
		InData 	=> memData,
		OutPkt 	=> tsPkt,
		OutData	=> tsData
	);
	
	TX_eth_add_crc: eth_add_crc PORT MAP(
		Clk 		=> clk,
		Rst		=> rst,
		InPkt 	=> tsPkt,
		InData 	=> tsData,
		OutPkt 	=> crcPkt,
		OutData	=> crcData
	);
	
	TX_eth_tx : phy_tx PORT MAP (
		clk		=> clk,
		rst		=> rst,
		Led		=> Led(6 downto 5),
		PhyTxd	=> PhyTxd, 
      PhyTxEn	=> PhyTxEn,
		PhyTxClk	=> PhyTxClk,
		PhyTxEr	=> PhyTxEr,
		
		value		=> d_tx,
		sw			=> sw,
			  
		busPkt	=> crcPkt,
		busDesc	=> '0',
		data		=> crcData
	);
	digit <= mdio_out when mdio_trgr = '1' else
				d_tx;
		
	-- Statistics path

	STAT_stat_calc: stat_calc PORT MAP(
		Time64 		=> cnt64,
		Delay 		=> reg_delay, -- X"0007A120", -- 5ms
		Value 		=> rxPktTs,
		KickIn 		=> rxPktTsKick,
		Output 		=> stat_cprs_val,
		KickOut		=> stat_cprs_kick,
		Underflow	=> cnt_underflow_en
	);
	
	STAT_stat_compress: stat_compress PORT MAP(
		Clk 			=> clk,
		Value 		=> stat_cprs_val,
		KickIn 		=> stat_cprs_kick,
		Statistic 	=> stat_wr_value,
		KickOut 		=> stat_wr_kick
	);
	
	STAT_stat_writer: stat_writer PORT MAP(
		Clk 			=> clk,
		Rst 			=> rst,
		MemWe 		=> stat_wr_we,
		MemAddr	 	=> stat_wr_addr,
		MemDin 		=> stat_wr_din,
		MemDout 		=> stat_wr_dout,
		Value 		=> stat_wr_value,
		Kick 			=> stat_wr_kick
	);
	
	statistics_memory : stat_mem PORT MAP (
		clka 			=> clk,
		wea 			=> stat_wr_we,
		addra 		=> stat_wr_addr,
		dina 			=> stat_wr_din,
		douta 		=> stat_wr_dout,
		clkb 			=> clk,
		web 			=> "0",
		addrb 		=> stat_read_addr,
		dinb 			=> ( others => '0' ),
		doutb 		=> stat_read_dout
	);

	E2K_dump_autokick : enable_to_kick PORT MAP(clk, cnt64(31), dump_autokick_en);
	dump_autokick <= dump_autokick_en and sw(6);
	
	stat_dump_kick <= stat_reader_trgr or dump_autokick when rising_edge(clk);
	DUMP_stat_reader: stat_reader PORT MAP(
		Clk 			=> clk,
		Rst 			=> rst,
		Trgr 			=> stat_dump_kick,
		MemData 		=> stat_read_dout,
		MemAddr 		=> stat_read_addr,
		Request		=> req_uart(0),
		Grant			=> grt_uart(0),
		ByteOut 		=> stat_uart_byte,
		ByteEna 		=> stat_uart_kick,
		ReaderBusy 	=> uart_busy
	);
	
	
	CNT_udrfl	: counter_en GENERIC MAP (N_BITS => 36) 
										 PORT MAP(clk, rst, cnt_underflow_en, cnt_underflow);
	E2K_rx_pkt : enable_to_kick PORT MAP(clk, ctrl_de, cnt_rx_pkt_en);
	CNT_rxpkt : counter_en GENERIC MAP (N_BITS => 36) 
									 PORT MAP(clk, rst, cnt_rx_pkt_en, cnt_rx_pkt);
	E2K_rx_ctrl : enable_to_kick PORT MAP(clk, ctrl_ce, cnt_rx_ctrl_en);
	CNT_rxctrl	: counter_en GENERIC MAP (N_BITS => 36) 
									 PORT MAP(clk, rst, cnt_rx_ctrl_en, cnt_rx_ctrl);
	E2K_tx_pkt : enable_to_kick PORT MAP(clk, memPkt, cnt_tx_pkt_en);
	CNT_txpkt : counter_en GENERIC MAP (N_BITS => 36) 
									 PORT MAP(clk, rst, cnt_tx_pkt_en, cnt_tx_pkt);
	
	regs_to_dump <= cnt_underflow & cnt_rx_pkt & cnt_rx_ctrl & cnt_tx_pkt & regs;
	regs_dump_kick <= btnD or dump_autokick;
	
	DUMP_REGS : reg_dumper GENERIC MAP (N_BYTES => 28)
	PORT MAP(
		Clk			=> clk,
		Rst			=> rst,
		Trgr			=> regs_dump_kick,
		Regs			=> regs_to_dump,
		Request		=> req_uart(1),
		Grant			=> grt_uart(1),
		Byte			=> reg_uart_byte,
		ByteEna		=> reg_uart_kick,
		ReaderBusy	=> uart_busy
	);
	
	SEM_uart : semaphore_cyclic GENERIC MAP (N_BITS => 2)
	PORT MAP( clk, rst, req_uart, grt_uart );
	
	uart_kick <= stat_uart_kick OR reg_uart_kick;
	uart_byte <= stat_uart_byte OR reg_uart_byte;
		
	STAT_uart_tx: uart_tx PORT MAP(
		Clk 			=> clk,
		Rst 			=> rst,
		FreqEn 		=> uart_freq_en,
		Byte 			=> uart_byte,
		Kick 			=> uart_kick,
		RsTx 			=> RsTx,
		Busy 			=> uart_busy
	);
	
	STAT_uart_freq : freq_generator
	GENERIC MAP (FREQUENCY => 9600 )
	PORT MAP( Clk => clk,
				 Rst => rst,
				 Output => uart_freq_en
   );
		
end Behavioral;

