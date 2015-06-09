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

entity cell_ctrl is
  port(
    clk, rstn: in std_ulogic; -- clock and synchronous reset
    -- read / write signals to start reading / writing
    DONE_READING:  in std_ulogic; -- read_cell_vector is ready to be read
    DONE_WRITING: in std_ulogic; -- write_cell_vector is ready to be written, it has been written into mem
    READY_READING: out std_ulogic; -- the read_cell_vector has been read, it can now be changed by ADDR_CTR
    READY_WRITING: out std_ulogic; -- the write_cell_vector is ready to be written in memory
    -- n state of the world, 3 rows at a time of width BUFFER_SIZE
    read_cell_vector: in CELL_VECTOR(0 to N_CELL-1); -- read cells from memory
                                                                -- we only need this one as our window is gliding

    -- n+1 state of the world to be written in memory
    write_cell_vector:     out CELL_VECTOR(0 to N_CELL-3) -- cells to be written to memory
                                      -- this is the north register
    -- lock: out std_ulogic
  );
end entity cell_ctrl;

architecture arc of cell_ctrl is

  signal cells: window; -- the cells translated from the colors, 3 x N_CELL
  signal new_cells: CELL_VECTOR(0 to N_CELL-1);
  signal new_data: std_ulogic := '0';
  signal state: CELL_CTRL_STATE;

begin

  -- lock <= new_data;

  state_process: process(clk)
  begin
    if clk = '1' then
      if rstn = '0' then
        state <= FREEZE;
      else
        case cell_ctrl_state is
          when FREEZE =>
            if DONE_WRITING = '1' and DONE_READING = '1' then
              state <= NORMAL;
            else
              if DONE_WRITING = '1' then
                state <= WRITE;
              else
                if DONE_READING = '1' then
                  state <= READ;
                end if;
              end if;
            end if;

          when READ =>
            if DONE_WRITING = '1' then
              state <= NORMAL;
            end if;

          when WRITE =>
            if DONE_READING = '1' then
              state <= NORMAL;
            end if;

          when NORMAL => 
            

  
  input: process(clk)
  begin
    if clk = '1' then
      if rstn = '0' then
        for i in 0 to N_CELL-1 loop
          cells(0, i) <= DEAD;
          cells(1, i) <= DEAD;
          cells(2, i) <= DEAD;
        end loop;
        READY_READING <= '0';
        new_data <= '0';
      else
        READY_READING <= '0'; -- unless we say so, the memory is not ready to be overwritten
        if DONE_WRITING = '1' then -- we can't do anything unless the past generation has been written to memory
          new_data <= '0'; -- new_data is a lock to prevent overwritting cached cells
          if (DONE_READING = '1') then -- if the memory has been read successfuly
            for i in 0 to ( N_CELL-1 ) loop -- we slide the widow towards the south
              cells(0,i) <= cells(1,i);
              cells(1,i) <= cells(2,i);
              cells(2,i)  <= (read_cell_vector(i));
            end loop;
            READY_READING <= '1'; -- tells the mem the read_cell_vector has been read (it can be written), DONE_READING will be set to 0
            new_data <= '1'; -- we can trust the computation of the generation g
          end if;
        end if;
      end if; -- end of the reset block
    end if; -- end of the synchronous block
  end process input;


  GEN: for i in 1 to ( N_CELL-2 ) generate -- we create N_CELL-2 cells, mapped with each others
    CELL: entity CELLOUX_LIB.CELL(syn)
    port map(clk, rstn, '1', cells(0,i), cells(0,i+1), cells(1,i+1), cells(2,i+1), cells(2,i), cells(2,i-1), cells(1,i-1), cells(0,i-1), new_cells(i));
  end generate GEN;

  output: process(clk)
  begin
    if clk = '1' then
      if rstn = '0' then
        for i in 0 to N_CELL-3 loop
          write_cell_vector(i) <= DEAD;
        end loop;
        READY_WRITING <= '0';
      else
        READY_WRITING <= '0'; -- we set READY_WRITING to 0 unless we cache the new cells in the write_cell_vector
        if (DONE_WRITING = '1') and (new_data = '1') then -- checks if new data is to be output and if the old one has been written
          for i in 0 to ( N_CELL-3 ) loop
            write_cell_vector(i) <= new_cells(i); -- output the soon-to-be-written cells
          end loop;
          READY_WRITING <= '1'; -- the DONE_WRITING will be set to 0 by address controller ?
        end if;
      end if; -- end of the reset block
    end if;-- end of the syncronous block
  end process;

end;

