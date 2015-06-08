--
-- SimpleRegister4Zynq - This file is part of SimpleRegister4Zynq
-- Copyright (C) 2015 - Telecom ParisTech
--
-- This file must be used under the terms of the CeCILL.
-- This source file is licensed as described in the file COPYING, which
-- you should have received as part of this distribution.  The terms
-- are also available at
-- http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library main_lib;
use main_lin.main_pkg.all;

library celloux_lib;
use celloux_lib.pack_cell.all;

library axi_lib;
use axi_lib.axi_pkg.all;

entity adr_ctrl is
   port(
         aclk:     in std_ulogic; -- Clock
         aresetn:  in std_ulogic  -- Reset
 )
end entity adr_ctrl;

architecture adr_ctr of adr_ctrl is

  signal s_axi_m2s:                axilite_gp_m2s;
  signal s_axi_s2m:                axilite_gp_s2m;
  signal height:                   std_ulogic_vector(15 downto 0);
  signal width:                    std_ulogic_vector(15 downto 0);
  signal global_start:             std_ulogic; -- start global du module
  signal compute_start:            std_ulogic; -- start signal for a new generation computation
  signal color:                    std_ulogic_vector(31 downto 0);
  signal waddress:                 std_ulogic_vector(31 downto 0);
  signal raddress:                 std_ulogic_vector(31 downto 0);
  signal wsize:                    integer;
  signal rsize:                    integer;
  signal ready_writing:            std_ulogic;
  signal read_request:             std_ulogic;
  signal in_cell_vector:           cell_vector;
  signal out_cell_vector:          cell_vector;
  signal done_reading:             std_ulogic;
  signal done_writing:             std_ulogic;
  signal done_reading_cell_ctrl:   std_ulogic;
  signal done_writing_cell_ctrl:   std_ulogic;
  signal ready_reading_cell_ctrl:  std_ulogic;
  signal ready_writing_cell_ctrl:  std_ulogic;
  signal write_offset:             integer range 0 to 79;
  signal write_state:              ADDR_CTRL_STATE;
  signal read_strobe:              std_ulogic_vector(0 to 7); -- to remember where to read the first cell
  signal write_strobe: std_ulogic_vector(0 to 7); -- a logical mask to write in memory
  signal read_offset:              integer range 0 to 79; -- tell how many cells have been written to memory

