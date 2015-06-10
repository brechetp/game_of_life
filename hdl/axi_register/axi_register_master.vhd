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

  read_pr: process(aclk)
    type state_type is (idle, request, read);
    signal state: state_type
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
	state <= idle;
      else
	done_reading <= '0';
	case state is
	  when idle=>
	    if read_rq = '1' then
	      m_axi_m2s.arvalid	<=  '1';
	      m_axi_m2s.araddr	<=  raddress;
	      m_axi_m2s.arlen	<=  rsize;
	      m_axi_m2s.arsize	<=  '011';
	      m_axi_m2s.arburst	<=  axi_burst_incr;
	      state <= request;
	    end if;
	  when request=>
	    if m_axi_s2m.arready <= '1' then
	      m_axi_m2s.arvalid	<=  '0';
	      state		<=  read;
	      read_cell_number  :=  0;		--  Reset cpt value for next read.
	      read_word_cpt	:=  0;
	  when write=>
	    if m_axi_s2m.rvalid = '1' then	--  Slave is sending us the data
	      for i in 0 to 7 loop
	        if ((r_strobe(i) = '1') or (read_word_cpt != 0)) and (r_offset + read_cell_number < 80) then
		  rc_vector(r_offset+read_cell_number) <= color2state(m_axi_s2m.rdata(8*i+7 downto 8*i));	--  Store the cell
		  read_cell_number := read_cell_number + 1;						--  Assert that we've just loaded a new cell
	        end if:
	      end loop;
	      read_word_cpt := read_word_cpt + 1;   --  We've just read a part of the burst   
	      if m_axi_s2m.rlast	= '1' then  --  Last part of the burst
	        done_reading<=  '1';		    --  We finished our loading job
		state	    <=	idle;
	      end if;
	    end if;
	end case;
      end if;
    end if;
  end process read_pr;

  write_pr: process(aclk)
    type state_type is (idle, request, write);
    signal state: state_type
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
	write_word_cpt	    :=	0;
	write_cell_number   :=	0;
	state <= idle;
      else
	done_writing <= '0';
        m_axi_m2s.bready <= '1';--  We are always ready to receive responces
        m_axi_m2s.wvalid <= '1';--  Our write data is always valid 
	tmp := write_word_cpt;
	for i in 0 to 7 loop
	  if ((w_strobe(i) = '1') or (write_word_cpt != 0)) and (write_cell_number+tmp < 80) then	--  First burst call, will be written, not overflowing the cell_vector 
	    m_axi_m2s.wdata(8*i+7 downto 8*i) <= state2color(wc_vector(tmp));	--  Put the cell in a space that will be written
	    tmp := tmp +1							--  Assert that we've written another cell.
	  end if;
        end loop;
	case state is
	  when idle=>
	    if write_rq = '1' then
	      m_axi_m2s.awvalid	<=  '1';
	      m_axi_m2s.awaddr	<=  waddress;
	      m_axi_m2s.awlen	<=  wsize;
	      m_axi_m2s.awsize	<=  '011';
	      m_axi_m2s.awburst	<=  axi_burst_incr;
	      m_axi_m2s.wstrb	<=  w_strobe;	--  Strobe for the first word
	      state <= request;
	    end if;
	  when request=>
	    if m_axi_s2m.awready <= '1' then
	      m_axi_m2s.awvalid	<=  '0';
	      m_axi_m2s.wstrb	<= '11111111':  --  For the other word we write everything (We may need a final strobe, we can compute it ourselves)
	      state		<=  write;
	      write_cell_number	:=  0;		--  Reset cpt value for next write.
	      tmp		:=  0;
	      write_word_cpt	:=  0;
	  when write=>
	    if m_axi_s2m.wready = '1' then  --	We can write
              if write_cpt = wsize-1 then   --	We finish writting
                m_axi_m2s.wlast <=  '1';    --	We assert wlast to notify the slave
		done_writing	<=  '1';
		state		<= idle;    --	We go back to idle state to wait for next request
	      else
		write_word_cpt := write_word_cpt + 1;		--  We've send another part of the burst
		write_cell_number := write_cell_number + tmp;	--  We refresh the number of cell written in memory  
	      end if;
	    end if;
	end case;
      end if;
    end if;
  end process write_pr;

end architecture rtl;
