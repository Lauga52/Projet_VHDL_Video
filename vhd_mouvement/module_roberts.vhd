library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity module_roberts is
  port (
	in_active_area	: in std_logic;
	iY				: in std_logic_vector(7 downto 0) ; --image pixel
	oY				: out std_logic_vector(7 downto 0); --output pixel
  ) ;
end entity ; -- module_roberts

--TODO : c/c l'entity module_memoire_ligne


architecture arch of module_roberts is

begin

	--TODO : instantiation de la memoire ligne
	u1: module_memoire_ligne
	



	process_roberts : process( in_active_area, iY1, iY2, threshold )
	begin
		if in_active_area = '1' then
			if (unsigned(iY1) > (unsigned(iY2)+unsigned(threshold))) then
				oY<=X"EB";	-- pixel blanc
			elsif (unsigned(iY2) > (unsigned(iY1)+unsigned(threshold))) then
				oY<=X"EB";	-- pixel blanc
			else	
				oY<=X"10";	-- pixel noir
			end if;
		else
			oY<=X"10";	-- pixel noir
		end if;	
	end process ; -- process_roberts
	
end architecture ; -- arch

--
-- 1er cycle : lecture + traitement
-- 2e cycle : ecriture + registres
--
