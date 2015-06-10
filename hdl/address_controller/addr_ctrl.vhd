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
--use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

use WORK.addr_ctrl_pkg.all;

library main_lib;
use main_lib.main_pkg.all;

library celloux_lib;
use celloux_lib.pack_cell.all;

library axi_lib;
use axi_lib.axi_pkg.all;

library axi_register_lib;

entity addr_ctrl is
   port(
	aclk:     in std_ulogic; -- Clock
	aresetn:  in std_ulogic;  -- Reset
        computation_start: in std_ulogic;
	--------------------------------
	-- AXI lite slave port s0_axi --
	--------------------------------
	-- Inputs (master to slave) --
	------------------------------
	-- Read address channel
	s0_axi_araddr:  in  std_logic_vector(11 downto 0);
	s0_axi_arprot:  in  std_logic_vector(2 downto 0);
	s0_axi_arvalid: in  std_logic;
	-- Read data channel
	s0_axi_rready:  in  std_logic;
	-- Write address channel
	s0_axi_awaddr:  in  std_logic_vector(11 downto 0);
	s0_axi_awprot:  in  std_logic_vector(2 downto 0);
	s0_axi_awvalid: in  std_logic;
	-- Write data channel
	s0_axi_wdata:   in  std_logic_vector(31 downto 0);
	s0_axi_wstrb:   in  std_logic_vector(3 downto 0);
	s0_axi_wvalid:  in  std_logic;
	-- Write response channel
	s0_axi_bready:  in  std_logic;
	-------------------------------
	-- Outputs (slave to master) --
	-------------------------------
	-- Read address channel
	s0_axi_arready: out std_logic;
	-- Read data channel
	s0_axi_rdata:   out std_logic_vector(31 downto 0);
	s0_axi_rresp:   out std_logic_vector(1 downto 0);
	s0_axi_rvalid:  out std_logic;
	-- Write address channel
	s0_axi_awready: out std_logic;
	-- Write data channel
	s0_axi_wready:  out std_logic;
	-- Write response channel
	s0_axi_bvalid:  out std_logic;
	s0_axi_bresp:   out std_logic_vector(1 downto 0);

	---------------------------
	-- AXI master port m_axi --
	---------------------------
	-------------------------------
	-- Outputs (slave to master) --
	-------------------------------
	-- Read address channel
	m_axi_arid:    out std_logic_vector(5 downto 0);
	m_axi_araddr:  out std_logic_vector(31 downto 0);
	m_axi_arlen:   out std_logic_vector(3 downto 0);
	m_axi_arsize:  out std_logic_vector(2 downto 0);
	m_axi_arburst: out std_logic_vector(1 downto 0);
	m_axi_arlock:  out std_logic_vector(1 downto 0);
	m_axi_arcache: out std_logic_vector(3 downto 0);
	m_axi_arprot:  out std_logic_vector(2 downto 0);
	m_axi_arqos:   out std_logic_vector(3 downto 0);
	m_axi_arvalid: out std_logic;
	-- Read data channel
	m_axi_rready:  out std_logic;
	-- Write address channel
	m_axi_awid:    out std_logic_vector(5 downto 0);
	m_axi_awaddr:  out std_logic_vector(31 downto 0);
	m_axi_awlen:   out std_logic_vector(3 downto 0);
	m_axi_awsize:  out std_logic_vector(2 downto 0);
	m_axi_awburst: out std_logic_vector(1 downto 0);
	m_axi_awlock:  out std_logic_vector(1 downto 0);
	m_axi_awcache: out std_logic_vector(3 downto 0);
	m_axi_awprot:  out std_logic_vector(2 downto 0);
	m_axi_awqos:   out std_logic_vector(3 downto 0);
	m_axi_awvalid: out std_logic;
	-- Write data channel
	m_axi_wid:     out std_logic_vector(5 downto 0);
	m_axi_wdata:   out std_logic_vector(63 downto 0);
	m_axi_wstrb:   out std_logic_vector(7 downto 0);
	m_axi_wlast:   out std_logic;
	m_axi_wvalid:  out std_logic;
	-- Write response channel
	m_axi_bready:  out std_logic;
	------------------------------
	-- Inputs (slave to master) --
	------------------------------
	-- Read address channel
	m_axi_arready: in  std_logic;
	-- Read data channel
	m_axi_rid:     in  std_logic_vector(5 downto 0);
	m_axi_rdata:   in  std_logic_vector(63 downto 0);
	m_axi_rresp:   in  std_logic_vector(1 downto 0);
	m_axi_rlast:   in  std_logic;
	m_axi_rvalid:  in  std_logic;
	-- Write address channel
	m_axi_awready: in  std_logic;
	-- Write data channel
	m_axi_wready:  in  std_logic;
	-- Write response channel
	m_axi_bvalid:  in  std_logic;
	m_axi_bid:     in  std_logic_vector(5 downto 0);
	m_axi_bresp:   in  std_logic_vector(1 downto 0)
 );
