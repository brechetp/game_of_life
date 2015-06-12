library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

library axi_lib;
use axi_lib.axi_pkg.all;

library axi_register_lib;

entity axi_register_sim is
  port(
	start: out std_ulogic;
	height,width: out std_ulogic_vector(15 downto 0);
	color: out std_ulogic_vector(31 downto 0);
	widthx: out natural range 0 to 3
  );
end entity axi_register_sim;

architecture sim of axi_register_sim is

  signal aclk: std_ulogic;
  signal aresetn: std_ulogic;
  signal s_axi_m2s: axilite_gp_m2s;
  signal s_axi_s2m: axilite_gp_s2m;
  signal stop_simulation: std_ulogic := '0';
  
  begin

-- this process generates a symmetrical clock with a period of 20 ns.
-- this clock will never stop.
    clock_generator: process
    begin
      aresetn <= '1' after 20 ns;
      aclk <= '0';
      wait for 10 ns;
      aclk <= '1';
      wait for 10 ns;
      if stop_simulation = '1' then
        wait;
      end if;
    end process clock_generator;

    order_generator: process(aclk)
      variable cpt: integer :=0;
      begin
        if aresetn = '0' then
	  cpt := 0;
	elsif aclk = '1' then
          cpt := cpt +1;
	  s_axi_m2s.awvalid <= '0';
	  s_axi_m2s.wvalid <= '0';
	  s_axi_m2s.bready <= '1';
	  if cpt = 5 then
	    s_axi_m2s.awvalid <= '1';
	    s_axi_m2s.wvalid <= '1';
	    s_axi_m2s.awaddr <= "00000000000000000000000000000000";
	    s_axi_m2s.wdata <= "00000000000000000000000000000011";
	  elsif cpt = 10 then
	    s_axi_m2s.awvalid <= '1';
	    s_axi_m2s.wvalid <= '1';
	    s_axi_m2s.awaddr <= "00000000000000000000000000000100";
	    s_axi_m2s.wdata <= "00000000000000000000000000001001";
	  elsif cpt = 15 then
	    s_axi_m2s.awvalid <= '1';
	    s_axi_m2s.wvalid <= '1';
	    s_axi_m2s.awaddr <= "00000000000000000000000000001100";
	    s_axi_m2s.wdata <= "00000000011000000000110000000011";
	  elsif cpt = 20 then
	    s_axi_m2s.awvalid <= '1';
	    s_axi_m2s.wvalid <= '1';
	    s_axi_m2s.awaddr <= "00000000000000000000000000001000";
	    s_axi_m2s.wdata <= "00000000011000000000110000000011";
	  elsif cpt = 25 then
	    s_axi_m2s.awvalid <= '1';
	    s_axi_m2s.wvalid <= '1';
	    s_axi_m2s.awaddr <= "00000000000000000000000000001100";
	    s_axi_m2s.wdata <= "00000000011000000000110000000011";
	  end if;
	  if cpt = 40 then
	    stop_simulation <= '1';
          end if;
	end if;
  end process order_generator;

  axi_register: entity axi_register_lib.axi_register_v1(rtl)
  port map(
	aclk => aclk,
	aresetn => aresetn,
	height => height,
	width => width,
	start => start,
	color => color,
	s_axi_m2s => s_axi_m2s,
	s_axi_s2m => s_axi_s2m,
	widthx => widthx
  );

end architecture sim;
