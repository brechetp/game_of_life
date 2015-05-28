-- buffer.vhd file
-- helps to fetch cells from memomy and store it in a buffer


entity buffer_in is                                         -- used to retrieve cells from memory
  generic (N:         POSITIVE range 1 to 1024 := 512);     -- N is the number of cells the AC can take care of simultaneoulsy
  port    (clk: std_logic;
  reset: std_logic;
  cells_in:  std_ulogic_vector(63 downto 0);       -- cell_in is 8-bit color, there are 8 of them on a mem fetch
          cells_out:  std_ulogic_vector(N*8 - 1 downto 0)); -- we map N of then to the output
end entity buffer_in;


  
