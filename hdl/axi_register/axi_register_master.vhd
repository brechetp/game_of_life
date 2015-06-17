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
use celloux_lib.cell_pkg.all;

-- See the README file for a detailed description of the AXI register master

entity axi_register_master is
  port(
    aclk:                      in  std_ulogic;
    aresetn:                   in  std_ulogic;
    -- AXI lite slave port
    m_axi_m2s:                 out axi_hp_m2s;
    m_axi_s2m:                 in  axi_hp_s2m;
    -- Read control signals
    raddress:                  in  std_ulogic_vector(31 downto 0); --  Address from which to start reading
    rsize:                     in  integer range 0 to 15;		      --  size of reading burst
    r_strobe:                  in  std_ulogic_vector(7 downto 0);  --  Which part of the first 64 bit to read into rc_vector
    read_rq :                  in  std_ulogic;			                --  request new read
    r_offset:                  in	integer range 0 to 79;		      --  offset from which to write in rc_vector
    -- Read response signals
    done_reading:              out std_ulogic;                     --  Read finished
    rc_vector:                 out cell_vector(0 to 79);           --  cell array to be read from
    -- Write control signals
    waddress:                  in  std_ulogic_vector(31 downto 0); --  Address from which to start writing
    wc_vector:                 in  cell_vector(0 to 77);			      --  cell array to be written in memory
    wsize:                     in  integer range 0 to 15;		      --  size of writting burst
    w_strobe:                  in	std_ulogic_vector(7 downto 0);	--  Strobe for the first part of the burst
    w_strobe_last:             in  std_ulogic_vector(7 downto 0);  --  Strobe for the last part of the burst
    write_rq:                  in  std_ulogic;			                --  Input data is valid - request new write
    -- Write response signals
    done_writing:              out std_ulogic                    --  Write succesfull, ready for another
  );
end axi_register_master;

architecture rtl of axi_register_master is
    type rstate_type is (idle, request, read);
    type wstate_type is (idle, request, write);
    signal rstate: rstate_type;
    signal wstate: wstate_type;
    signal read_cell_number:integer range 0 to 80;
    signal read_word_cpt:   integer range 0 to 16;  
