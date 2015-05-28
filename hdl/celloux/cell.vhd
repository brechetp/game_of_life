-- file cell.vhdl
use WORK.pack_cell.all;


entity cell is
  port
  (
    clk, mode: in bit; -- mode will serve initialization purposes
    N, NE, E, SE, S, SW, W, NW: in CELL_STATE; -- the cell neighbors
    state_out: out CELL_STATE
  );
end entity cell;
  


architecture syn of cell is

  signal state: CELL_STATE;

begin


  state_out <= state; -- we copy our working state to output

  process(clk)
    variable neighbour_count: N_COUNT; 
  begin
    if clk = '1' and clk'event then -- on rising edge, we assume neighbors are ready
      neighbour_count := N + NE + E + SE + S + SW + W + NW; -- we redefined the add operation
      case state is -- we check the old state
        when DEAD =>
          if neighbour_count = 3 then -- reproduction
            state <= NEWALIVE;
          end if;
        when ALIVE =>
          if neighbour_count /= 2 and neighbour_count /= 3 then -- death
            state <= NEWDEAD;
          end if;
        when NEWDEAD =>
          if neighbour_count = 3 then -- reproduction
            state <= NEWALIVE;
          else
            state <= DEAD;
          end if;
        when NEWALIVE =>
          if neighbour_count /= 2 and neighbour_count /= 3 then -- death
            state <= NEWDEAD;
          else
            state <= ALIVE;
          end if;
      end case ;
      done <= '1'; -- the computation is done
    end if;
  end process;

  

end architecture syn;



      