begin

  i_axi_register: entity axi_register_lib.axi_register
  port map(
    aclk      => aclk,
    aresetn   => aresetn,
    s_axi_m2s => s_axi_m2s,
    s_axi_s2m => s_axi_s2m,
  );

  i_axi_register_master: entity work.axi_register_master
  port map(
    aclk         => aclk,
    aresetn      => aresetn,
    m_axi_m2s    => s_axi_m2s,
    m_axi_s2m    => s_axi_s2m,
    wadress      => waddress,
    raddress     => raddress,
    wsize        => wsize,
    rsize        => rsize,
    wc_vector    => write_cell_vector,
    write_rq     => ready_writing,
    read_rq      => read_request,
    rc_vector    => read_cell_vector,
    done_reading => done_reading,
    done_writing => done_writing,
    write_offset => write_offset,
    r_strobe     => read_strobe,
    w_strobe     => write_strobe,
    r_offset     => read_offset -- the offset of the already valid cells
  );

  i_cell_ctrl: entity work.cell_ctrl
  port map(
    clk             => aclk,
    rstn            => aresetn,
    in_cell_vector  => read_cell_vector,
    done_reading    => done_reading_cell_ctrl,
    done_writing    => done_writing_cell_ctrl,
    out_cell_vector => write_cell_vector,
    ready_writing   => ready_writing_cell_ctrl,
    ready_reading   => ready_reading_cell_ctrl
  );
        
  read_process: process(aclk)
    variable first_time:              STD_ULOGIC := '1'; -- set iif the column is computed for the first time
    variable current_line:     NATURAL; -- local copies of i,
    variable jcurrent_column:     NATURAL; -- local copies of j
    variable offset_first_to_load:    STD_ULOGIC_VECTOR(31 downto 0); -- offset in the address space
    variable address_to_start_load:   STD_ULOGIC_VECTOR(31 downto 0); -- address to read in memory
    variable place_in_first_word:     STD_ULOGIC_VECTOR(2 downto 0); -- offset in the 64 bit space mapped by the address



  begin
    if aclk = '1' then -- syncronous block
      if aresetn = '0' then -- reset
        i := to_integer(HEIGHT) - 1; -- Game height - 1, size in cells not bits ( 1 cell = 8 bits)
        j := 0; -- up left corner
        state <= idle;
        first_time := '1';
      else -- no reset
        read_rq <= '0'; -- default values
        case write_state is
          when IDLE => -- wait for the next generation computation to start
            -- initialisation state, we set variables as in reset
            i <= WORLD_HEIGHT - 1; -- we first need to fetch this line by convention
            j <= 0;
            first_time := '1';
            if computation_start = '1' then -- the life awakens (new generaion computation)
              write_state <= START_LINE; -- start of a column computation
            end if;

          when START_LINE =>    
            -- start of a new column computation
            -- i is the line index and j the column one
            if done_reading = '1' and READY_READING_CELL_CTRL = '1' then -- the axi register has done reading the memory, we can ask for another shot of data
              if j = 0 then -- we are on the first column, we need to fetch the last cell (index in line = width-1)
                write_state <= PRELOAD;
              else -- we don't need to fetch last cell in line
                write_state <= INLINE;
              end if;
            end if;

          when PRELOAD =>
            -- PRELOAD state
            -- whenever j is at the border of the world, we fetch
            if done_reading = '1' then -- the memory has been read
              done_reading_cell_ctrl <= '0'; -- the next cells are not valid
              read_line := i;
              read_column := WORLD_WIDTH-1; -- we take into account the torus effect
              offset_first_to_load := coordinates2address(current_line, current_column);
              address_to_start_load := r_base_address + offset_first_to_load(31 downto 6) & b"000000";
              place_in_first_word := offset_first_to_load(5 downto 3); -- this is the offset in a 64bits word. There are 8 of them (the number of cells mapped to the address)
              read_strobe <= (to_integer(place_in_first_word) => '1', others => '0'); -- we set the bit of the cell to be first read to 1, acts like a mask
              read_request <= '1';
              raddress <= address_to_start_load; -- since we are in the case ready_reading we can change the read_address
              read_offset <= 0;
              rsize <= 1; -- set the read size 
              end if; -- end of the ready_reading block
            end if; -- end of the done_reading

          when POSTLOAD => -- we need to read one cell (i, 0). The rest has already been read
            if done_reading = '1' and ready_reading_cell_ctrl = '1' then -- if we the read is up
              read_column := 0; -- we need the column 0 
              read_line := i; -- of the current line
              rsize <= 1; -- we only need 1 cell
              offset_to_first_load := coordinates2offset(read_line, read_column);
              address_to_start_load := r_base_address + offset_to_first_load(31 downto 6) & b"000000";
              place_in_first_word := offset_to_first_load(5 downto 3);
              read_strobe <= (to_integer(place_in_first_word) => '1', others => '0'); -- mask to keep the desired cell in the 8 mapped by the 64 bit word
              read_rq <= '1'; -- we request a read
              raddress <= address_to_start_load;
              done_reading_cell_ctrl <= '1';
              if i = 1 then
                if first_time ='0' then
                  read_state <= IDLE; -- no need to update j, we are already in the last column
                  start_writing <= '0';
                else
                  start_writing <= '1';
                  read_state <= INLINE;
                  i <= i+1;
                end if;
                first_time := not first_time;
              else
                if i = WORLD_HEIGHT - 1 then
                  i <= 0;
                else
                  i <= i+1;
                end if;
                read_state <= INLINE;
              end if;

          when INLINE => -- we are in the middle of the world
            if done_reading = '1' and ready_reading_cell_ctrl = '1' then -- the memory has been read and the cell controller is ready to accept more input (its output has been written)
              read_line := i;
              right_torus:= '0'; -- test if we need to go to postload state or not
              if j > 0 and j + N_CELL - 1 <= GAME_WIDTH - 1 then -- no torus effect
                read_column := j-1; -- we need to fetch the (i, j-1) cell
                done_reading_cell_ctrl <= '1'; -- the 
              else
                if j = 0 then -- left torus, the leftmost cell has already been fetched
                  done_reading_cell_ctrl <= '1';
                  read_state <= PRELOAD; -- will be overwritten in the case of a shift to the right (end of the column 0)
                  read_column := j;
                  rsize <= N_CELL-1;
                  read_offset <= 1;
                else -- right torus, we will need to finish the read by invoking postload
                  right_torus := '1';
                  done_reading_cell_ctrl <= '0';
                  read_state <= POSTLOAD; -- mode right torus
                  read_column := j-1;
                  rsize <= GAME_WIDTH - j + 1; -- number of cells to fetch inline
              end if;
              offset_to_first_load := coordinates2offset(current_line, current_column);
              address_to_start_load := r_base_address + offset_first_to_load(31 downto 6) & b"000000"; -- we align on 64 bit addresses, mask
              place_in_first_word := offset_first_to_load(5 downto 3);
              for k in 0 to 7 loop -- init of the read_strobe array
                if k >= place_in_first_word then -- we set the mask to 1 for the cells ahead of place_in_first_place
                  read_strobe(k) <= '1';
                else
                  read_strobe(k) <= '0';
                end if;
              end loop; -- end of the read_strobe init
              read_rq <= '1'; -- request an address read
              read_address <= address_to_start_load; -- address to read
              if right_torus = '0' then
                if i = 1 then -- possible end of column
                  if first_time = '1' then -- we need to start the writing of this new column
                    start_writing <= '1';
                    i <= i + 1;
                  else
                    start_writing <= '0'; -- the next 3 line are not valid to write
                    i <= WORLD_HEIGHT - 1; -- reset the line index
                    j <= j + N_CELL - 2;
                    read_state <= INLINE;
                  end if;
                  fisrt_time := not first_time; -- reset / unset of first_time check
                else -- i/= 1, we stay in the current column
                  if i = WORLD_HEIGHT - 1 then -- need to roll up
                    i <= 0;
                  else -- regular behavior
                    i <= i +1; -- next line to be read
                  end if;
                end if;
              else
                read_state <= POSTLOAD;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process read_process;


  write_process: process(aclk)
    variable address_to_write: std_ulogic_vector(31 downto 0); -- where to write address in memory
    variable current_write_line: integer range -2 to WORLD_HEIGHT-1; -- write line index
    variable current_write_column: natural range -1 to WORLD_WIDTH-1; -- write column index
    variable offset_first_to_write: std_ulogic_vector(31 downto 0); -- offset in the waddress
    variable place_in_first_word: std_ulogic_vector(2 downto 0); -- word offset
    
  begin
    if clk = '1';
      if aresetn = '0' then
        current_write_line := 0;
        current_write_column := 0;
        write_state <= W_IDLE;
        address_to_write := (others => '0');
        offset_first_to_write := (others => '0');
        place_in_first_word := (others => '0');
        wsize <= 0;
        wadress <= (others => '0');
        write_strobe <= (others => '0');
        -- ...
      else
        case write_state is
          when W_IDLE => -- we wait for a new generation to be written
            if start_writing = '1' then -- driven by the read process, as we need to first read then write
              write_state <= W_START; -- basically we will write tat address i-2
            end if;

          when W_START => -- we qre instructed to wompute waddress and to ask for writing
            write_rq <= '0'; -- raised when something is to be written

            if ready_writing_cell_ctrl = '1' and done_writing = '1' then -- the new generation is ready and the write access is clear
              if i < 2 then -- the read head is in the first two line of a new column
                write_line := i + WORLD_WEIGHT; -- we set the write line with torus regards
                if j < (N_CELL*8 - 2) then
                  write_column := j + WORLD_HEIGHT; -- writing the right-down corner
                else
                  write_column := j - (N_CELL)*8 - 2; -- write column must be set to the previous read one in this case
                end if;
              else
                write_line := i - 2; -- we write the "middle" line
                write_column := j; -- we write on the read column
              end if; -- write_line|column are assigned
              if write_column + (N_CELL*8 - 2) - 1 > WORLD_WIDTH - 1 then
                wsize <= WORLD_WIDTH - write_column; -- write_column + wsize - 1 = WORLD_WIDTH - 1
                -- we don't want to write more than the place we have left
              else
                wsize <= N_CELL*8 - 2; -- number of cells to write, e.g. 78
              end if;

              offset_first_to_write := coordinates2offset(write_line, write_column);
              address_to_write := w_base_address + offset_first_to_write(31 downto 6) & b"000000"; -- we write at this address 
              place_in_first_word := offset_fisrt_to_write(5 downto 3); -- 3 bits to map the exaxt begining of the write
              for i in 0 to 7 loop
                if i >= to_integer(place_in_first_word) then
                  w_strobe(i) <= '1';
                else
                  w_strobe(i) <= '0';
                end if;
              end loop;

              waddress <= address_to_write;
              write_rq <= '1';
              
              if write_line = WORLD_HEIGHT - 1 and write_colum + (N_CELL*8 - 2) > WORLD_WIDTH then -- when we wrote the last line, we go to IDLE state waiting for another generation computation
                write_state <= W_IDLE;
            end if; -- end of the if ready to write block
        end case;
      end if; -- end of the reset
    end if; -- end of the synconous block
  end process write_process;
end;


                    











