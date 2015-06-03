-- simulation environment for ac.vhd, the cellular automaton
--
library ieee;
use ieee.std_logic_1164.all;
library celloux_lib;
use celloux_lib.pack_cell.all;
library main_lib;
use main_lib.main_pkg.all;

entity ca_sim is
  port(cells : out CELL_VECTOR(0 to N_CELL-1);
      RR, RW, lock : out std_ulogic);
end entity ca_sim;

architecture sim of ca_sim is
  
  signal clk, rstn: std_ulogic;
  signal stop_sim: std_ulogic :='0';
  signal DR, DW: std_ulogic; -- Done Reading/Writing
  signal in_register: CELL_VECTOR(0 to N_CELL-1);

begin
  
  clock_generator: process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
    if stop_sim = '1' then
      wait;
    end if;
  end process clock_generator;

  rst_generator: process
  begin
    rstn <= '1';
    wait for 705 ns;
    rstn <= '0';
    wait for 20 ns;
    rstn <= '1';
    if stop_sim = '1' then
      wait;
    end if;
  end process rst_generator;


  cell_generator: process
    variable rand: integer range 0 to 255 := 35;
  begin
    in_register <= (others => DEAD);
    DR <= '1';
    DW <= '1';
    for i in 0 to 200 loop
      if clk = '1' then
        for j in 0 to N_CELL-1 loop
          in_register(j) <= CELL_STATE'VAL((rand*(i*j+i+j+1)) mod 4);
        end loop;
        if (rand mod 3) = 1 then
          DR <= not DR;
        end if;
        rand := (rand*137+ 187) mod 256;
        if (rand mod 3 = 0) then
          DW <= not DW;
        end if;
      end if;
      wait on clk;
    end loop;
    report "end of simulation";
    stop_sim <= '1';
  end process cell_generator;


  -- we instanciate the entity ca, arc.
  --
 i_ca: entity main_lib.ca(arc)
 port map
 (
   clk => clk,
   rstn => rstn,
   READY_READING => RR, -- in_register has been read by ca
   READY_WRITING => RW, -- out_register has been written by ca
   DONE_READING => DR,
   DONE_WRITING => DW,
   in_register => in_register,
   out_register => cells,
   lock => lock
 );

end architecture sim;





