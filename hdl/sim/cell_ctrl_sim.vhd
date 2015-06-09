-- simulation environment for ac.vhd, the cellular automaton
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library celloux_lib;
use celloux_lib.pack_cell.all;
library main_lib;
use main_lib.main_pkg.all;

entity cell_ctrl_sim is
  port(cells : out CELL_VECTOR(0 to N_CELL-3);
      RR, RW: out std_ulogic);
end entity cell_ctrl_sim;

architecture sim of cell_ctrl_sim is
  
  signal clk, rstn: std_ulogic := '1';
  signal stop_sim: std_ulogic :='0';
  signal DR, DW: std_ulogic; -- Done Reading/Writing
  signal read_cell_vector: CELL_VECTOR(0 to N_CELL-1);
  signal rand: unsigned(31 downto 0) := b"00101101101010101011100110101110";

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

--  rst_generator: process
--  begin
--    rstn <= '1';
--    if stop_sim = '1' then
--      wait;
--    end if;
--  end process rst_generator;
  

  cell_generator: process
  begin
    read_cell_vector <= (others => DEAD);
    DR <= '1';
    DW <= '1';
    for i in 0 to 200 loop
      if clk = '1' then
        for j in 0 to N_CELL-1 loop
          read_cell_vector(j) <= CELL_STATE'VAL(to_integer(rand(1 downto 0)));
        end loop;
        if rand(3 downto 2) = "00" then
          DR <= not DR;
        end if;
        rand <= resize(to_unsigned(1664525, 32) * rand + to_unsigned(1013904223, 32), 32);
        if i >= 120 and i <= 170 then
          DW <= '0';
        else
          if rand(5 downto 4) = "00" then
            DW <= not DW;
          end if;
        end if;
      end if;
      wait on clk;
    end loop;
    report "end of simulation";
    stop_sim <= '1';
  end process cell_generator;


  -- we instanciate the entity cell_ctrl, arc.
  --
 i_cell_ctrl: entity main_lib.cell_ctrl(arc)
 port map
 (
   clk => clk,
   rstn => rstn,
   READY_READING => RR, -- read_cell_vector has been read by cell_ctrl
   READY_WRITING => RW, -- write_cell_vector has been written by cell_ctrl
   DONE_READING => DR,
   DONE_WRITING => DW,
   read_cell_vector => read_cell_vector,
   write_cell_vector => cells
   --lock => lock
 );

end architecture sim;





