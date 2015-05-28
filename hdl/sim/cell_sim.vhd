-- file cell_sim.vhd
library celloux_lib;
use celloux_lib.pack_cell.all;

-- the entity of a simulation environment usually has no input output ports.
-- file cell_sim_arc.vhd
entity cell_sim is
  port(state: out CELL);
end entity cell_sim;

architecture sim of cell_sim is

-- we declare signals to be connected to the instance of cell. the names of the
-- signals are the same as the name of the ports of the entity cell because it is
-- much simpler but we could use different names and bind signal names to port
-- names in the instanciation of cell.
  signal clk, stop_simulation: bit;
  signal N, NE, E, SE, S, SW, W, NW: CELL;

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
    for i in 1 to 511 loop
      if clk = '1' then
        if (i mod 256 = 0) then
          N <= invert(N);
        end if;
        if (i mod 128 = 0) then
          NE <= invert(NE);
        end if;
        if (i mod 64 = 0) then
          E <= invert(E);
        end if;
        if (i mod 32 = 0 ) then
          SE <= invert(SE);
        end if;
        if (i mod 16 = 0) then
          S <= invert(S);
        end if;
        if (i mod 8 = 0) then
          SW <= invert (SW);
        end if;
        if (i mod 4 = 0) then
          W <= invert(W);
        end if;
        NW <= invert(NW);
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
    mode      => '1',
    N         => N,
    NE        => NE,
    E         => E,
    SE        => SE,
    S         => S,
    SW        => SW,
    W         => W,
    NW        => NW,
    state_out => state
  );

end architecture sim;
