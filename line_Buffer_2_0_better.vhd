library IEEE;

package helpers is
begin

--
--Just to make the loops easier ( nothing to do with synthesization just to make the development easier) define it as a matrix so we could index them easier
--But if having issues with the inference , cuz we may want it into a bram and not into registers then maybe we could need to define as a long array, but I 
--don't think it's the case
type t_window_row is array ( 0 to KERNEL_SIZE - 1 ) of std_logic_vector ( WIDTH - 1 downto 0 );
type t_window is array ( 0 to KERNEL_SIZE - 1) of t_window_row;

--SUBy COUNT we refer to the rows we need to pass to the output , and since they will rotate since we have a stride 1 horizontally but also vertically
--then we need to take into account which one is the first one and the next ones , technically our valid will be high only after the first 3 rows are filled
type t_suby_count is array ( 0 to KERNEL_SIZE - 1) of unsigned ( to_integer ( ceil ( log2(KERNEL_SIZE) )) - 1 downto 0 );

--We define the lines and line buffer , line buffer is just the 
type t_line is array (0 to IMAGE_WIDTH - 1 ) of std_logic_vector ( WIDTH - 1 downto 0 );
type t_line_buffer is array ( 0 to KERNEL_SIZE - 1) of t_line;


end package helpers;


use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.helpers.all;

entity line_buffer is
generic (
	KERNEL_SIZE : integer := 5;
	IMAGE_WIDTH : integer := 1920;
	WIDTH : integer := 8;
);
port (
	clk , rst : in  std_logic;
	data_in : in std_logic_vector ( WIDTH - 1 downto 0);
	window : out t_window := ( others => ( others =>'0'));
	valid : out std_logic
);


architecture rtl of line_buffer is

signal line_buffer : t_line_buffer;
signal x_count : unsigned ( to_integer(ceil ( log2 (IMAGE_WIDTH))) - 1 downto 0 ) := ( others => '0'); 
signal suby_count : t_suby_Count := (others => ( others => '0')); -- double check for these first values

signal start : std_logic; --we need to wait for the first 3 line buffers to be filled firstly on the frist implementation then we can start incrementing the suby_count, or only 2 line buffers on the second implementation, more info later

signal window_reg : t_window := ( others => (others => '0'));

signal we : std_logic_vector ( KERNEL_SIZE - 1 DOWNTO 0 ) := ((KERNEL_SIZE - 1 DOWNTO 1 => '0') , '1');

begin

--So because we want the stride, we shift the window ( to get the overlap effect ) and input the new value each time at the end of the window
--because of that at the beginning of the linebuffers we need to wait for KERNEL_SIZE clock cycles before we have the first valid window, otherwise it will alway be with garbage data mixed withd ata from older rows

KEEP_TRACK_OF_INDEXES :
process ( clk)
begin
	if rising_Edge ( clk ) then
		if rst = '1' then
			x_Count <= ( others => '0');
			for i in 0 to KERNEL_SIZE - 1 loop
				suby_Count ( i ) <= to_unsigned ( i , suby_count(0)'length);
			end loop;
			start <= '0';
			signal we <= ((KERNEL_SIZE - 1 DOWNTO 1 => '0') , '1');
		else
			x_count <= x_count + 1;
			if x_count < KERNEL_SIZE then
				 valid_reg <= '0';
				 if x_count = KERNEL_SIZE - 1 then
					valid_reg <= '1'
				 end if;
			end if;
			if x_count = IMAGE_WIDTH - 1 THEN
				x_count <= ( others => '0');
				we <= we (KERNEL_SIZE - 2 downto 0) & we (KERNEL_SIZE - 1);
				if start = '1' then
					for i in 0 to KERNEL_SIZE - 1 loop
						suby_count (i) <= suby_count (i) + 1;
						if suby_count (i) = KERNEL_SIZE-1 then
							suby_count ( i ) <= ( others => '0');
					end loop;
				else if line < KERNEL_SIZE  
					line <= line + 1 ;
					if line = KERNEL_SIZE - 1 then -- first implementation waits for them to be  filled first and then output
						start <= '1';
				end if;
			end if;




SHIFT_THE_WINDOW:process ( clk )
begin
	if rising_edge ( clk ) then
		if start = '1' then
		for I in 0 to kernel_size - 1 loop
			for j in 1 to kernel_size - 1 loop
				window_reg (i)(j-1) <= window_reg(I)(j);-- while the last value of the row gets the data from line buffer
			end loop;
				window_reg (i)(kernel_size - 1 ) <= line_buffer ( sub_y_count(i))( x_count ) ;
		end loop;
		end if;
	end if;
			


end process SHIFT_THE_WINDOW; 

WRITE_TO_LINE_BUFFERS:
process ( clk )
begin
	if rising_edge ( clk ) then
		for I in 0 to KERNEL_SIZE - 1 loop
		    if we ( I ) = '1' then	
			line_Buffer ( I ) ( x_count ) <= data_in;
			end if;
		    if start = '1' then
			line_out ( I ) <= line_buffer ( sub_y_count(i))( x_count );
		    end if;
		end loop;

end process WRITE_TO_LINE_BUFFERS; --infers bram that's why we have address and also an write enable
window <= window_reg;
valid <= valid_Reg;
end architecture rtl;