end entity addr_ctrl;

architecture window of addr_ctrl is

  signal s0_axi_m2s:		    axilite_gp_m2s;
  signal s0_axi_s2m:		    axilite_gp_s2m;
  signal m_axi_m2s:		    axi_hp_m2s;
  signal m_axi_s2m:		    axi_hp_s2m;
  signal gpi:			    std_ulogic_vector(7 downto 0);
  signal gpo:			    std_ulogic_vector(7 downto 0);
  signal height:		    std_ulogic_vector(15 downto 0);
  signal width:			    std_ulogic_vector(15 downto 0);
  signal global_start:		    std_ulogic; -- start global du module
  signal compute_start:		    std_ulogic; -- start signal for a new generation computation
  signal color:			    std_ulogic_vector(31 downto 0);
  signal waddress:		    std_ulogic_vector(31 downto 0);
  signal raddress:		    std_ulogic_vector(31 downto 0);
  signal wsize:			    integer;
  signal rsize:			    integer;
  signal ready_writing:		    std_ulogic;
  signal read_request:		    std_ulogic;
  signal write_request:		    std_ulogic;
  signal read_cell_vector:	    cell_vector(0 to N_CELL-1);
  signal write_cell_vector:	    cell_vector(0 to N_CELL-3);
  signal done_reading:		    std_ulogic;
  signal done_writing:		    std_ulogic;
  signal done_reading_cell_ctrl:    std_ulogic;
  signal done_writing_cell_ctrl:    std_ulogic;
  signal ready_reading_cell_ctrl:   std_ulogic;
  signal ready_writing_cell_ctrl:   std_ulogic;
  signal read_state:		    ADDR_CTRL_READ_STATE;
  signal write_state:		    ADDR_CTRL_WRITE_STATE;
  signal read_strobe:		    std_ulogic_vector(0 to 7); -- to remember where to read the first cell
  signal write_strobe:		    std_ulogic_vector(0 to 7); -- a logical mask to write in memory
  signal read_offset:		    integer range 0 to 79; -- tell how many cells have been written to memory
  signal i:			    NATURAL range 0 to WORLD_HEIGHT-1; -- line index
  signal j:			    NATURAL range 0 to WORLD_WIDTH-1; -- column index
  signal start_writing:		    std_ulogic; -- to start the write process

