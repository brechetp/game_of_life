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
    state_out: out CELL_STATE
  );
end entity cell;
  


architecture syn of cell is

begin


  process(clk)
    variable neighbour_count: BIT_COUNT; -- gives the count of neighbours
  begin
    if clk = '1' then -- on rising edge, we assume neighbors are ready
      if rstn = '0' then -- the reset is set
        state_out <= DEAD;
      else
	state_out <= DEAD;
        if run = '1' then -- we output something only if the run flag is set
          neighbour_count := three_count(N, NE, E, SE, S, SW, W, NW); -- we redefined the add operation
          case self is -- we check the old state
            when DEAD =>
              state_out <= DEAD; -- default case
              if neighbour_count(0) = '1' and neighbour_count(1) = '1' then -- reproduction
                state_out <= NEWALIVE;
              end if;
            when ALIVE =>
              state_out <= ALIVE; -- default case
              if neighbour_count(1) = '0' then -- count /= 2,3 -> death
                state_out <= NEWDEAD;
              end if;
            when NEWDEAD =>
              state_out <= DEAD; -- default case
              if neighbour_count(0) = '1' and neighbour_count(1) = '1' then -- count =3 -> reproduction
                state_out <= NEWALIVE;
              end if;
            when NEWALIVE =>
              state_out <= ALIVE;
              if neighbour_count(1) = '0' then --count /= 2,3  death
                state_out <= NEWDEAD;
              end if;
            end case ; -- end of the case switch
          end if;
        end if; -- end of the reset if
      end if; -- end of the synchronous block
  end process;

  

end architecture syn;



      
