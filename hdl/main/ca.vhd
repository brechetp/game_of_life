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
library ieee;
use ieee.std_logic_1164.all;
library celloux_lib;
use celloux_lib.pack_cell.all;
library WORK;
use WORK.main_pkg.all;

entity ca is
  port(
    clk: in std_ulogic;
    arstn: in std_ulogic;
    -- read / write signals to start reading / writing
    DONE_READING:  in std_ulogic; -- in_register is ready to be read
    DONE_WRITING: in std_ulogic; -- out_register is ready to be written, it has been written into mem
    READY_READING: out std_ulogic; -- the in_register has been read, it can now be changed by ADDR_CTR
    READY_WRITING: out std_ulogic; -- the out_register has been written
    -- n state of the world, 3 rows at a time of width BUFFER_SIZE
    in_register:   in CELL_VECTOR; -- south cell colors
                                                                -- we only need this one as our window is gliding

    -- n+1 state of the world to be written in memory
    out_register:     out CELL_VECTOR; -- the output colors 
    new_data: inout std_ulogic
                                                                -- this is the north register
  );
end entity ca;

architecture arc of ca is

  signal cells: window; -- the cells translated from the colors, 3 x N_CELL
  signal new_cells: CELL_VECTOR(0 to N_CELL-1);

begin
  
  input: process(clk)
  begin
    if clk = '1' then
      new_data <= '0'; -- if raised, the new generation is in new_cells
      if ((DONE_READING = '1') and DONE_WRITING = '1' and rising_edge(clk)) then -- if both of the in and out registers are ready
        for i in 0 to ( N_CELL-1 ) loop -- we slide the widow towards the south
          cells(0,i) <= cells(1,i);
          cells(1,i) <= cells(2,i);
          cells(2,i)  <= (in_register(i));
        end loop;
        READY_READING <= '1'; -- tells the mem the in_register has been read, DONE_READING will be set to 0
        new_data <= '1'; -- we can trust the computation of the generation g
      end if;
    end if;
  end process input;


  GEN: for i in 1 to ( N_CELL-2 ) generate -- we create N_CELL-2 cells, mapped with each others
    CELL: entity CELLOUX_LIB.CELL(syn)
    port map(clk, '1', cells(0,i), cells(0,i+1), cells(1,i+1), cells(2,i+1), cells(2,i), cells(2,i-1), cells(1,i-1), cells(0,i-1), new_cells(i));
  end generate GEN;

  output: process(clk)
  begin
    READY_WRITING <= '0'; -- we set READY_WRITING to 0 unless we write it
    if (rising_edge(clk) and (DONE_WRITING = '1') and (new_data = '1')) then
      for i in 1 to ( N_CELL-2 ) loop
        out_register(i) <= new_cells(i); -- we translate the state into a color
      end loop;
      READY_WRITING <= '1'; -- the DONE_WRITING will be set to 0
    end if;
  end process;

end;

