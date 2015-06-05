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

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

library axi_lib;
use axi_lib.axi_pkg.all;

library celloux_lib;
use celloux_lib.pack_cell.all

-- See the README file for a detailed description of the AXI register master

entity axi_register_master is
  port(
    aclk:       in  std_ulogic;
    aresetn:    in  std_ulogic;
    -- AXI lite slave port
    m_axi_m2s:  out axi_gp_m2s;
    m_axi_s2m:  in  axi_gp_s2m;
    -- Read control signals 
    raddress:	    in  std_ulogic_vector(31 downto 0); --  Address from which to start reading
    rsize:	    in  integer range 0 to 10;		--  size of reading burst
    r_strobe:	    in  std_ulogic_vector(7 downto 0);  --  Which part of the first 64 bit to read into rc_vector
    read_rq :	    in  std_ulogic:			--  request new read
    r_offset:	    in	integer range 0 to 79;		--  offset from which to write in rc_vector
    -- Read response signals
    done_reading:   out std_ulogic; --  Read finished
    rc_vector:	    out cell_vector;--  cell array to be read from
    -- Write control signals
    waddress:	    in  std_ulogic_vector(31 downto 0); --  Address from which to start writing
    wc_vector:	    in  cell_vector;			--  cell array to be written in memory
    wsize:	    in  integer range 0 to 10;		--  size of writting burst
    w_strobe:	    in	std_ulogic_vector(7 downto 0);	--  offset to the first non valid cell in rc_vector
    write_rq:	    in  std_ulogic;			--  Input data is valid - request new write
    -- Write response signals
    done_writing:   out std_ulogic  --  Write succesfull, ready for another
  );
end entity axi_register_master;

architecture rtl of axi_register_master is
    shared variable done_writing_tmp: std_ulogic;
    shared variable done_reading_tmp: std_ulogic;
