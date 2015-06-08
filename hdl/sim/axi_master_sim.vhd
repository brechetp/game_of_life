-- file cell_sim.vhd
library celloux_lib;
use celloux_lib.pack_cell.all;

-- the entity of a simulation environment usually has no input output ports.
-- file cell_sim_arc.vhd
entity axi_sim is
  port(	m_axi_m2s: out axi_gp_m2s;
	done_writing, done_reading: out std_ulogic;
	rc_vector: out cell_vector
  );
end entity axi_sim;

architecture sim of axi_sim is

-- we declare signals to be connected to the instance of cell. the names of the
-- signals are the same as the name of the ports of the entity cell because it is
-- much simpler but we could use different names and bind signal names to port
-- names in the instanciation of cell.
  signal m_axi_s2m: cell_vector;
  signal clk, stop_simulation: bit;
  signal aresetn:   bit := '0';
  signal waddress:  std_ulogic_vector(31 downto 0) := "11001100110011001100110011001100";
  signal raddress:  std_ulogic_vector(31 downto 0) := "00110011001100110011001100110011";
  signal wsize:	    integer range 0 to 9 := 1;
  signal rsize:	    integer range 0 to 9 := 1;
  signal wc_vector: cell_vector(0 to 79);
  signal write_rq:  std_ulogic	:=  '0'
  signal read_rq:   std_ulogic  :=  '0'
  signal w_offset:  integer range 0 to 79 := 0;
begin

-- this process generates a symmetrical clock with a period of 20 ns.
-- this clock will never stop.
  clock_generator: process
  begin
    aresetn <= '1' after 20 ns;
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
    if stop_simulation = '1' then
      wait;
    end if;
  end process clock_generator;

-- this process will drive the axi_master input so as to get him to act
  order_generator: process
  begin
    if aresetn = '0' then
      m_axi_s2m => (others <= 0);
      m_axi_s2m.awready <= '1';
      m_axi_s2m.arready <= '1';
    else
      wait on aclk;
      write_rq	<= '1';
      wsize	<=  9;
      w_strobe	<=  '00001111';
      wc_vector <= (1 => ALIVE, 5 => NEWALIVE, others => DEAD);
      for i in 0 to 50 loop
	wait on aclk;
	if aclk = '1' then
	  write_rq <= 0
	end if;
      end loop;
    end if;

    
  end process order_generator
  

  master: entity axi_register_lib.axi_register_master(rtl)
  port map(aclk	=>  clk,
  aresetn	=>  aresetn,
  m_axi_m2s	=>  m_axi_m2s,
  m_axi_s2m	=>  m_axi_s2m,
  waddress      =>  waddress,
  raddress	=>  raddress,
  wsize		=>  wsize,
  rsize		=>  rsize,
  wc_vector	=>  wc_vector,
  write_rq	=>  write_rq,
  read_rq	=>  read_rq,
  done_writing	=>  done_writing,
  done_reading	=>  done_reading,
  rc_vector	=>  rc_vector,
  w_offset	=>  w_offset,
  w_strobe	=>  w_strobe,
  r_strobe	=>  r_strobe
  );

end architecture sim;
