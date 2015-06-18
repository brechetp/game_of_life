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

library celloux_lib;
use celloux_lib.cell_pkg.all;

library cell_controller_lib;

library axi_lib;
use axi_lib.axi_pkg.all;

library axi_register_lib;

entity addr_ctrl is
   port( 
	aclk:     in std_ulogic; -- Clock
	aresetn:  in std_ulogic;  -- Reset
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

  signal computation_start:         std_ulogic;
  signal s0_axi_m2s:		    axilite_gp_m2s;
  signal s0_axi_s2m:		    axilite_gp_s2m;
  signal m_axi_m2s:		    axi_hp_m2s;
  signal m_axi_s2m:		    axi_hp_s2m;
  signal height:		    std_ulogic_vector(15 downto 0);
  signal width:			    std_ulogic_vector(15 downto 0);
  signal global_start:		    std_ulogic; -- start global du module
  signal color:			    std_ulogic_vector(31 downto 0);
  signal waddress:		    std_ulogic_vector(31 downto 0);
  signal raddress:		    std_ulogic_vector(31 downto 0);
  signal wsize:			    integer range 0 to 15; -- the number of 64-bit words to write - 1
  signal rsize:			    integer range 0 to 15;
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
  signal read_state:		    ADDR_CTRL_READ_STATE := R_IDLE;
  signal write_state:		    ADDR_CTRL_WRITE_STATE := W_IDLE;
  signal read_strobe:		    std_ulogic_vector(0 to 7); -- to remember where to read the first cell
  signal write_strobe:		    std_ulogic_vector(0 to 7); -- a logical mask to write in memory
  signal write_strobe_last:		    std_ulogic_vector(0 to 7); -- a logical mask to write in memory
  signal read_offset:		    integer range 0 to 79; -- tell how many cells have been written to memory
  signal i:			    integer range 0 to WORLD_HEIGHT_MAX; -- line index
  signal j:			    integer range 0 to WORLD_WIDTH_MAX; -- column index
  signal WORLD_HEIGHT:              natural range 0 to WORLD_HEIGHT_MAX := WORLD_HEIGHT_MAX;
  signal WORLD_WIDTH:               natural range 0 to WORLD_WIDTH_MAX := WORLD_WIDTH_MAX;
  signal first_time:                STD_ULOGIC;      -- set iif the column is computed for the first time
  signal init:                      std_ulogic;
  signal next_state:                ADDR_CTRL_READ_STATE;   -- Will store the state we'll go to upon completion of the curent request.
  signal previous_state:            ADDR_CTRL_READ_STATE;   -- Will store the state we'll go to upon completion of the curent request.
  signal r_base_address, w_base_address: unsigned(31 downto 0);
  signal switch:                    std_ulogic;

begin

  i_axi_register: entity axi_register_lib.axi_register_v1(rtl)
  port map(
    aclk      => aclk,
    aresetn   => aresetn,
    s_axi_m2s => s0_axi_m2s,
    s_axi_s2m => s0_axi_s2m,
    height    => height,
    width     => width,
    start     => global_start,
    color     => color,
    switch    => switch,
    r_base_address => r_base_address,
    w_base_address => w_base_address
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
    r_offset     => read_offset, -- the offset of the already valid cells
    w_strobe_last => write_strobe_last
  );

  i_cell_ctrl: entity cell_controller_lib.cell_ctrl
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
        
  WORLD_HEIGHT <= to_integer(unsigned(height)); -- convert the world dimensions
  WORLD_WIDTH <= to_integer(unsigned(width));

  computation_clock: process(aclk) 
  variable count:     INTEGER range 0 to 200000;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then -- reset
        count := 0;
      elsif global_start = '1' then
        switch <= '0';
        computation_start <= '0';
        count := count +1;
        if count = 70 then
          switch <= '1';
          computation_start <= '1';
        elsif count > 100000 then -- TESTING Will only raise it once
          count := 100001;
        elsif count = 200000 then
          computation_start <= '1';
          switch <= '1';
          count := 0;
        end if;
      else
        switch <= '0';
        computation_start <= '0';
        count := 0;
      end if; 
    end if;
  end process;

  read_process: process(aclk)
    variable read_line:               NATURAL;                -- local copies of i,
    variable read_column:             NATURAL;                -- local copies of j
    variable offset_first_to_load:    unsigned(31 downto 0);  -- offset in the address space
    variable address_to_start_load:   unsigned(31 downto 0);  -- address to read in memory
    variable place_in_first_word:     unsigned(2 downto 0);   -- offset in the 64 bit space mapped by the address
    variable right_torus:             std_ulogic := '0';      -- logic test to check if we are with a right torus
  begin
    if rising_edge(aclk) then -- syncronous block
      if aresetn = '0' then -- reset
	done_reading_cell_ctrl	<= '0';
	i			<= 0;
        j			<= 0; -- up left corner
        read_state		<= r_idle;
        first_time		<= '1';
	read_request		<= '0';
	read_column		:= 0;
	read_line		:= 0;
      else -- no reset
        done_reading_cell_ctrl  <= '0'; -- the next cells are not valid
        read_request		<= '0'; -- default values
        case read_state is
          when R_IDLE => -- wait for the next generation computation to start
            -- initialisation state, we set variables as in reset
            i		<= WORLD_HEIGHT - 1; -- we first need to fetch this line by convention
            j		<= 0;
            first_time  <= '1';
            init        <= '1';
            if computation_start = '1' then -- the life awakens (new generaion computation)
              read_state <= R_PRELOAD; -- start of a column computation
            end if;

          when R_PRELOAD =>
            -- R_PRELOAD state
            -- whenever j is at the border of the world, we fetch
	    read_state		    <=	R_PRELOAD;
	    read_line               := i;
            read_column             := WORLD_WIDTH-1; -- we take into account the torus effect
            offset_first_to_load    := coordinates2offset(read_line, read_column, WORLD_WIDTH);
            address_to_start_load   := r_base_address + (offset_first_to_load(31 downto 6) & b"000000") ;
            place_in_first_word     := offset_first_to_load(5 downto 3); -- this is the offset in a 64bits word. There are 8 of them (the number of cells mapped to the address)
            raddress                <= std_ulogic_vector(address_to_start_load); -- since we are in the case ready_reading we can change the read_address
            read_offset             <= 0;
            rsize                   <= 0; -- set the read size 
            read_strobe             <= (others => '0');
            read_strobe(to_integer(place_in_first_word)) <= '1'; -- we set the bit of the cell to be first read to 1, acts like a mask
            if (ready_reading_cell_ctrl = '1') or (init = '1') then
              init                  <=  '0';
              read_request          <= '1';
              next_state            <= R_INLINE;
              previous_state        <= read_state;
              read_state            <= R_WAIT;
            end if;

          when R_POSTLOAD => -- we need to read one cell (i, 0). The rest has already been read
            read_column		    := 0; -- we need the column 0
            read_line		    := i; -- of the current line
            rsize		    <= 0; -- we only need 1 cell
            offset_first_to_load    := coordinates2offset(read_line, read_column, WORLD_WIDTH);
            address_to_start_load   := r_base_address + (offset_first_to_load(31 downto 6) & b"000000");
            place_in_first_word	    := offset_first_to_load(5 downto 3);
            read_strobe		    <= (others => '0');
            read_strobe(to_integer(place_in_first_word)) <= '1'; -- mask to keep the desired cell in the 8 mapped by the 64 bit word
            read_request	    <= '1'; -- we request a read
            raddress		    <= std_ulogic_vector(address_to_start_load);
            if i = 1 then
              if first_time ='0' then
                next_state <= R_IDLE;
                read_state <= R_WAIT; -- no need to update j, we are already in the last column
                previous_state <= read_state;
              else
                next_state <= R_INLINE;
                read_state <= R_WAIT;
                previous_state <= read_state;
                i <= i+1;
              end if;
              first_time <= not first_time;
            else
              if i = WORLD_HEIGHT - 1 then
                i <= 0;
              else
                i <= i+1;
              end if;
              next_state <= R_INLINE;
              read_state <= R_WAIT;
              previous_state <= read_state;
            end if;

          when R_INLINE => -- we are in the middle of the world
            if ready_reading_cell_ctrl = '1' or (j = 0) then -- the memory has been read and the cell controller is ready to accept more input (its output has been written)
              read_line		:=  i;
              right_torus       :=  '0'; -- test if we need to go to postload state or not
              if (j > 0) and (j + N_CELL-1 <= WORLD_WIDTH-1) then -- no torus effect
                read_column	    := j-1; -- we need to fetch the (i, j-1) cell
                next_state      <= R_INLINE;
                previous_state  <= read_state;
                read_state      <= R_WAIT;
              else -- torus effect 
                rsize         <= 9;
                if j=0 then -- left torus, the leftmost cell has already been fetched
                  next_state	<= R_PRELOAD; -- mode right torus
                  previous_state<= read_state;
                  read_state	<= R_WAIT;
                  read_column	:= j;
                  read_offset	<= 1;
                else -- right torus we have to fetch the rightmost cell after this line
                  right_torus   := '1';
                  next_state	<= R_POSTLOAD; -- mode right torus
                  previous_state<= read_state;
                  read_state	<= R_WAIT;
                  read_column	:= j-1; -- we need to fetch the (i, j-1) cell
                  read_offset   <= 0;
                end if;
              end if;
	            offset_first_to_load    :=	coordinates2offset(read_line, read_column, WORLD_WIDTH);
              address_to_start_load   :=	r_base_address + (offset_first_to_load(31 downto 6) & b"000000");
              place_in_first_word	    :=	offset_first_to_load(5 downto 3);
              for k in 0 to 7 loop -- init of the read_strobe array
                if k >= to_integer(place_in_first_word) then -- we set the mask to 1 for the cells ahead of place_in_first_place
                  read_strobe(k) <= '1';
                else
                  read_strobe(k) <= '0';
                end if;
              end loop; -- end of the read_strobe init
              raddress		    <= std_ulogic_vector(address_to_start_load); -- address to read
              read_request <= '1'; -- request an address read
              if right_torus = '0' then
                if i = 1 then -- possible end of column
                  if first_time = '1' then -- we need to start the writing of this new column
                    i <= i + 1;
                  else
                    i               <=  WORLD_HEIGHT - 1; -- reset the line index
                    j               <=  j + N_CELL - 2;
                    next_state      <=  R_INLINE;
                    previous_state  <=  read_state;
                    read_state      <=  R_WAIT;
                  end if;
                  first_time <= not first_time; -- reset / unset of first_time check
                else -- i/= 1, we stay in the current column
                  i <= i +1; -- next line to be read
                  if i = WORLD_HEIGHT - 1 then -- need to roll up
                    i <= 0;
                  end if;
                end if;
              end if;
            end if;
          when R_WAIT => -- we wait for the current query completion before moving on
            if done_reading = '1' then
              read_state  <= next_state; -- we load the saved nex_state;
              if (previous_state = R_POSTLOAD) or (previous_state = R_INLINE and next_state /= R_POSTLOAD) then -- once the whole N_CELL have been fetched
                done_reading_cell_ctrl <= '1';
              end if;
            end if;
        end case;
      end if;
    end if;
  end process read_process;


  write_process: process(aclk)
    variable address_to_write:      unsigned(31 downto 0); -- where to write address in memory
    variable write_line:            integer range -2 to WORLD_HEIGHT_MAX-1; -- write line index
    variable write_column:          integer range 0 to WORLD_WIDTH_MAX-1; -- write column index
    variable offset_first_to_write: unsigned(31 downto 0); -- offset in the waddress
    variable place_in_first_word:   unsigned(2 downto 0); -- word offset
    variable offset_last_to_write:  unsigned(31 downto 0); 
    variable place_in_last_word:    unsigned(2 downto 0); 
    variable cpt:                   integer range -2 to WORLD_HEIGHT_MAX; -- cpt that keep the current line to be written. Is valid when positive
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        write_line            := 0;
        write_column          := 0;
        write_state           <= W_IDLE;
        address_to_write      := (others => '0');
        offset_first_to_write := (others => '0');
        place_in_first_word   := (others => '0');
        offset_last_to_write  := (others => '0');
        place_in_last_word    := (others => '0');
        wsize                 <= 0;
        waddress              <= (others => '0');
        write_strobe          <= (others => '0');
        write_strobe_last     <= (others => '0');
        cpt                   := -2;
        -- ...
      else
        write_request <= '0';			    --  Raised when something is to be written
        done_writing_cell_ctrl <= '0';		    --  Will be raised one clk cycle to notify the cell ctrl that the cells have been written 
        write_column  := j;			    --  We write on the read column
        write_line    := cpt;		            --  We write the "middle" line
        case write_state is
          when W_IDLE =>			    --  We wait for a new generation to be written
            done_writing_cell_ctrl <= '1';
            if ready_writing_cell_ctrl = '1' then   --  Driven by the cell ctrl. Indicate that a value to good to be written
              cpt := cpt+1;
              if cpt =0 then
                write_state <= W_START;		    --  Basically we will write at line cpt
              end if;  
            end if;

          when W_START =>			    --  We are instructed to compute waddress and to ask for writing
            offset_first_to_write := coordinates2offset(write_line, write_column, WORLD_WIDTH);
            address_to_write := w_base_address + (offset_first_to_write(31 downto 6) & b"000000"); -- we write at this address 
            place_in_first_word := offset_first_to_write(5 downto 3); -- 3 bits to map the exact begining of the write
	          wsize <= 8;
            if write_column + (N_CELL - 2) - 1 > WORLD_WIDTH - 1 then  -- TODO See this condition again: DONE (?)
              wsize <= to_integer(to_unsigned(WORLD_WIDTH-1-j,16)(15 downto 3)); -- Wsize <= (WORLD_WIDTH -1 -j)/8 isn't it >> 10 ????
                -- We don't want overflow on other addresses
            elsif place_in_first_word <= "001" then
              wsize <= 8; -- we don't overflow on trailing 64-bit words
            elsif  place_in_first_word > "001" then
              wsize <= 9; -- we overflow on trailing 64-bit words, we need to write one more
            end if;
	          for index in 0 to 7 loop
              if i >= to_integer(place_in_first_word) then
                write_strobe(index) <= '1';
              else
                write_strobe(index) <= '0';
              end if;
            end loop;
            if write_column + (N_CELL - 2) - 1 > WORLD_WIDTH - 1 then -- TODO See this condition again 
              offset_last_to_write := coordinates2offset(write_line, WORLD_WIDTH - 1, WORLD_WIDTH);  -- Right torus, the last is the border cell
            else
              offset_last_to_write := coordinates2offset(write_line, write_column + 77, WORLD_WIDTH);-- No torus, the last is the first cell + 78
            end if;
            place_in_last_word := offset_last_to_write(5 downto 3); -- 3 bits to map the exact begining of the write
            for index in 0 to 7 loop
              if index <= to_integer(place_in_last_word) then
                write_strobe_last(index) <= '1';
              else
                write_strobe_last(index) <= '0';
              end if;
            end loop;
            waddress <= std_ulogic_vector(address_to_write);
            if ready_writing_cell_ctrl = '1' then   --  The new generation is ready
              write_request <= '1';
              write_state <= W_WAIT;
            end if;                     --  End of the if ready to write block

          when W_WAIT =>                --  We launched a request and are waiting for it to finish
            if done_writing = '1' then  --  The request is finished
              cpt := cpt + 1;            --  The next line to write will be cpt+1
              write_state <= W_START;
              -- Test finished column, go to W_IDLE and reset cpt
              if (write_line = WORLD_HEIGHT - 1) then
                write_state <= W_IDLE;
		            cpt := -2;
              end if;
              done_writing_cell_ctrl <= '1'; --  Notify that the cells have been written in memory
            end if;
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


                    