begin

  i_axi_register: entity axi_register_lib.axi_register(rtl)
  port map(
    aclk      => aclk,
    aresetn   => aresetn,
    s0_axi_m2s => s0_axi_m2s,
    s0_axi_s2m => s0_axi_s2m,
    gpi => gpi,
    gpo => gpo
  );

  i_axi_register_master: entity axi_register_lib.axi_register_master(rtl)
  port map(
    aclk         => aclk,
    aresetn      => aresetn,
    m_axi_m2s    => m_axi_m2s,
    m_axi_s2m    => m_axi_s2m,
    waddress	 => waddress,
    raddress     => raddress,
    wsize        => wsize,
    rsize        => rsize,
    wc_vector    => write_cell_vector,
    write_rq     => write_request,
    read_rq      => read_request,
    rc_vector    => read_cell_vector,
    done_reading => done_reading,
    done_writing => done_writing,
    r_strobe     => read_strobe,
    w_strobe     => write_strobe,
    r_offset     => read_offset -- the offset of the already valid cells
  );

  i_cell_ctrl: entity main_lib.cell_ctrl
  port map(
    clk             => aclk,
    rstn            => aresetn,
    read_cell_vector  => read_cell_vector,
    done_reading    => done_reading_cell_ctrl,
    done_writing    => done_writing_cell_ctrl,
    write_cell_vector => write_cell_vector,
    ready_writing   => ready_writing_cell_ctrl,
    ready_reading   => ready_reading_cell_ctrl
  );
        
  read_process: process(aclk)
    variable first_time:              STD_ULOGIC := '1'; -- set iif the column is computed for the first time
    variable read_line:     NATURAL; -- local copies of i,
    variable read_column:     NATURAL; -- local copies of j
    variable offset_first_to_load:    unsigned(31 downto 0); -- offset in the address space
    variable address_to_start_load:   unsigned(31 downto 0); -- address to read in memory
    variable place_in_first_word:     unsigned(2 downto 0); -- offset in the 64 bit space mapped by the address
    variable right_torus: std_ulogic := '0'; -- logic test to check if we are with a right torus

  begin
    if aclk = '1' then -- syncronous block
      if aresetn = '0' then -- reset
        i <= WORLD_HEIGHT - 1;-- Game height - 1, size in cells not bits ( 1 cell = 8 bits)
        j <= 0; -- up left corner
        read_state <= idle;
        first_time := '1';
      else -- no reset
        read_request <= '0'; -- default values
        case read_state is
          when IDLE => -- wait for the next generation computation to start
            -- initialisation state, we set variables as in reset
            i <= WORLD_HEIGHT - 1; -- we first need to fetch this line by convention
            j <= 0;
            first_time := '1';
            if computation_start = '1' then -- the life awakens (new generaion computation)
              read_state <= START_LINE; -- start of a column computation
            end if;

          when START_LINE =>    
            -- start of a new column computation
            -- i is the line index and j the column one
            if j = 0 then -- we are on the first column, we need to fetch the last cell (index in line = width-1)
              read_state <= PRELOAD;
            else -- we don't need to fetch last cell in line
              read_state <= INLINE;
            end if;

          when PRELOAD =>
            -- PRELOAD state
            -- whenever j is at the border of the world, we fetch
            if done_reading = '1' then -- the memory has been read
              done_reading_cell_ctrl <= '0'; -- the next cells are not valid
              read_line := i;
              read_column := WORLD_WIDTH-1; -- we take into account the torus effect
              offset_first_to_load := coordinates2offset(read_line, read_column);
              address_to_start_load := r_base_address + offset_first_to_load(31 downto 6) & b"000000" ;
              place_in_first_word := offset_first_to_load(5 downto 3); -- this is the offset in a 64bits word. There are 8 of them (the number of cells mapped to the address)
              read_strobe <= (to_integer(place_in_first_word) => '1', others => '0'); -- we set the bit of the cell to be first read to 1, acts like a mask
              read_request <= '1';
              raddress <= std_ulogic_vector(address_to_start_load); -- since we are in the case ready_reading we can change the read_address
              read_offset <= 0;
              rsize <= 1; -- set the read size 
            end if; -- end of the ready_reading block

          when POSTLOAD => -- we need to read one cell (i, 0). The rest has already been read
            if done_reading = '1' and ready_reading_cell_ctrl = '1' then -- if we the read is up
              done_reading_cell_ctrl <= '1';
              read_column := 0; -- we need the column 0 
              read_line := i; -- of the current line
              rsize <= 1; -- we only need 1 cell
              offset_first_to_load := coordinates2offset(read_line, read_column);
              address_to_start_load := r_base_address + offset_first_to_load(31 downto 6) & b"000000";
              place_in_first_word := offset_first_to_load(5 downto 3);
              read_strobe <= (to_integer(place_in_first_word) => '1', others => '0'); -- mask to keep the desired cell in the 8 mapped by the 64 bit word
              read_request <= '1'; -- we request a read
              raddress <= std_ulogic_vector(address_to_start_load);
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
            end if; -- end of done reading

          when INLINE => -- we are in the middle of the world
            if done_reading = '1' and ready_reading_cell_ctrl = '1' then -- the memory has been read and the cell controller is ready to accept more input (its output has been written)
              read_line := i;
              right_torus:= '0'; -- test if we need to go to postload state or not
              if j > 0 and j + N_CELL - 1 <= WORLD_WIDTH - 1 then -- no torus effect
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
                  rsize <= WORLD_WIDTH - j + 1; -- number of cells to fetch inline
                end if;
              end if;
              offset_first_to_load := coordinates2offset(read_line, read_column);
              address_to_start_load :=r_base_address + offset_first_to_load(31 downto 6) & b"000000";
              place_in_first_word := offset_first_to_load(5 downto 3);
              for k in 0 to 7 loop -- init of the read_strobe array
                if k >= place_in_first_word then -- we set the mask to 1 for the cells ahead of place_in_first_place
                  read_strobe(k) <= '1';
                else
                  read_strobe(k) <= '0';
                end if;
              end loop; -- end of the read_strobe init
              read_request <= '1'; -- request an address read
              raddress <= std_ulogic_vector(address_to_start_load); -- address to read
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
                first_time := not first_time; -- reset / unset of first_time check
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
    variable address_to_write: unsigned(31 downto 0); -- where to write address in memory
    variable write_line: integer range -2 to WORLD_HEIGHT-1; -- write line index
    variable write_column: integer range -1 to WORLD_WIDTH-1; -- write column index
    variable offset_first_to_write: unsigned(31 downto 0); -- offset in the waddress
    variable place_in_first_word: unsigned(2 downto 0); -- word offset
    
  begin
    if aclk = '1' then
      if aresetn = '0' then
        write_line := 0;
        write_column := 0;
        write_state <= W_IDLE;
        address_to_write := (others => '0');
        offset_first_to_write := (others => '0');
        place_in_first_word := (others => '0');
        wsize <= 0;
        waddress <= (others => '0');
        write_strobe <= (others => '0');
        -- ...
      else
        case write_state is
          when W_IDLE => -- we wait for a new generation to be written
            if start_writing = '1' then -- driven by the read process, as we need to first read then write
              write_state <= W_START; -- basically we will write at address i-2
            end if;

          when W_START => -- we qre instructed to wompute waddress and to ask for writing
            write_request <= '0'; -- raised when something is to be written
            done_writing_cell_ctrl <= '0';

            if ready_writing_cell_ctrl = '1' and done_writing = '1' then -- the new generation is ready and the write access is clear
              if i < 2 then -- the read head is in the first two line of a new column
                write_line := i + WORLD_HEIGHT; -- we set the write line with torus regards
              else
                write_line := i - 2; -- we write the "middle" line
              end if; -- write_line|column are assigned
              write_column := j; -- we write on the read column
              if write_column + (N_CELL*8 - 2) - 1 > WORLD_WIDTH - 1 then
                wsize <= WORLD_WIDTH - write_column; -- write_column + wsize - 1 = WORLD_WIDTH - 1
                -- we don't want to write more than the place we have left
              else
                wsize <= N_CELL*8 - 2; -- number of cells to write, e.g. 78
              end if;

              offset_first_to_write := coordinates2offset(write_line, write_column);
              address_to_write := w_base_address + offset_first_to_write(31 downto 6) & b"000000"; -- we write at this address 
              place_in_first_word := offset_first_to_write(5 downto 3); -- 3 bits to map the exaxt begining of the write
              for i in 0 to 7 loop
                if i >= to_integer(place_in_first_word) then
                  write_strobe(i) <= '1';
                else
                  write_strobe(i) <= '0';
                end if;
              end loop;

              waddress <= std_ulogic_vector(address_to_write);
              write_request <= '1';
              
              if ((write_line = WORLD_HEIGHT - 1) and (write_column + (N_CELL*8 - 2) > WORLD_WIDTH)) or (start_writing = '0') then -- when we wrote the last line, we go to IDLE state waiting for another generation computation or we are asked to stop writing
                write_state <= W_IDLE;
              end if;
            end if; -- end of the if ready to write block

        end case;
      end if; -- end of the reset
    end if; -- end of the synconous block
  end process write_process;

