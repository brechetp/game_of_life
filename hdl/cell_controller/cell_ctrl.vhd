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
    READY_CELL_CTRL: out std_ulogic; -- the write_cell_vector is ready to be written in memory
    -- n state of the world, 3 rows at a time of width BUFFER_SIZE
    read_cell_vector: in CELL_VECTOR(0 to N_CELL-1); -- read cells from memory
                                                                -- we only need this one as our window is gliding

    -- n+1 state of the world to be written in memory
    write_cell_vector:     out CELL_VECTOR(0 to N_CELL-3) -- cells to be written to memory
                                      -- this is the north register
  );
end entity cell_ctrl;

architecture arc of cell_ctrl is

  signal cells:           window := (others => (others => DEAD)); -- the cells translated from the colors, 3 x N_CELL
  signal new_cells:       CELL_VECTOR(0 to N_CELL-3) := (others => DEAD); 
  signal state:           CELL_CTRL_STATE := FREEZE;
  signal enable:             std_ulogic := '0'; -- tells if the computation should start or freeze to cells

begin

  --
  state_process: process(clk) -- sets the cell_ctrl state
  begin
    if rising_edge(clk) then
      if rstn = '0' then
        state <= FREEZE;
        enable <= '0';
      else
        enable <= '0';
        case state is -- we remember the seen signals. We only reset to freeze when we have READY_WRITING set

          when FREEZE => -- we wait for done signals during one CC
            if DONE_WRITING = '1' and DONE_READING = '1' then -- we can read and write to registers
              state <= NORMAL;
              enable <= '1'; -- starts the write_cell_vector computation
            elsif DONE_READING = '1' then -- to remember the DONE_READING signal
              state <= READ;
            elsif DONE_WRITING = '1' then -- to remember the DONE_WRITING signal
              state <= WRITE;
            end if;

          when READ => -- we remember the DONE_READING signal
            if DONE_WRITING = '1' then
              state <= NORMAL;
              enable <= '1';
            end if;

          when WRITE => -- DONE_WRITING has been read, wait for DONE_READING
            if DONE_READING = '1' then
              state <= NORMAL;
              enable <= '1';
            end if;

          when NORMAL =>
            state <= FREEZE; -- we have read and written memory, we wait for new DONE_READING and DONE_WRITING signals

        end case;
      end if;
    end if;
  end process;
  
  input: process(state)
  begin
    if state = NORMAL then -- we can't do anything unless the past generation has been written to memory
      for i in 0 to ( N_CELL-1 ) loop -- we slide the widow towards the south
        cells(0,i)    <= cells(1,i);
        cells(1,i)    <= cells(2, i);
        cells(2,i)    <= (read_cell_vector(i)); -- for the next computation
      end loop;
    end if; -- end of the synchronous block
  end process input;


  NET_GEN: for i in 1 to ( N_CELL-2 ) generate -- we create N_CELL-2 cells, mapped with each others
    CELL: entity CELLOUX_LIB.CELL(syn)
    port map(
          enable => enable, -- computes iif enable is set
          N => cells(0, i),
          NW => cells(0, i+1),
          W => cells(1, i+1),
          SW => cells(2, i+1),
          S => cells(2, i),
          SE => cells(2, i-1),
          E => cells(1, i-1),
          NE => cells(0, i-1),
          self => cells(1, i),
          state_out => new_cells(i-1),
          mem_state => new_cells(i-1)
        );
  end generate NET_GEN;

  output: process(new_cells)
  begin
    for i in 0 to ( N_CELL-3 ) loop -- we slide the widow towards the south
      write_cell_vector(i) <= new_cells(i);
    end loop;
  end process;

  with state select
    READY_CELL_CTRL <= '1' when NORMAL,
                       '0' when others;

end;

