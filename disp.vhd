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

entity disp is
    Port ( clk_i : in  STD_LOGIC;
           rst_i : in  STD_LOGIC;
           data_i : in  std_logic_vector(15 downto 0);
           led_an_o : out  std_logic_vector(3 downto 0);
           led_seg_o : out  std_logic_vector(6 downto 0));
end disp;

architecture Behavioral of disp is

signal Reset : std_logic;
signal ena_o : std_logic;
signal seg_sel : std_logic_vector(3 downto 0);

begin

Reset <= rst_i when RISING_EDGE(clk_i);

led_an_o <= seg_sel;

logi: process (clk_i) is
variable clk_i_div : STD_LOGIC_VECTOR(16 downto 0);
begin
	if rising_edge(clk_i) then
		ena_o <= clk_i_div(16);
				
		if clk_i_div(16) = '1' then
				clk_i_div := (others => '0');
--		else 
--				ena_o <= '0';
		end if;
		
		clk_i_div := clk_i_div + 1;

		if Reset = '1' then
			clk_i_div := (others => '0');
		end if;
	end if;
end process logi;

enc_proc: process (clk_i) is
variable flop : integer range 0 to 3 := 0;
variable nibble : std_logic_vector(3 downto 0);
variable value : std_logic_vector(6 downto 0);
begin
	if rising_edge(clk_i) then
		if ena_o = '1' then
			seg_sel <= seg_sel(2 downto 0) & seg_sel(3);
			if flop = 3 then
				flop := 0;
			else
				flop := flop + 1;
			end if;		
			
			nibble := data_i(3 + flop * 4 downto flop * 4);

			case nibble is -- abcdefg
				when B"0000" => value := B"1000000"; -- B"00000011";
				when B"0001" => value := B"1111001"; -- B"10011111";
				when B"0010" => value := B"0100100"; -- B"00100101";
				when B"0011" => value := B"0110000"; -- B"00001101";
				when B"0100" => value := B"0011001"; -- B"10011001";
				when B"0101" => value := B"0010010"; -- B"01001001";
				when B"0110" => value := B"0000010"; -- B"01000001";
				when B"0111" => value := B"1111000"; -- B"00011111";
				when B"1000" => value := B"0000000"; -- B"00000001";
				when B"1001" => value := B"0010000"; -- B"00001001";
				when B"1010" => value := B"0001000"; -- B"00010001";
				when B"1011" => value := B"0000011"; -- B"11000001";
				when B"1100" => value := B"0100111"; -- B"11100101";
				when B"1101" => value := B"0100001"; -- B"10000101";
				when B"1110" => value := B"0000110"; -- B"01100001";
				when B"1111" => value := B"0001110"; -- B"01110001";
				when others => value := B"1111111";
			end case;
			led_seg_o <= value;
		end if;
		
		if Reset = '1' then
			seg_sel <= B"1110";
			flop := 0;
		end if;
  end if;
end process enc_proc;

end Behavioral;

