library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_signed.all;

--library lib_VIDEO;
--use lib_VIDEO.all;

entity bench is

end entity bench;

architecture A of bench is
	
	constant size : integer := 8;			
	
	component filtre_video 
		generic (
				size	: integer
				);
		port (
				CLK		: in std_logic; --clock à 54 Mhz
				RESET 		: in std_logic; -- reset à 0 
				-- flux video
				-- synchro
				VGA_X :	in std_logic_vector(10 downto 0);
				VGA_Y :	in std_logic_vector(10 downto 0);
				-- entrée
				iY : 	in std_logic_vector(7 downto 0);
				iCb : 	in std_logic_vector(7 downto 0);
				iCr : 	in std_logic_vector(7 downto 0);
				-- sortie
				oY	: 	out std_logic_vector(7 downto 0);
				oCb	: 	out std_logic_vector(7 downto 0);
				oCr	: 	out std_logic_vector(7 downto 0);

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
		end component filtre_video;
		
		
		component SRAM
		  	port (
			clk				: in std_logic;
		    -- SRAM interfaces
			address_SRAM 	: in std_logic_vector(17 downto 0); 	-- à connecter à SRAM_ADDR
			data_SRAM		: inout std_logic_vector(15 downto 0);  -- à connecter à SRAM_DQ
			write_enable 	: in std_logic; 						-- à connecter à SRAM_WE_N
			read_enable 	: in std_logic; 						-- à connecter à SRAM_OE_N
			chip_enable 	: in std_logic;							-- à connecter à SRAM_CE_N 
			high_mask 		: in std_logic ; 						-- à connecter à SRAM_UB_N
			low_mask 		: in std_logic
		  	) ;
		end component SRAM ;
		
		
		--horloge et reset
		signal CLK		: std_logic := '0'; --clock à 54 Mhz
		signal RESET 		: std_logic; -- reset à 0 
	
		-- flux video
		-- synchro
		signal VGA_X : std_logic_vector(10 downto 0) := (others => '0');
		signal VGA_Y : std_logic_vector(10 downto 0) := (others => '0');
		
		-- entrée
		signal iY :  std_logic_vector(7 downto 0):= (others => '0');
		signal iCb : std_logic_vector(7 downto 0);
		signal iCr :  std_logic_vector(7 downto 0);
		-- sortie
		signal oY	:  std_logic_vector(7 downto 0);
		signal oCb	:  std_logic_vector(7 downto 0);
		signal oCr	:  std_logic_vector(7 downto 0);


		signal switch : std_logic_vector(17 downto 0);

		-- SRAM interfaces
		signal address_SRAM 	:  std_logic_vector(17 downto 0); 	-- à connecter à SRAM_ADDR
		signal data_SRAM		:  std_logic_vector(15 downto 0);  -- à connecter à SRAM_DQ
		signal write_enable 	:  std_logic; 						-- à connecter à SRAM_WE_N
		signal read_enable 		:  std_logic; 						-- à connecter à SRAM_OE_N
		signal chip_enable 		:  std_logic;						-- à connecter à SRAM_CE_N 
		signal high_mask 		:  std_logic; 						-- à connecter à SRAM_UB_N
		signal low_mask 		:  std_logic;
		
		signal Compt : std_logic_vector(7 downto 0):= (others => '0');
		
		
				
begin

	filtre : filtre_video
		generic map(
		size => size
		)
		port map(
		CLK	=> CLK,
		RESET 	=> RESET,
		VGA_X => VGA_X, 
		VGA_Y => VGA_Y,
		iY  => iY,
		iCb => iCb,
		iCr => iCr,
		oY => oY,
		oCb	=> oCb,
		oCr	=> oCr,
		switch => switch,
		address_SRAM => address_SRAM,
		data_SRAM => data_SRAM,
		write_enable => write_enable,
		read_enable => read_enable,
		chip_enable => chip_enable,
		high_mask => high_mask,
		low_mask => low_mask
		);
		
	memoire: SRAM
		port map(
		clk	=> CLK,
	    -- SRAM interfaces
		address_SRAM => address_SRAM,
		data_SRAM => data_SRAM,
		write_enable => write_enable,
		read_enable => read_enable,
		chip_enable => chip_enable,
		high_mask => high_mask,
		low_mask => low_mask
		) ;

	
	switch <= "000" & "00000000000" & "1111";
	
	CLK <= not(CLK) after 10 ns; -- simulation de l'horloge à 54 MHz
	RESET <= '0', '1' after 165 ns;
		
	iCb <= "10000000";
	iCr <= "10000000";
	
	process_simu : process(VGA_X, VGA_Y)
	variable temp : std_logic_vector(10 downto 0);
	

	
	begin
		if VGA_X < std_logic_vector(to_unsigned(2**size+5,11)) then
			VGA_X <= std_logic_vector(unsigned(VGA_X)+1) after 40 ns;
		else 	
			VGA_X <= (others => '0');
		end if;	
		
		if VGA_Y < std_logic_vector(to_unsigned(2**size+5,11)) then 
			VGA_Y <= std_logic_vector(unsigned(VGA_Y)+1) after (2**size+5)*40 ns;
		else
			VGA_Y <= (others => '0');
		end if;				

-- test 1 :		
--		iY <= std_logic_vector(unsigned(iY) + 1); 

-- test 2 :
--		temp := std_logic_vector(unsigned(VGA_X) + unsigned(VGA_Y(6 downto 0) & '0'));
--		iY <= temp(7 downto 0);
		
-- test 3 :				
--		temp := std_logic_vector(unsigned(VGA_Y));
--		iY <= temp(7 downto 0);

-- test 4 :
--		if VGA_Y < "00000000010" or VGA_Y > "0000001100" then
--			iY <= X"10";
--		else	
--			if VGA_X < "00000000010" or VGA_X > "0000001100" then
--				iY <= X"10";
--			else
--				iY <= X"EB";
--			end if;	
--		end if;		
--
-- test 5:
--
iY <= std_logic_vector(unsigned(iY) + unsigned(Compt));

Compt <=std_logic_vector(unsigned( Compt) + 1) after 40 ns; 

					
	end process ; -- process_simu
	
	iCb <= "10000000";
	iCr <= "10000000";

end architecture A;

			
		
					