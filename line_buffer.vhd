library IEEE;

use IEEE.std_logic_116.all;
use IEEE.numeric_std.all;

package types is
type t_line_out is array ( natural range <>) of std_logic_vector ;
type t_line_buffer is array ( natural range <> ) of std_logic_vector;
type t_line_buffer_complete is array ( natural range <>) of t_line_buffer;  

end package types;

entity line_buffer 
generic (
	FILTER_SIZE : INTEGER:=3;
	IMAGE_WIDTH : INTEGER := 80; --just arbitrary values
)
port (
	clk , rst : in std_logic;
	valid_in : std_logic;
	last_pixel : in std_logic;
	last_line : in std_logic;
	pixel_in : std_logic_vector ( 15 downto 0 );
	line_out_data : out t_line_out ( 0 to 2 )( 15 downto 0 ): ( others => ( others => '0'));
	valid : out std_logic


)
end entity line_buffer;

architecture rtl of line_buffer is
signal line_buffers : t_line_buffer_complete ( 0 to FILTER_SIZE ) (0 to IMAGE_WIDTH - 1) ( 15 downto 0 ) := ( others => ( others => ( others => '0' ))) ; --1 line buffer plus per parallel computing
signal x , y ,  : unsigned ( 6 downto 0 ) := ( others => '0'); --we refer to x the line buffers , line buffer 1 , line buffer 2 etc
--y to address where to write the value and suby which one to process , maybe also the same could be fine , just in case
--not really efficient processing better some more pipelined implementation, but just for beginning
-- or better just use integer 0 to 3
signal suby , subx : unsigned (1 downto 0):= "00"; -- no need for the if else logic to check 3 or 4 , since subx max 0 to 3
signal start, start_process  : std_logic := '0';

begin
process (clk )
	if rising_edge ( clk )
		if start = '0' then
			-- do nothing
			valid <= '0';
		else
			valid <= '1';
			for i in 0 to 2 loop
				line_out_data(i) <= line_buffers ( sub_x + i mod 4 )(sub_y); --pretty messy but it should work
			end loop;
			if sub_y = IMAGE_WIDTH - 1 then
				sub_y <= ( others => '0');
			else
				sub_y <= sub_y + 1;
			end if;
		end if;
end process;
					
process ( clk )
	if rising_edge ( clk ) then
		if valid_in = '1' then
			line_buffers ( to_integer(x) )(to_integer (y)) <= pixel_in;
			y <= y + 1;
			if last_pixel = '1' then
			--== Initial address for the 3 lines to output , once we have loaded the first 3 lines , for each line we load, we get a new
			-- sub_x so a new 3 lines to use
				if start = '1' then
					if sub_x = 3 then
						sub_x <= 0
						
					else
						sub_x <= sub_x + 1;
					end if;
				end if;
		--=========The first time we the line buffer is sending data
				if start = '0' and x = 2 then
					start <= '1';
				end if;
		--===Wrap around for the line buffer number
				y <= ( others => '0');
				if x = 3 then
					x <= 0;
				else 
					x <= x + 1 ; --lower the bit width of x , not needed
				end if;
		--=================
									
				
			end if;
			
end process;
end architecture rtl;
