-- simulation environment for ac.vhd, the cellular automaton
--
library ieee;
use ieee.std_logic_1164.all;
library global_lib;
use global_lib.numeric_std.all;
library celloux_lib;
use celloux_lib.cell_pkg.all;
library cell_controller_lib;
use cell_controller_lib.cell_ctrl_pkg.all;
library address_controller_lib;
use address_controller_lib.addr_ctrl_pkg.all;

entity cell_ctrl_sim is
  port(cells : out CELL_VECTOR(0 to N_CELL-3));
end entity cell_ctrl_sim;

architecture sim of cell_ctrl_sim is
  
  signal clk, rstn: std_ulogic := '1';
  signal stop_sim: std_ulogic :='0';
  signal DR, DW: std_ulogic; -- Done Reading/Writing
  signal read_cell_vector: CELL_VECTOR(0 to N_CELL-1);
  signal rand: unsigned(31 downto 0) := b"00101101101010101011100110101110";
  signal RR: STD_ULOGIC;

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
    variable RR_mem: STD_ULOGIC;
  begin
    read_cell_vector <= (others => DEAD);
    DR <= '0';
    DW <= '0';
    for i in 0 to 200 loop
      if clk = '1' then
        DR <= '0';
        DW <= '0';
        RR_mem := RR or RR_mem; -- we unset them one DR/DW are set
        for j in 0 to N_CELL-1 loop
          read_cell_vector(j) <= CELL_STATE'VAL(to_integer(rand(1 downto 0)));
        end loop;
        if (rand(3 downto 2) = "00" and DR = '0') then
          DR <= '1';
          RR_mem := '0';
        end if;
        rand <= resize(to_unsigned(1664525, 32) * rand + to_unsigned(1013904223, 32), 32);
        if i >= 120 and i <= 170 then
          DW <= '0';
        else
          if (rand(5 downto 4) = "00" and DW = '0') then
            DW <= '1';
            RR_mem := '0';
          end if;
        end if;
      end if;
      if i <= 6 then
        DW <= '1';
        DR <= '1';
      end if;
      wait on clk;
    end loop;
    report "end of simulation";
    stop_sim <= '1';
  end process cell_generator;


  -- we instanciate the entity cell_ctrl, arc.
  --
 i_cell_ctrl: entity cell_controller_lib.cell_ctrl(arc)
 port map
 (
   clk => clk,
   rstn => rstn,
   READY_CELL_CTRL => RR, -- write_cell_vector has been written by cell_ctrl
   DONE_READING => DR,
   DONE_WRITING => DW,
   read_cell_vector => read_cell_vector,
   write_cell_vector => cells
 );

end architecture sim;





