library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity module_roberts is
  generic (
		address_size : integer:=8; 
		word_size : integer:=8
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
		address_size : integer:=8; --TODO : coder 8 en dur ?
		word_size : integer
		);
port (
		CLK			: in std_logic;
		RESET		: in std_logic;		
		address 	: in std_logic_vector(address_size-1 downto 0);
		data_in		: in std_logic_vector(word_size-1 downto 0);
		data_out	: out std_logic_vector(word_size-1 downto 0);
		read_write	: in std_logic
		);
end component;





--sjgnaux
signal address_cur			: std_logic_vector(address_size-1 downto 0) ;
signal read_write			: std_logic;

signal pixel_lig_prec		: std_logic_vector(7 downto 0):= (others => '0');
signal pixel_prec			: std_logic_vector(7 downto 0):= (others => '0');
signal data_out				: std_logic_vector(7 downto 0):= (others => '0');

signal G					: std_logic_vector(15 downto 0):= (others => '0') ; --attention : multiplication !

signal G_prec1				: std_logic_vector(15 downto 0):= (others => '0');
signal G_prec2				: std_logic_vector(15 downto 0):= (others => '0');
signal data_out_g1			: std_logic_vector(15 downto 0):= (others => '0');
signal G_ligne_prec1_g1		: std_logic_vector(15 downto 0):= (others => '0');
signal G_ligne_prec2_g1		: std_logic_vector(15 downto 0):= (others => '0');
signal data_out_g2			: std_logic_vector(15 downto 0):= (others => '0');
signal G_ligne_prec1_g2		: std_logic_vector(15 downto 0):= (others => '0');
signal G_ligne_prec2_g2		: std_logic_vector(15 downto 0):= (others => '0');

signal Max_G 				: std_logic_vector(15 downto 0):= (others => '0');



