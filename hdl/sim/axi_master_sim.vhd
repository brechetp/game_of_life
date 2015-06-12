-- file cell_sim.vhd
library celloux_lib;
use celloux_lib.cell_pkg.all;

library axi_lib;
use axi_lib.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

library axi_register_lib;

-- the entity of a simulation environment usually has no input output ports.
-- file cell_sim_arc.vhd
entity axi_master_sim is
  port(	m_axi_m2s: out axi_hp_m2s;
	done_writing, done_reading: out std_ulogic;
	rc_vector: out cell_vector(0 to 79)
  );
end entity axi_master_sim;

architecture sim of axi_master_sim is

-- we declare signals to be connected to the instance of cell. the names of the
-- signals are the same as the name of the ports of the entity cell because it is
-- much simpler but we could use different names and bind signal names to port
-- names in the instanciation of cell.
  signal m_axi_s2m: axi_hp_s2m;
  signal clk:             std_ulogic;
  signal stop_simulation: std_ulogic := '0';
  signal aresetn:   std_ulogic := '0';
  signal waddress:  std_ulogic_vector(31 downto 0) := "11001100110011001100110011001100";
  signal raddress:  std_ulogic_vector(31 downto 0) := "00110011001100110011001100110011";
  signal wsize:	    integer range 0 to 9 := 1;
  signal rsize:	    integer range 0 to 9 := 1;
  signal wc_vector: cell_vector(0 to 77);
  signal write_rq:  std_ulogic	:=  '0';
  signal read_rq:   std_ulogic  :=  '0';
  signal r_offset:  integer range 0 to 79 := 0;
  signal w_strobe:  std_ulogic_vector(7 downto 0);
  signal w_strobe_last:std_ulogic_vector(7 downto 0);
  signal r_strobe:  std_ulogic_vector(7 downto 0);
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
  order_generator: process(clk)
  variable cpt: integer :=0;
  begin
    if aresetn = '0' then
      m_axi_s2m <= (bid => (others => '0'), rid => (others => '0'), rdata => (others => '0'), rresp => axi_resp_okay, bresp => axi_resp_okay, others => '0');
      m_axi_s2m.awready <= '1';
      m_axi_s2m.arready <= '1';
      cpt := 0;
    elsif clk = '1' then
      cpt := cpt +1;
      read_rq <= '0';
      write_rq <= '0';
      if cpt = 9 then
        write_rq	<= '1';
        wsize	    <=  9;
        w_strobe	<=  "00001111";
        r_strobe    <= (others => '1');
        wc_vector   <= (1 => ALIVE, 5 => NEWALIVE, others => DEAD);
        r_offset    <= 0;
      elsif cpt = 10 then
        m_axi_s2m.wready <= '1';
      elsif cpt = 20 then
        read_rq <= '1';
        rsize   <=  9;
        r_strobe<= "00001111";
      elsif cpt = 23 then
        m_axi_s2m.rvalid <= '1';
        m_axi_s2m.rdata  <= (others => '0');
      elsif cpt = 24 then
        m_axi_s2m.rdata  <= (others => '1');
      elsif cpt = 32 then
        m_axi_s2m.rlast   <= '1';
      else
        write_rq    <=  '0';
      end if;
      if cpt = 50 then
        stop_simulation <= '1';
      end if;
    end if;
  end process order_generator;
  

  master: entity axi_register_lib.axi_register_master(rtl)
  port map(
      aclk	=>  clk,
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
      r_offset	=>  r_offset,
      w_strobe	=>  w_strobe,
      r_strobe	=>  r_strobe,
      w_strobe_last => w_strobe_last
  );

end architecture sim;
