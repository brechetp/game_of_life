-- file cell.vhdl
library ieee;
library WORK;
use ieee.std_logic_1164.all;
use WORK.cell_pkg.all;


entity cell is
  port
  (
    clk, rstn: in std_ulogic; -- clock ans sychronous reset (active low)
    run: in std_ulogic; -- if unset the state_out is a copy of mem_state
    N, NE, E, SE, S, SW, W, NW: in CELL_STATE; -- the cell neighbors
    self: in CELL_STATE; -- the gen n state
    state_out: out CELL_STATE -- the gen n+1 state
  );
end entity cell;
  


architecture syn of cell is

  signal next_state: CELL_STATE;

begin


  state_out <= next_state;

  process(clk)
    variable neighbour_count: BIT_COUNT; -- gives the count of neighbours
  begin
    if clk = '1' then -- on rising edge, we assume neighbors are ready
      if rstn = '0' then -- the reset is set
        next_state <= DEAD;
        state_out <= DEAD;
      else
        if run = '1' then -- we output something only if the run flag is set
          neighbour_count := three_count(N, NE, E, SE, S, SW, W, NW); -- we redefined the add operation
          case self is -- we check the old state
            when DEAD =>
              next_state <= DEAD; -- default case
              if neighbour_count(0) = '1' and neighbour_count(1) = '1' then -- reproduction
                next_state <= NEWALIVE;
              end if;
            when ALIVE =>
              next_state <= ALIVE; -- default case
              if neighbour_count(1) = '0' then -- count /= 2,3 -> death
                next_state <= NEWDEAD;
              end if;
            when NEWDEAD =>
              next_state <= DEAD; -- default case
              if neighbour_count(0) = '1' and neighbour_count(1) = '1' then -- count =3 -> reproduction
                next_state <= NEWALIVE;
              end if;
            when NEWALIVE =>
              next_state <= ALIVE;
              if neighbour_count(1) = '0' then --count /= 2,3  death
                next_state <= NEWDEAD;
              end if;
            end case ; -- end of the case switch
          end if;
        end if; -- end of the reset if
      end if; -- end of the synchronous block
  end process;

  

end architecture syn;



      