-----------------------------------------------------------------
-------------------------- AXI wrapper --------------------------
-- AXI slave
  s0_axi_m2s.araddr  <= std_ulogic_vector(X"00000" & s0_axi_araddr);
  s0_axi_m2s.arprot  <= std_ulogic_vector(s0_axi_arprot);
  s0_axi_m2s.arvalid <= s0_axi_arvalid;

  s0_axi_m2s.rready  <= s0_axi_rready;

  s0_axi_m2s.awaddr  <= std_ulogic_vector(X"00000" & s0_axi_awaddr);
  s0_axi_m2s.awprot  <= std_ulogic_vector(s0_axi_awprot);
  s0_axi_m2s.awvalid <= s0_axi_awvalid;

  s0_axi_m2s.wdata   <= std_ulogic_vector(s0_axi_wdata);
  s0_axi_m2s.wstrb   <= std_ulogic_vector(s0_axi_wstrb);
  s0_axi_m2s.wvalid  <= s0_axi_wvalid;

  s0_axi_m2s.bready  <= s0_axi_bready;

  s0_axi_arready     <= s0_axi_s2m.arready;

  s0_axi_rdata       <= std_logic_vector(s0_axi_s2m.rdata);
  s0_axi_rresp       <= std_logic_vector(s0_axi_s2m.rresp);
  s0_axi_rvalid      <= s0_axi_s2m.rvalid;

  s0_axi_awready     <= s0_axi_s2m.awready;

  s0_axi_wready      <= s0_axi_s2m.wready;

  s0_axi_bvalid      <= s0_axi_s2m.bvalid;
  s0_axi_bresp       <= std_logic_vector(s0_axi_s2m.bresp);

