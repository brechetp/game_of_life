-- file cell.vhdl
use WORK.pack_cell.all;


entity cell is
  port(clk, mode: bit; N, NE, E, SE, S, SW, W, NW: in STATUS; --mode is for init purpose
       state_out: out STATUS);
end entity cell;
  


architecture syn of cell is

  signal state: STATUS;


begin


  state_out <= state; -- we copy our working state to output

  process(clk)
    variable neighbour_count: N_COUNT; 
  begin
    if clk = '1' and clk'event then -- on rising edge
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
    end if;
  end process;

  

end architecture syn;



      
