-- module memoire_ligne
-- permet de stocker une ligne compl�te de pixel
-- et de la lire dans le sens inverse pour traitement anti-causal

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity module_memoire_ligne is
		generic (
		address_size : integer:=8 --TODO : coder 8 en dur ?
		--word_size : integer:=8
		);
	    port (
		CLK			: in std_logic;
		RESET		: in std_logic;		
		address 	: in std_logic_vector(7 downto 0);
		data_in		: in std_logic_vector(7 downto 0);
		data_out	: out std_logic_vector(7 downto 0);
		read_write	: in std_logic
		);
end entity module_memoire_ligne;


architecture A of module_memoire_ligne is

--signal
type mem_type is array (2**address_size - 1  downto 0) of std_logic_vector(7 downto 0);
signal memoire : mem_type;

begin
	process_RAM:process(CLK)
	begin
		if CLK='1' and CLK'event then
			if read_write = '1' then 	-- ecriture
				memoire(to_integer(unsigned(address))) <= data_in;
			end if;
		end if;		
	end process process_RAM;	
	
	data_out <= memoire(to_integer(unsigned(address))); --lecture asynchrone		
		
end architecture A;

