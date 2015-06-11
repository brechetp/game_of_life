-- file cell_sim.vhd
--
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library celloux_lib;
use celloux_lib.pack_cell.all;

-- the entity of a simulation environment usually has no input output ports.
-- file cell_sim_arc.vhd
entity cell_sim is
  port(state: out CELL_STATE);
end entity cell_sim;

architecture sim of cell_sim is

-- we declare signals to be connected to the instance of cell. the names of the
-- signals are the same as the name of the ports of the entity cell because it is
-- much simpler but we could use different names and bind signal names to port
-- names in the instanciation of cell.
  signal clk, rstn, stop_simulation: std_ulogic := '0';
  signal N, NE, E, SE, S, SW, W, NW, SELF: CELL_STATE;
  signal rand: unsigned(31 downto 0) := b"00101101101010101011100110101110";
  signal index1: integer;
  signal index2: integer;
  signal index3: integer;
  signal index4: integer;
  signal index5: integer;
  signal index6: integer;
  signal index7: integer;
  signal index8: integer;
  signal index: integer;
  signal state_bit: std_ulogic; -- to test state2bit function

begin

-- this process generates a symmetrical clock with a period of 20 ns.
-- this clock will never stop.
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

  state_bit <= state2bit(self);

  rst_generator: process
  begin
    rstn <= '1';
    wait for 345 ns;
    rstn <= '0';
    if stop_simulation = '1' then
      wait;
    end if;
  end process rst_generator;

  slice: process(rand)
  begin 
    index1 <= to_integer(rand(1 downto 0));
    index2 <= to_integer(rand(5 downto 4));
    index3 <= to_integer(rand(9 downto 8));
    index4 <= to_integer(rand(13 downto 12));
    index5 <= to_integer(rand(17 downto 16));
    index6 <= to_integer(rand(21 downto 20));
    index7 <= to_integer(rand(25 downto 24));
    index8 <= to_integer(rand(29 downto 28));
    index <= to_integer(rand(3 downto 2));
  end process slice;

-- this process generates the input sequence for the signal neighbours.
  neighbour_generator: process
  begin -- we generate all 256 neighbour signals
    N  <= DEAD;
    NE <= DEAD;
    E  <= DEAD;
    SE <= DEAD;
    S  <= DEAD;
    SW <= DEAD;
    W  <= DEAD;
    NW <= DEAD;
    SELF <= DEAD;
    for i in 1 to 511 loop
      if clk = '1' then
        N <= CELL_STATE'VAL(index1);
        NE <= CELL_STATE'VAL(index2);
        E <= CELL_STATE'VAL(index3);
        SE <= CELL_STATE'VAL(index4);
        S <= CELL_STATE'VAL(index5);
        SW <= CELL_STATE'VAL(index6);
        W <= CELL_STATE'VAL(index7);
        NW <= CELL_STATE'VAL(index8);
        SELF <= CELL_STATE'VAL(index);
        rand <= resize(to_unsigned(1664525, 32) * rand + to_unsigned(1013904223, 32), 32);
      end if;
      wait on clk;
    end loop;
    report "End of simulation";
    stop_simulation <= '1';
    end process neighbour_generator;



-- we instanciate the entity cell, architecture syn. we name the instance i_cell and
-- specify the association between port names (left) and actual simulation signals (right).
  i_cell: entity celloux_lib.cell(syn)
  port map
  (
    clk       => clk,
    rstn => rstn,
    mode      => '1',
    N         => N,
    NE        => NE,
    E         => E,
    SE        => SE,
    S         => S,
    SW        => SW,
    W         => W,
    NW        => NW,
    self_state => SELF,
    state_out => state
  );

end architecture sim;
