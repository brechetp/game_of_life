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
    rsize:	    in  integer range 0 to 9;		--  size of reading burst
    r_strobe:	    in  std_ulogic_vector(7 downto 0);  --  Which part of the first 64 bit to read into rc_vector
    read_rq :	    in  std_ulogic:			--  request new read
    -- Read response signals
    done_reading:   out std_ulogic; --  Read finished
    rc_vector:	    out cell_vector;--  cell array to be read from
    -- Write control signals
    waddress:	    in  std_ulogic_vector(31 downto 0); --  Address from which to start writing
    wc_vector:	    in  cell_vector;			--  cell array to be written in memory
    wsize:	    in  integer range 0 to 9;		--  size of writting burst
    w_strobe:	    in	std_ulogic_vector(7 downto 0);	--  offset to the first non valid cell in rc_vector
    write_rq:	    in  std_ulogic;			--  Input data is valid - request new write
    w_offset:	    in	integer range 0 to 79;		--  offset from which to write in rc_vector
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
    variable do_write_rq:   std_ulogic;
    variable do_read_rq:    std_ulogic;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
	do_write_rq :=	'0';
	do_read_rq  :=	'0';
      else
	m_axi_m2s.awvalid <= '0';
	m_axi_m2s.arvalid <= '0';
	if write_rq = '1' then
	  do_write_rq	    := '1';
	  done_writing_tmp  := '0';
	elsif read_rq = '1' then
	  do_read_rq	    := '1';
	  done_reading_tmp  := '0';
	end if;
	if do_write_rq = '1' then
	  if m_axi_s2m.awready <= '1' then
	    m_axi_m2s.awvalid	<= '1';
	    m_axi_m2s.awaddr	<= address;
	    m_axi_m2s.awlen	<= 10;
	    m_axi_m2s.awsize	<= wsize;
	    m_axi_m2s.awburst	<= axi_burst_incr;
	    do_write_rq		:= '0';
	  end if;
	end if;
	if do_read_rq = '1' then
	  if m_axi_s2m.arready <= '1' then
	    m_axi_m2s.arvalid	<= '1';
	    m_axi_m2s.araddr	<= address;
	    m_axi_m2s.arlen	<= 10;
	    m_axi_m2s.arsize	<= rsize;
	    m_axi_m2s.arburst	<= axi_burst_incr;
	    do_read_rq		:= '0';
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
    variable write_cpt,read_cpt: natural;
  begin
    if rising_edge(aclk)
      for i in 0 to 7 loop
        m_axi_m2s.wdata(8*i+7 downto 8*i) <= convert2color(wc_vector(8*write_cpt + i));
      end loop;
      if m_axi_s2m.rvalid = '1' then
        for i in 0 to 7 loop
         rc_vector(8*read_cpt+i) <= convert2cell(m_axi_s2m.rdata(8*i+7 downto 8*i));
        end loop;
        read_cpt := read_cpt + 1;
	if m_axi_s2m.rlast = '1' then
	  done_reading_tmp := '1';
	  read_cpt := 0;
	end if;
      end if;
      if m_axi_s2m.wvalid = '1' then
        if write_cpt = wsize then
          m_axi_m2s.wlast = '1';
	  done_writing_tmp := '1';
	  write_cpt := 0;
	else
	  write_cpt := write_cpt + 1;
	end if;
      end if;
    end if;
  end process wr_proc;
end architecture rtl;