-- AXI master

  m_axi_arid         <= std_logic_vector(m_axi_m2s.arid);
  m_axi_araddr       <= std_logic_vector(m_axi_m2s.araddr);
  m_axi_arlen        <= std_logic_vector(m_axi_m2s.arlen);
  m_axi_arsize       <= std_logic_vector(m_axi_m2s.arsize);
  m_axi_arburst      <= std_logic_vector(m_axi_m2s.arburst);
  m_axi_arlock       <= std_logic_vector(m_axi_m2s.arlock);
  m_axi_arcache      <= std_logic_vector(m_axi_m2s.arcache);
  m_axi_arprot       <= std_logic_vector(m_axi_m2s.arprot);
  m_axi_arqos        <= std_logic_vector(m_axi_m2s.arqos);
  m_axi_arvalid      <= m_axi_m2s.arvalid;

  m_axi_rready       <= m_axi_m2s.rready;

  m_axi_awid         <= std_logic_vector(m_axi_m2s.awid);
  m_axi_awaddr       <= std_logic_vector(m_axi_m2s.awaddr);
  m_axi_awlen        <= std_logic_vector(m_axi_m2s.awlen);
  m_axi_awsize       <= std_logic_vector(m_axi_m2s.awsize);
  m_axi_awburst      <= std_logic_vector(m_axi_m2s.awburst);
  m_axi_awlock       <= std_logic_vector(m_axi_m2s.awlock);
  m_axi_awcache      <= std_logic_vector(m_axi_m2s.awcache);
  m_axi_awprot       <= std_logic_vector(m_axi_m2s.awprot);
  m_axi_awqos        <= std_logic_vector(m_axi_m2s.awqos);
  m_axi_awvalid      <= m_axi_m2s.awvalid;

  m_axi_wid          <= std_logic_vector(m_axi_m2s.wid);
  m_axi_wdata        <= std_logic_vector(m_axi_m2s.wdata);
  m_axi_wstrb        <= std_logic_vector(m_axi_m2s.wstrb);
  m_axi_wlast        <= m_axi_m2s.wlast;
  m_axi_wvalid       <= m_axi_m2s.wvalid;

  m_axi_bready       <= m_axi_m2s.bready;

  m_axi_s2m.arready  <= m_axi_arready;

  m_axi_s2m.rid      <= std_ulogic_vector(m_axi_rid);
  m_axi_s2m.rdata    <= std_ulogic_vector(m_axi_rdata);
  m_axi_s2m.rresp    <= std_ulogic_vector(m_axi_rresp);
  m_axi_s2m.rlast    <= m_axi_rlast;
  m_axi_s2m.rvalid   <= m_axi_rvalid;

  m_axi_s2m.awready  <= m_axi_awready;

  m_axi_s2m.wready   <= m_axi_wready;

  m_axi_s2m.bvalid   <= m_axi_bvalid;
  m_axi_s2m.bid      <= std_ulogic_vector(m_axi_bid);
  m_axi_s2m.bresp    <= std_ulogic_vector(m_axi_bresp);


end;


                    










