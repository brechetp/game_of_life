-- simulation environment for ac.vhd, the cellular automaton
--
library ieee;
use ieee.std_logic_1164.all;
use work.main_pkg.all

entity ca_sim is
  port(cells : out array (0 to BUFFER_SIZE-1) of std_ulogic);
end entity ca_sim;

architecture sim of ca_sim is
  
  signal clk, stop_sim: bit;
  signal RR, RW, DR, DW: std_ulogic; -- Ready/Done Reading/Writing
  signal color_register: std_ulogic_vector(0 to BUFFER_SIZE-1);

clock_generator: process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
    if stop_simulation = '1' then
      wait;
    end if;
  end process clock_generator;


  color_generator: process
  begin
    color_register <= (others => '0');
    RR <= '0';
    RW <= '1';
    for i in 0 to 200 loop
      if rising_edge(clk) then
        for j in 0 to N_COLORS-1 loop
          color_register(j*8 to (j+1)*8-1) <= COLORS'VAL((j+i)+(i*j) mod 4);
        end loop;
        if (i mod 2 = 0) then
          RR <= not RR;
        end if;
        if (i mod 4 = 0) then
          RW <= not RW;

      end if;
    end loop;
    report "end of simulation";
    stop_sim <= '1';
  end process color_generator;


  -- we instanciate the entity ca, arc.
  --
  i_ca: entity main_lib.ca(arc)
  port map
  (
    clk => clk,
    WIDTH => 1280,
    HEIGHT => 840,
    READY_READING => RR,
    READY_WRITING => RW,
    DONE_READING => DR,
    DONE_WRITING => DW,
    in_register => color_register,
    out_register => cells
  );

end architecture sim;