begin
  -- This process will emit the request over the axi bus
  wnr_request_pr: process(aclk)
    -- idle:	waiting for gpi_valid to write or gpi_nr to read (higher priority to write)
    -- if gpi_valid is set to 1 then initialize variable then we set do_write_rq, if gpi_nr is set to 1 then we set do_reqd_rq
    -- do_write_rq:	if awready is 1 then assert awvalid (to 1), awaddr (to address), awlen (to the burst size = 10),awsize (011b = 8 bytes (64-bit wide burst)), awburst (type of burst, only 01b = INCR ) for one clock yhen go back to idle
    -- do_read_rq:	if arready is 1 then assert arvalid (to 1), araddr (to address), arlen (to the burst size = 10),arsize (011b = 8 bytes (64-bit wide burst)), arburst (type of burst, only 01b = INCR ) for one clock yhen go back to idle
    signal do_write_rq:   std_ulogic;
    signal do_read_rq:    std_ulogic;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
	do_write_rq	    :=	'0';
	do_read_rq	    :=	'0';
	m_axi_m2s.awvalid   <=	'0';
	m_axi_m2s.arvalid   <=	'0';
      else
	if write_rq = '1' then
	  do_write_rq	    <=	'1';
	  done_writing_tmp  :=	'0';
	if read_rq = '1' then
	  do_read_rq	    <=	'1';
	  done_reading_tmp  :=	'0';
	end if;
	if do_write_rq = '1' then
	  m_axi_m2s.awvalid	<=  '1';
	  m_axi_m2s.awaddr	<=  address;
	  m_axi_m2s.awlen	<=  10;
	  m_axi_m2s.awsize	<=  wsize;
	  m_axi_m2s.awburst	<=  axi_burst_incr;
	  if (m_axi_s2m.awready <= '1') and (m_axi_m2s.awvalid = '1') then
	    do_write_rq		:=  '0';
	    m_axi_m2s.awvalid	<=  '0';
	  end if;
	end if;
	if do_read_rq = '1' then
	  m_axi_m2s.arvalid	<=  '1';
	  m_axi_m2s.araddr	<=  address;
	  m_axi_m2s.arlen	<=  10;
	  m_axi_m2s.arsize	<=  rsize;
	  m_axi_m2s.arburst	<=  axi_burst_incr;
	  if (m_axi_s2m.arready = '1') and (m_axi_m2s_arvalid = '1') then
	    do_read_rq		:=  '0';
	    m_axi_m2s.arvalid	<=  '0';
	  end if;
	end if;
      end if;
    end if;
  end process wnr_request_pr;

  -- This process drive done_reading and done_writing
  rw_drive_proc: process (aclk)
  begin
    if rising_edge(aclk) then
      done_reading <= done_reading_tmp;
      done_writing <= done_writing_tmp;
    end if;
  end process rw_drive_proc;

  --This process will emit and read the data as needed. 
  wr_proc: process(aclk)
    -- idle:	wait for either rvalid or wvalid, set wdata to wc_vector(write_cpt)
    -- rvalid:	store convert2cell(rdata(i)) in rc_vector(read_cpt+i) 8 time (as there are 8 cell in 64bit) and incr read_cpt
    --		if rlast is set, reset read_cpt, drive done_reading_tmp to 1
    -- wvalid:	incr write_cpt by 8
    --		if write_cpt = wsize then set wlast and done_writing_tmp to 1
    variable write_word_cpt:	natural range 0 to 10;	--  The current index in the write burst
    variable write_cell_number: natural range 0 to 80;	--  The index of the next cell to write in wc_vector
    variable tmp:		natural range 0 to  7;	--  A temp counter used with write_cell_number to write the good cell
    variable read_cell_number:	natural range 0 to 80;	--  The index of the next cell to load in rc_vector
    variable read_word_cpt:	natural range 0 to 10;	--  The current index in the read burst
  begin
    if rising_edge(aclk)
      tmp := write_cell_number;	    --	Initalize tmp to the right index
      m_axi_m2s.bready <= '1';	    --  We are always ready to receive responces
      m_axi_m2s.wvalid <= '1';	    --  Our write data is always valid 
      for i in 0 to 7 loop
	if ((w_strobe(i) = '1') or (write_word_cpt != 0)) and (write_cell_number+tmp < 80) then	--  First burst call, will be written, not overflowing the cell_vector 
	    m_axi_m2s.wdata(8*i+7 downto 8*i) <= state2color(wc_vector(tmp));	--  Put the cell in a space that will be written
	    tmp := tmp +1							--  Assert that we've written another cell.
	end if;
      end loop;
      if write_word_cpt = 0 then
	m_axi_m2s.wstrb <= w_strobe;	--  Strobe for the first word
      else
	m_axi_m2s.wstrb <= '11111111':  --  For the other word we write everything (We may need a final strobe, we can compute it ourselves)
      end if;
      if m_axi_s2m.rvalid = '1' then	--  Slave is sending us the data
        for i in 0 to 7 loop
	  if ((r_strobe(i) = '1') or (read_word_cpt != 0)) and (r_offset + read_cell_number < 80) then --	Same concept than the write loop
            rc_vector(r_offset+read_cell_number) <= color2state(m_axi_s2m.rdata(8*i+7 downto 8*i)); --	Store the cell
	    read_cell_number := read_cell_number + 1;						    --	Assert that we've just loaded a new cell
	  end if:
        end loop;
	read_word_cpt := read_word_cpt + 1; --	We've just read a part of the burst   
	if m_axi_s2m.rlast = '1' then	--  Last part of the burst
	  done_reading_tmp  := '1'; -- We finished our loading job
	  read_cell_number  :=	0;  -- Reset cpt value for next read.
	  read_word_cpt	    :=	0;
	end if;
      end if;
      if m_axi_s2m.wready = '1' then -- We can write
	m_axi_m2s.bready <= '1';	--  We accept responce from the slave
        if write_cpt = wsize then   --	We finished writting
          m_axi_m2s.wlast   <= '1'; --	We assert wlast to notify the slave
	  done_writing_tmp  := '1'; --  Reset cpt value for next write
	  write_word_cpt    :=	0;
	  write_cell_number :=  0;
	else
	  write_word_cpt := write_word_cpt + 1;		    --	We've send another part of the burst
	  write_cell_number := write_cell_number + temp;    --  We refresh the number of cell written in memory  
	end if;
      end if;
    end if;
  end process wr_proc;
end architecture rtl;