begin

	mem_ligne_pix: module_memoire_ligne
	
	generic map(
		address_size => address_size,
		word_size => word_size
	)
		
	port map(
		CLK => CLK,
		RESET => RESET,			
		address	=> address_cur,
		data_in	=> iY,
		data_out => data_out,
		read_write => read_write
	);
	
	
	mem_ligne_grad1: module_memoire_ligne
	
	generic map(
		address_size => address_size,
		word_size => 16
	)
		
	port map(
		CLK => CLK,
		RESET => RESET,			
		address	=> address_cur,
		data_in	=> G,
		data_out => data_out_g1,
		read_write => read_write
	);
	
	
	mem_ligne_grad2: module_memoire_ligne
	
	generic map(
		address_size => address_size,
		word_size => 16
	)
		
	port map(
		CLK => CLK,
		RESET => RESET,			
		address	=> address_cur,
		data_in	=> data_out_g1,
		data_out => data_out_g2,
		read_write => read_write
	);
	



	process_roberts : process(CLK, RESET) --signal iY was modified : incoming pixel
	
	function Max(a,b:std_logic_vector)
		return std_logic_vector is
			begin
				if a>b then
					return a;
				else
					return b;
				end if;
			end Max;
	
	
	
	
	variable var_data_out : std_logic_vector(7 downto 0) ;
	variable var_data_in : std_logic_vector(7 downto 0) ;
	variable var_pixel_lig_prec : std_logic_vector(7 downto 0) ;
	variable var_pixel_prec : std_logic_vector(7 downto 0) ;
	variable var_oY : std_logic_vector(7 downto 0) ;
	variable var_Gv : std_logic_vector(7 downto 0) ;
	variable var_Gh : std_logic_vector(7 downto 0) ;
	
	variable d0		: std_logic_vector(15 downto 0) ;
	variable d1		: std_logic_vector(15 downto 0) ;	
	variable d2		: std_logic_vector(15 downto 0) ;	
	variable d3		: std_logic_vector(15 downto 0) ;
	
	variable var_G_Max	: std_logic_vector(15 downto 0) ;
	
	begin
		if CLK'event and CLK='1' then
			if in_active_area = '1' then
				
				if RESET = '0' then 
					read_write <='0';
					address_cur <="00000000";
					
					pixel_lig_prec <= (others => '0');
					pixel_prec <= (others => '0');
					--data_out <= (others => '0');
					G <= (others => '0') ; --attention multiplication !
					G_prec1 <= (others => '0');
					G_prec2 <= (others => '0');
					--data_out_g1 <= (others => '0');
					G_ligne_prec1_g1 <= (others => '0');
					G_ligne_prec2_g1 <= (others => '0');
					--data_out_g2 <= (others => '0');
					G_ligne_prec1_g2 <= (others => '0');
					G_ligne_prec2_g2 <= (others => '0');
					Max_G <= (others => '0');

			
				elsif read_write = '0' then -- on va faire une lecture en memoire_ligne
				
				-- **** Calculs :
				
					-- affectation des variables :
					var_data_out := data_out;
					var_data_in := iY;
					var_pixel_lig_prec := pixel_lig_prec;
					var_pixel_prec := pixel_prec;
				
					-- Calcul du filtrage :
					var_Gh := iY + data_out - pixel_lig_prec - pixel_prec;
					var_Gv := -iY + data_out + pixel_lig_prec - pixel_prec;
					G <= var_Gv*var_Gv + var_Gh*Var_Gh;		--TODO : verifier que tout ca tient en un cycle			
					

					-- calcul du max :
					
					d0:=abs(data_out_g2-G_prec2);
					d1:=abs(data_out_g1-G_ligne_prec2_g1);
					d2:=abs(G-G_ligne_prec2_g2);
					d3:=abs(G_prec1-G_ligne_prec1_g2);
					var_G_Max:=Max(Max(d0,d1),Max(d2,d3)); --direction dominante
					
					-- G_ligne_prec1_g1 est le point central du voisinage 3-3
					if var_G_Max = d0 then
						if G_ligne_prec1_g1 >= G and G_ligne_prec1_g1 >= G_ligne_prec2_g2 then
							oY <= (others => '1'); --unsigned
						else
							oY <= (others => '0');
						end if;
					elsif var_G_Max = d1 then
						if G_ligne_prec1_g1 >= data_out_g1 and G_ligne_prec1_g1 >= G_ligne_prec2_g1 then
							oY <= (others => '1'); --unsigned
						else
							oY <= (others => '0');
						end if;
					elsif var_G_Max = d2 then
						if G_ligne_prec1_g1 >= G and G_ligne_prec1_g1 >= G_ligne_prec2_g2 then
							oY <= (others => '1'); --unsigned
						else
							oY <= (others => '0');
						end if;
					elsif var_G_Max = d3 then
						if G_ligne_prec1_g1 >= G_prec1 and G_ligne_prec1_g1 >= G_ligne_prec1_g2 then
							oY <= (others => '1'); --unsigned
						else
							oY <= (others => '0');
						end if;
					end if;
						

					
				-- **** mise a jour des signaux mais effectif en sortant du process
					
					-- memoire ligne "pixels"
					pixel_lig_prec <= var_data_out; 
					pixel_prec <= var_data_in; 

					--memoires lignes "gradients"				
						--registres (signaux)
					G_prec2 <= G_prec1;
					G_prec1 <= G;
						--signaux (reliés aux memoires lignes)
					G_ligne_prec2_g1 <= G_ligne_prec1_g1;
					G_ligne_prec1_g1 <= data_out_g1;
					G_ligne_prec2_g2 <= G_ligne_prec1_g2;
					G_ligne_prec1_g2 <= data_out_g2;
										
					
					
					
				
					read_write <='1'; --on va activer l'ecriture dans la memoire_ligne_pix et dans les memoires grads
					

					
				
					
				elsif read_write = '1' then -- on va faire une ecriture dans les memoire_lignes
					
					--Ecriture de iY en memoire_ligne via data_in, de data_out_g1 et data_out_g2				
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

