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
use celloux_lib.cell_pkg.all;
library address_controller_lib;
use address_controller_lib.addr_ctrl_pkg.all;
library WORK;
use WORK.cell_ctrl_pkg.all;

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
  );
end entity cell_ctrl;

architecture arc of cell_ctrl is

  signal cells: window; -- the cells translated from the colors, 3 x N_CELL
  signal new_cells: CELL_VECTOR(0 to N_CELL-1);
  --signal -- new_data: std_logic := 'L';
  signal state: CELL_CTRL_STATE := FREEZE;
  signal run: std_ulogic := '0'; -- tells if the computation should start or freeze to cells

begin

  --
  state_process: process(clk) -- sets the cell_ctrl state
  begin
    if clk = '1' then
      if rstn = '0' then
        state <= FREEZE;
	run <= '0';
      else
	run <= '0';
        case state is -- we remember the seen signals. We only reset to freeze when we have READY_WRITING set

          when FREEZE => -- we wait for done signals during one CC
            if DONE_WRITING = '1' and DONE_READING = '1' then -- we can read and write to registers
              state <= NORMAL;
              run <= '1'; -- starts the write_cell_vector computation
            elsif DONE_READING = '1' then -- to remember the DONE_READING signal
              state <= READ;
            elsif DONE_WRITING = '1' then -- to remember the DONE_WRITING signal
              state <= WRITE;
            end if;

          when READ => -- we remember the DONE_READING signal
            if DONE_WRITING = '1' then
              state <= NORMAL;
              run <= '1';
            end if;

          when WRITE => -- DONE_WRITING has been read, wait for DONE_READING
            if DONE_READING = '1' then
              state <= NORMAL;
              run <= '1';
            end if;

          when NORMAL =>
            run <= '0'; -- prevent from overwriting the write_cell_vector
            state <= FREEZE; -- we have read and written memory, we wait for new DONE_READING and DONE_WRITING signals

        end case;
      end if;
    end if;
  end process;
  
  input: process(clk)
  begin
    if clk = '1' then
      if rstn = '0' then
        cells <= ( others => (others => DEAD));
        READY_READING <= '0';
        -- new_data <= 'L';
      else
        READY_READING <= '0'; -- unless we say so, the memory is not ready to be overwritten
        if state = NORMAL then -- we can't do anything unless the past generation has been written to memory
          for i in 0 to ( N_CELL-1 ) loop -- we slide the widow towards the south
            cells(0,i)	<= cells(1,i);
            cells(1,i)	<= (read_cell_vector(i)); -- for the next computation
          end loop;
          READY_READING <= '1'; -- tells the mem the read_cell_vector has been read (it can be written)
	else
	  cells <= cells;
        end if;
      end if; -- end of the reset block
    end if; -- end of the synchronous block
  end process input;


  NET_GEN: for i in 1 to ( N_CELL-2 ) generate -- we create N_CELL-2 cells, mapped with each others
    CELL: entity CELLOUX_LIB.CELL(syn)
    port map(
          clk   => clk,
          rstn => rstn,
          run => run, -- computes iif run is set
          N => cells(0, i),
          NW => cells(0, i+1),
          W => cells(1, i+1),
          SW => read_cell_vector(i+1),
          S => read_cell_vector(i),
          SE => read_cell_vector(i-1),
          E => cells(1, i-1),
          NE => cells(0, i-1),
          self => cells(1, i),
          state_out => write_cell_vector(i-1)
        );
  end generate NET_GEN;

  output: process(clk)
  begin
    if clk = '1' then
      if rstn = '0' then
        READY_WRITING <= '0';
      else
        READY_WRITING <= '0'; -- we set READY_WRITING to 0 unless we cache the new cells in the write_cell_vector
        if state = NORMAL then -- checks if DONE signals have been read
          READY_WRITING <= '1'; -- for addr_ctrl: the write_vector is valid
        end if;
      end if; -- end of the reset block
    end if;-- end of the syncronous block
  end process;

end;

