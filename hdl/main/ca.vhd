-- cellular automata.
-- computes the generation g+1 from the generation g on a window
--                WIDTH
-- ------------------------------------------------
-- |      N_CELL                                  |
-- |     --------                                 | HEIGHT
-- |     |      | 3 rows                          |
-- |     --------                                 |
-- |        |                                     |
-- |        v                                     |
-- ------------------------------------------------

library CELLOUX;
use CELLOUX.all;

entity ca is
  port(
    clk: in bit;
    WIDTH:            in positive;   -- the world width, total number of cell rows (e.g. 1280)
    HEIGHT:           in positive;   -- the world height, total number of cell columns (e.g. 840)
    -- read / write signals to start reading / writing
    READY_READING:  in std_ulogic; -- in_register is ready to be read
    READY_WRITING: in std_ulogic; -- out_register is ready to be written
    DONE_READING: out std_ulogic; -- the in_register has been read
    DONE_WRITING: out std_ulogic; -- the out_register has been written
    -- n state of the world, 3 rows at a time of width BUFFER_SIZE
    in_register:   in COLOR_VECTOR(0 to N_CELL-1); -- south cell colors
                                                                -- we only need this one as our window is gliding

    -- n+1 state of the world to be written in memory
    out_register:     out COLOR_VECTOR(0 to N_CELL-1) -- the output colors 
                                                                -- this is the north register
  );

architecture arc of ca is

begin
  signal cells: window; -- the cells translated from the colors, 3 x N_CELL
  signal DONE_COMPUTING std_ulogic;
  
  input: process(clk)
    if READY_READING = '1' and rising_edge(clk) then 
      for i in 0 to ( N_CELL-1 ) loop -- we slide the widow towards the south
        cells(0)(i) <= cells(1)(i);
        cells(1)(i) <= cells(2)(i);
        cells(2)(i)  <= color2cell (in_register(i));

      end loop;
      DONE_WRITING <= 1; -- tell the in_register we're done
      new_data <= 1; -- we can trust the computation of the generation g
    end if;
  end process input;


  GEN: for i in 1 to ( N_CELL-2 ) generate -- we create N_CELL-2 cells, mapped with each others
    CELL: entity CELLOUX.CELL(syn)
    port map(clk, 1, DONE_COMPUTING, cells(0)(i), cells(0)(i+1), cells(1)(i+1), cells(2)(i+1), cells(2)(i), cells(2)(i-1), cells(1)(i-1), cells(0)(i-1), new_cells(i));
  end generate GEN;

  output: process(clk)
    if rising_edge(clk) and READY_WRITING = '1' and new_data = '1' then
    for i in 1 to ( N_CELL-2 ) loop
      out_register(i) <= cell2color(new_cells(i)); -- we translate the state into a color
    end loop;
    new_data <= '0';
    DONE_WRITING <= '1';
  end process;

end;

