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
use ieee.std.numeric_std.all;

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

library axi_lib;
use axi_lib.axi_pkg.all;

entity adr_ctrl is
   port(
  aclk:   in std_ulogic;    -- Clock
  aresetn:  in std_ulogic;    -- Reset
   )
end entity adr_ctrl;

architecture adr_ctr of adr_ctrl is

  signal s_axi_m2s:   axilite_gp_m2s;
  signal s_axi_s2m:   axilite_gp_s2m;
  signal height:    std_ulogic_vector(15 downto 0);
  signal width:     std_ulogic_vector(15 downto 0);
        signal global_start:    std_ulogic; -- start global du module
        signal compute_start:   std_ulogic; -- start signal for a new generation computation
      signal color:     std_ulogic_vector(31 downto 0);
  signal waddress:  std_ulogic_vector(31 downto 0);
  signal raddress:  std_ulogic_vector(31 downto 0);
  signal wsize:   integer;
  signal rsize:   integer;
  signal ready_writing: std_ulogic;
  signal read_request:  std_ulogic;
  signal in_cell_vector:  cell_vector;
  signal out_cell_vector: cell_vector;
  signal done_reading:  std_ulogic;
  signal done_writing:  std_ulogic;
        signal done_reading_cell_ctrl: std_ulogic;
        signal done_writing_cell_ctrl: std_ulogic;
        signal ready_reading_cell_ctrl: std_ulogic;
        signal ready_writing_cell_ctrl: std_ulogic;
  signal write_offset:  integer range 0 to 79;
        signal write_state: ADDR_CTRL_STATE;
        signal read_strobe: std_ulogic_vector(0 to 7); -- to remember where to read the first cell
        signal read_offset: integer range 0 to 79; -- tell how many cells have been written to memory

