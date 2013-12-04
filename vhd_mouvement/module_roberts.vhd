library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity module_roberts is
  generic (
		address_size : integer:=8 --TODO : coder 8 en dur ?
		--word_size : integer:=8
		);
  port (
  	CLK			: in std_logic;
	RESET		: in std_logic;	
 	in_active_area	: in std_logic;
	iY				: in std_logic_vector(7 downto 0) ; --pixel courant
	oY				: out std_logic_vector(7 downto 0) --output pixel
  );
end entity; -- module_roberts






architecture arch of module_roberts is



component module_memoire_ligne
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
end component;




--sjgnaux
signal pixel_lig_prec			: std_logic_vector(7 downto 0) ;
signal pixel_prec			: std_logic_vector(7 downto 0) ;
signal address_cur			: std_logic_vector(7 downto 0) ;
signal sig_data_out			: std_logic_vector(7 downto 0) ;
signal read_write			: std_logic;

begin

	u1: module_memoire_ligne
	
	generic map(
		address_size => address_size
	)
		
	port map(
		CLK => CLK,
		RESET => RESET,			
		address	=> address_cur,
		data_in	=> iY,
		data_out => sig_data_out,
		read_write => read_write
	);
	
	


	process_roberts : process(CLK, RESET) --signal iY was modified : incoming pixel
	
	variable var_data_out : std_logic_vector(7 downto 0) ;
	variable var_data_in : std_logic_vector(7 downto 0) ;
	variable var_pixel_lig_prec : std_logic_vector(7 downto 0) ;
	variable var_pixel_prec : std_logic_vector(7 downto 0) ;
	variable var_oY : std_logic_vector(7 downto 0) ;
	
	
	begin
		if CLK'event and CLK='1' then
			if in_active_area = '1' then
				
				if RESET = '1' then 
					read_write <='0';
				
			
				elsif read_write = '0' then -- on va faire une lecture en memoire_ligne
				
					-- mise à jour des variables :
					var_data_out := sig_data_out;
					var_data_in := iY;
					var_pixel_lig_prec := pixel_lig_prec;
					var_pixel_prec := pixel_prec;
				
					-- Calcul du filtrage :
					var_oY := iY + sig_data_out - pixel_lig_prec - pixel_prec;
				
				
					-- mise à jour des signaux mais effectif en sortant du process
					pixel_lig_prec <= var_data_out; --valeur future de pixel_lig_prec = valeur presente de sig_data_out
					pixel_prec <= var_data_in; --valeur future de pixel_prec = valeur presente de iY
				

					oY <= var_oY;
					read_write <='1';
				
					
				elsif read_write = '1' then -- on va faire une ecriture en memoire_ligne
					
					--iY est ecrit en memoire_ligne via data_in					
					address_cur <= address_cur+1;	
					read_write <='0';
		
				end if;	
				
			end if;
				
		end if;
					
	end process ; -- process_roberts
	
end architecture ; -- arch

--
-- 1er cycle : lecture + traitement
-- 2e cycle : ecriture + registres
--...
