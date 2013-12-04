library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity filtre_video is
	generic (
			size	: integer := 8 	-- taille de la sous-fenetre = 2**size pixels
			);
    port (
			--horloge et reset
			CLK			: in std_logic; -- clock à 54 MHz
			RESET 		: in std_logic; -- reset à 0 			
			-- flux video à 27 MHz
			-- synchro
			VGA_X :	in std_logic_vector(10 downto 0); -- compteur pixels
			VGA_Y :	in std_logic_vector(10 downto 0); -- compteur lignes
			-- entrée
			iY : 	in std_logic_vector(7 downto 0); -- flux video entrant : luminance
			iCb : 	in std_logic_vector(7 downto 0); -- flux video entrant : chrominance bleu
			iCr : 	in std_logic_vector(7 downto 0); -- flux video entrant : chrominance rouge
			-- sortie
			oY	: 	out std_logic_vector(7 downto 0); -- flux video sortant : luminance
			oCb	: 	out std_logic_vector(7 downto 0); -- flux video sortant : chrominance bleu
			oCr	: 	out std_logic_vector(7 downto 0); -- flux video sortant : chrominance rouge
			--switch D2E
			switch			: in std_logic_vector(17 downto 0);		-- à connecter à DPDT_SW;
			-- SRAM interfaces
			address_SRAM 	: out std_logic_vector(17 downto 0); 	-- à connecter à SRAM_ADDR
			data_SRAM		: inout std_logic_vector(15 downto 0);  -- à connecter à SRAM_DQ
			write_enable 	: out std_logic; 						-- à connecter à SRAM_WE_N
			read_enable 	: out std_logic; 						-- à connecter à SRAM_OE_N
			chip_enable 	: out std_logic;						-- à connecter à SRAM_CE_N 
			high_mask 		: out std_logic ; 						-- à connecter à SRAM_UB_N
			low_mask 		: out std_logic 			
			);			
end entity filtre_video;


architecture A of filtre_video is

component module_fenetrage
	generic (
			size			: integer := 8
			);
	port (
			VGA_X 			:	in std_logic_vector(10 downto 0);
			VGA_Y 			:	in std_logic_vector(10 downto 0);			
			iY 				: 	in std_logic_vector(7 downto 0);
			oY				: 	out std_logic_vector(7 downto 0);
			in_active_area 	:	out std_logic;
			X_cpt			:	out std_logic_vector(10 downto 0);
			Y_cpt			:	out std_logic_vector(10 downto 0)
		);
end component;


component module_SRAM
    port (
			CLK				: 	in std_logic;
			RESET 			: 	in std_logic;			 
			--module top interface
			in_active_area	:	in std_logic;
			X_cpt			: 	in std_logic_vector(10 downto 0);
			Y_cpt			: 	in std_logic_vector(10 downto 0);
			data_in			:	in std_logic_vector(7 downto 0);
			data_out		: 	out std_logic_vector(7 downto 0);					
			-- SRAM interfaces
			address_SRAM 	: out std_logic_vector(17 downto 0); 	-- à connecter à SRAM_ADDR
			data_SRAM		: inout std_logic_vector(15 downto 0);  -- à connecter à SRAM_DQ
			write_enable 	: out std_logic; 						-- à connecter à SRAM_WE_N
			read_enable 	: out std_logic; 						-- à connecter à SRAM_OE_N
			chip_enable 	: out std_logic;						-- à connecter à SRAM_CE_N 
			high_mask 		: out std_logic ; 						-- à connecter à SRAM_UB_N
			low_mask 		: out std_logic  						-- à connecter à SRAM_LB_N
			);			
end component;


component module_roberts
  port (
	CLK			: in std_logic;
	RESET		: in std_logic;	
 	in_active_area	: in std_logic;
	iY				: in std_logic_vector(7 downto 0) ; --pixel courant
	oY				: out std_logic_vector(7 downto 0) --output pixel
  );
end component; -- module_roberts


--signaux flux video
signal sig_Y1			: std_logic_vector(7 downto 0) ;
signal sig_Y2			: std_logic_vector(7 downto 0) ;
signal sig_X    : std_logic_vector(7 downto 0) ;

--signaux de synchro module fentrage
signal Y_cpt			: std_logic_vector(10 downto 0);
signal X_cpt 			: std_logic_vector(10 downto 0);
signal in_active_area 	: std_logic;

--signaux debug

begin
	u_1: module_fenetrage 
	generic map(
			size => size
			)
	port map(
			VGA_X => VGA_X,
			VGA_Y => VGA_Y,                        
			iY        => iY,
			oY        => sig_Y1,
			in_active_area => in_active_area,
			X_cpt => X_cpt,
			Y_cpt => Y_cpt
			);
			
	u_2: module_SRAM
	port map(
			CLK => CLK,
			RESET => RESET,
			--module top
			in_active_area => in_active_area,
			X_cpt => X_cpt,
			Y_cpt => Y_cpt,
			data_in => sig_Y1,
			data_out => sig_X,
			-- SRAM
			address_SRAM => address_SRAM,
			data_SRAM => data_SRAM,	
			write_enable => write_enable,
			read_enable => read_enable,
			chip_enable => chip_enable,
			high_mask => high_mask,
			low_mask => low_mask
			);
	
	u_3 : module_roberts
	generic map(
			address_size => size
			)
	port map(
			in_active_area => in_active_area,
			iY => sig_Y1,
			oY=> sig_Y2,
			RESET => RESET,
			CLK => CLK
			--threshold=> threshold --pas besoin pour le filtrage
	);
	
	--concurent
--	threshold <= switch(17 downto 10);
	oCb <= X"80";		
	oCr <= X"80";

	--process
	process_affichage : process( switch, iY, sig_Y1, sig_Y2)
	begin
		case( switch(4 downto 0) ) is
			when "00000" => oY <= iY; -- avant fenetrage		
			when "00001" => oY <= sig_Y1; -- après fenetrage				
			when others  => oY <= sig_Y2;  -- après roberts
		end case ;
	end process ; -- process_affichage
	

end architecture A;	