begin
  -- Signals driven at constant value
  -- We do not use transaction id, Quality of service
  -- We are accessing unsecured data
  m_axi_m2s.arid    <= (others => '0');
  m_axi_m2s.arlock  <= (others => '0');
  m_axi_m2s.arcache <= (others => '0');
  m_axi_m2s.arprot  <= (others => '0');
  m_axi_m2s.arqos   <= (others => '0');
  m_axi_m2s.awid    <= (others => '0');
  m_axi_m2s.awlock  <= (others => '0');
  m_axi_m2s.awprot  <= (others => '0');
  m_axi_m2s.awqos   <= (others => '0');
  m_axi_m2s.wid	    <= (others => '0');
  m_axi_m2s.awcache <= (others => '0');

  m_axi_m2s.arsize  <=  "011";
  m_axi_m2s.arburst <=  axi_burst_incr;
  m_axi_m2s.araddr  <=  raddress;
  m_axi_m2s.arlen   <=  std_ulogic_vector(to_unsigned(rsize, m_axi_m2s.arlen'length));

  m_axi_m2s.bready  <= '1'; --  We are always ready to receive responces
  m_axi_m2s.wvalid  <= '1'; --  Our write data is always valid 
  m_axi_m2s.awaddr  <=  waddress;
  m_axi_m2s.awlen   <=  std_ulogic_vector(to_unsigned(wsize, m_axi_m2s.awlen'length));
  m_axi_m2s.awsize  <=  "011";
  m_axi_m2s.awburst <=  axi_burst_incr;

  read_pr: process(aclk)
    variable tmp: integer range 0 to 8;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        rstate <= idle;
        m_axi_m2s.arvalid   <=  '0';
        m_axi_m2s.rready    <=  '0';
      else
        done_reading	    <= '0';
	      m_axi_m2s.arvalid   <=  '0';
        case rstate is
          when idle=>
            if read_rq = '1' then
              m_axi_m2s.arvalid	<=  '1';
              rstate <= request;
            end if;
          when request=>
	          m_axi_m2s.arvalid	<=  '1';
	          m_axi_m2s.rready	<=  '0';
            if m_axi_s2m.arready = '1' then
              m_axi_m2s.arvalid	<=  '0';
              m_axi_m2s.rready  <=  '1';
              rstate	        <=  read;
              read_cell_number  <=  0;		--  Reset cpt value for next read.
              read_word_cpt	<=  0;
            end if;
          when read=>
	          m_axi_m2s.rready  <=  '1';
            if m_axi_s2m.rvalid = '1' then	--  Slave is sending us the data
              tmp := 0;
              for i in 0 to 7 loop
                if ((r_strobe(i) = '1') or (read_word_cpt /= 0)) and ((r_offset + read_cell_number) < 80) then
                  rc_vector(r_offset+read_cell_number+tmp) <= color2state(m_axi_s2m.rdata(8*i+7 downto 8*i));	--  Store the cell
                  tmp := tmp + 1;						                                    --  Assert that we've just loaded a new cell
                end if;
              end loop;
              read_cell_number  <= read_cell_number + tmp;
              read_word_cpt     <= read_word_cpt + 1;   --  We've just read a part of the burst   
              if m_axi_s2m.rlast	= '1' then  --  Last part of the burst
                done_reading      <=  '1';		    --  We finished our loading job
                m_axi_m2s.rready  <=  '0';
                rstate	          <=  idle;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process read_pr;

  write_pr: process(aclk)
    variable write_word_cpt:    integer range 0 to 16;
    variable write_cell_number: integer range 0 to 80;
    variable tmp:               integer range 0 to 8;
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        write_word_cpt	    :=	0;
        write_cell_number   :=	0;
        wstate              <= idle;
        done_writing	      <=	'0';
      else
        done_writing <= '0';
        tmp          :=  0;
        for i in 0 to 7 loop
          if ((w_strobe(i) = '1') or (write_word_cpt /= 0)) and (write_cell_number + tmp < 78) then	--  First burst call, will be written, not overflowing the cell_vector 
            m_axi_m2s.wdata(8*i+7 downto 8*i) <= state2color(wc_vector(write_cell_number +  tmp));	--  Put the cell in a space that will be written
            tmp := tmp +1;                          							--  Assert that we've written another cell.
          end if;
        end loop;
        m_axi_m2s.awvalid   <=  '0';
        m_axi_m2s.wstrb	    <=  (others => '1');
        m_axi_m2s.wlast     <=  '0';
        case wstate is
          when idle=>
            if write_rq = '1' then
              m_axi_m2s.awvalid	<=  '1';
              m_axi_m2s.wstrb	  <=  w_strobe;	--  Strobe for the first word
              wstate            <= request;
            end if;
          when request=>
	          m_axi_m2s.awvalid	<=  '1';
            if m_axi_s2m.awready <= '1' then
              m_axi_m2s.wstrb	<=  w_strobe;	--  Strobe for the first word
              m_axi_m2s.awvalid	<=  '0';
              wstate	    	<=  write;
              write_cell_number	:=  0;		--  Reset cpt value for next write.
              write_word_cpt	:=  0;
            end if;
          when write=>
            if m_axi_s2m.wready = '1' then            --  We wrote one.
              write_cell_number := write_cell_number + tmp -1;	--  We refresh the number of cell written in memory  
              write_word_cpt    := write_word_cpt + 1;--  We've send another part of the burst
              tmp               :=  0;
              for i in 0 to 7 loop
                if ((w_strobe(i) = '1') or (write_word_cpt /= 0)) and (write_cell_number + tmp < 78) then	--  First burst call, will be written, not overflowing the cell_vector 
                  m_axi_m2s.wdata(8*i+7 downto 8*i) <= state2color(wc_vector(write_cell_number + tmp));	--  Put the cell in a space that will be written
                  tmp := tmp +1;                          							--  Assert that we've written another cell.
		            else
		              m_axi_m2s.wdata(8*i+7 downto 8*i) <= (others => '0');
                end if;
              end loop;
              if write_word_cpt = wsize-1 then       --	The next one will be the last
                m_axi_m2s.wlast <=  '1';       --	We assert wlast to notify the slave
                m_axi_m2s.wstrb <=  w_strobe_last;  
                done_writing	  <=  '1';
                wstate	    	  <=  idle;        --	We go back to idle state to wait for next request
              end if;
            end if;
        end case;
      end if;
    end if;
  end process write_pr;

end architecture rtl;
