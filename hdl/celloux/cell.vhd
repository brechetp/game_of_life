-- file cell.vhdl
library ieee;
library WORK;
use ieee.std_logic_1164.all;
use WORK.pack_cell.all;


entity cell is
  port
  (
    clk, rstn: in std_ulogic; -- clock ans sychronous reset (active low)
    mode: in bit; -- mode will serve initialization purposes
    N, NE, E, SE, S, SW, W, NW: in CELL_STATE; -- the cell neighbors
    state_out: out CELL_STATE
  );
end entity cell;
  


architecture syn of cell is

  signal state: CELL_STATE;

begin


  state_out <= state; -- we copy our working state to output

  process(clk)
    variable neighbour_count: BIT_COUNT; -- gives the count of neighbours
  begin
    if clk = '1' and clk'event then -- on rising edge, we assume neighbors are ready
      if rstn = '0' then -- the reset is set
        state <= DEAD;
      else
        neighbour_count := right_count(N, NE, E, SE, S, SW, W, NW); -- we redefined the add operation
        case state is -- we check the old state
          when DEAD =>
            if neighbour_count(0) = '1' and neighbour_count(1) = '1' then -- reproduction
              state <= NEWALIVE;
            end if;
          when ALIVE =>
            if neighbour_count(0) = '0' and neighbour_count(1) = '0' then -- death
              state <= NEWDEAD;
            end if;
          when NEWDEAD =>
            if neighbour_count(0) = '1' and neighbour_count(1) = '1' then -- reproduction
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
        end case ; -- end of the case switch
      end if; -- end of the reset if
    end if; -- end of the synchronous block
  end process;

  

end architecture syn;



      