begin

  i_axi_register: entity axi_register_lib.axi_register
  port map(
    aclk       => aclk,
    aresetn    => aresetn,
    s_axi_m2s => s_axi_m2s,
    s_axi_s2m => s_axi_s2m,
  );

  i_axi_register_master: entity work.axi_register_master
  port map(
    aclk    => aclk,
    aresetn   => aresetn,
    m_axi_m2s   => s_axi_m2s,
    m_axi_s2m   => s_axi_s2m,
    wadress   => waddress,
    raddress  => raddress,
    wsize   => wsize,
    rsize   => rsize,
    wc_vector => write_cell_vector,
    write_rq  => ready_writing,
    read_rq   => read_request,
    rc_vector => read_cell_vector,
    done_reading  => done_reading,
    done_writing  => done_writing,
    write_offset  => write_offset,
                r_strobe => read_strobe,
                w_strobe => write_strobe,
                r_offset => read_offset -- the offset of the already valid cells
  );

  i_cell_ctrl: entity work.cell_ctrl
  port map(
                clk => aclk,
                rstn => aresetn,
    in_cell_vector  => read_cell_vector,
    done_reading  => done_reading_cell_ctrl,
    done_writing  => done_writing_cell_ctrl,
    out_cell_vector => write_cell_vector,
    ready_writing => ready_writing_cell_ctrl,
    ready_reading => ready_reading_cell_ctrl
  );
        
        read_process: process(aclk)
          variable i,j : NATURAL := 0; -- coordinates in the world
          variable first_time: STD_ULOGIC := '1';
          variable current_line,column: NATURAL;
          variable offset_first_to_load, address_to_start_load: STD_ULOGIC_VECTOR(63 downto 0);
          variable place_in_first_word: STD_ULOGIC_VECTOR(2 downto 0);



        begin
          if aclk = '1' then -- syncronous block
            if aresetn = '0' then -- reset
              i := to_integer(HEIGHT) - 1; -- Game height - 1, size in cells not bits ( 1 cell = 8 bits)
              j := 0; -- up left corner
              state <= idle;
              first_time := '1';
            else -- no reset
              read_rq <= '0'; -- default values
              write_rq <= '0'; -- for read/write requests
              case write_state is
                when IDLE => -- wait for the next generation computation to start
                  -- initialisation state, we set variables as in reset
                  i := HEIGHT - 1; -- we first need to fetch this line by convention
                  j := 0;
                  first_time := '1';
                  if computation_start = '1' then -- the life awakens (new generaion computation)
                    write_state <= START_LINE; -- start of a column computation
                  end if;

                when START_LINE =>    
                  -- start of a new column computation
                  -- i is the line index and j the column one
                  if done_reading = '1' then -- the axi register has done reading the memory, we can ask for another shot of data
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
                    current_line := i;
                    if j = 0 then
                      column := to_integer(WIDTH)-1; -- we take into account the torus effect
                      done_reading_cell_ctrl <= '1'; -- we tell the cell_contrl the read_cell_vector is valid
                    else -- j belongs to ]width-80, width-1]
                      column := 0;
                    end if;
                    offset_first_to_load := coordinates2address(current_line, column);
                    address_to_start_load := r_base_address + offset_first_to_load(31 downto 6) & b"000000";
                    place_in_first_word := offset_first_to_load(5 downto 3); -- this is the offset in a 64bits word. There are 8 of them (the number of cells mapped to the address)
                    read_strobe <= (to_integer(place_in_first_word) => '1', others => '0'); -- we set the bit of the cell to be first read to 1, acts like a mask
                    if READY_READING_CELL_CTRL = '1' then -- the memory is ready to be read
                      done_reading_cell_ctrl <= '0'; -- we warn the cell ctrl the memory has NOT been fetched yet
                      if j /= 0 then -- since we are in preload, j belongs to [width-80, width-1]
                        read_offset <= to_integer(width) - j;
                      else
                        read_offset <= 0;
                      end if;
                      read_request <= '1';
                      raddress <= address_to_start_load; -- since we are in the case ready_reading we can change the read_address
                      rsize <= 0; -- set the read size 
                    end if; -- end of the ready_reading block
                  end if; -- end of the done_reading

                when INLINE => -- we are in the middle of the world
                  if done_reading = '1' then -- the memory has been read
                    current_line := i; -- temp save of the line
                    if j > 0 then -- no left torrus effect
                      column := j-1; -- we need to fetch the (i, j-1) cell
                      done_reading_cell_ctrl <= '1';
                    else -- left torrus, we need to load the leftmost cell
                      column = j;
                    end if;
                    offset_to_first_load := coordinates2address(current_line, column);
                    address_to_start_load := r_base_address + offset_first_to_load(31 downto 6) & b"000000"; -- we align on 64 bit addresses, mask
                    place_in_first_word := offset_first_to_load(5 downto 3);
                    for k in 0 to 7 loop -- init of the read_strobe array
                      if k >= place_in_first_word then -- we set the mask to 1 for the cells ahead of place_in_first_place
                        read_strobe(k) <= '1';
                      else
                        read_strobe(k) <= '0';
                      end if;
                    end loop; -- end of the read_strobe init
                    if ready_reading_cell_ctrl = '1' then -- if the memory is ready to be read
                      if j = 0 then
                        read_offset <= 1;
                      end if;
                      done_reading_cell_ctrl <= '1';
                      read_rq <= '1'; -- request an address
                      read_address <= address_to_start_load; -- address to read
                      if place_in_first_word /= 0 then 
                        rsize <= 10; -- rsize + 1 cells will be fetch
                      else
                        rsize <= 9;
                      end if;
                      i := i +1;
                      if i = height then
                        i := 0;
                      end if;
                      if i = 1 then -- the current line is i-1 = 0
                        if first_time = '1' then -- this is the first time we are here
                          first_time = '0'; -- set the first_time to "already seen"
                        else -- we have already computed the new generation for this column
                          j := j + 78; -- we shift he window to the right, we only compute 78 new cells at a time
                          if j > width-1 then
                            state <= IDLE;
                          else
                            state <= START_LINE; -- we start a new line, with the j modified
                          end if;
                        end if;
                      end if;
                      if j = 0 then 
                        state <= PRELOAD;
                      else
                        if j > width-1 then -- we stop the world computation once we reached the 
                          state <= IDLE;
                        else
                          state <= INLINE;
                        end if;
                      end if;
                    end if;
                  end if;
              end case;
            end if;
          end if;
        end process read_process;
      end;


                          











