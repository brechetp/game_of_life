library ieee;
use ieee.std_logic_1164.all;

package pack_cell is

  type CELL is (NEWDEAD, DEAD, NEWALIVE, ALIVE); -- the cell status
  subtype N_COUNT is INTEGER range 0 to 8; -- the number of neighbors
  subtype BIT_COUNT is BIT_VECTOR (1 downto 0); -- the number of neighbors in binary
  
  function "+"(S1, S2: CELL) return N_COUNT;
  function "+"(N: N_COUNT; S: CELL) return N_COUNT;
  function invert(state: CELL) return CELL;
  function color2state(cell, color: std_ulogic_vector) return CELL;
  function state2color(cell: CELL; color: std_ulogic_vector) return std_ulogic_vector; 

end package pack_cell;


package body pack_cell is

  function "+"(S1, S2: CELL) return N_COUNT is
    variable SUM: N_COUNT := 0;
  begin
    if (S1 = ALIVE) or (S1 = NEWALIVE) then
      SUM := SUM + 1;
    end if;
    if S2 = ALIVE or S2 = NEWALIVE then
      SUM := SUM + 1;
    end if;
    return SUM;
  end "+";

  function "+"(N: N_COUNT; S: CELL) return N_COUNT is
    variable SUM: N_COUNT := N;
  begin
    if S = ALIVE or S = NEWALIVE then
      SUM := SUM + 1;
    end if;
    return SUM;
  end "+";

  function color2state(cell, color: std_ulogic_vector) return CELL is
    variable state: CELL := DEAD;
  begin
    for i in 0 to 3 loop
      if cell = color(8*i+7 downto 8*i) then
        state := CELL'VAL(i);
      end if;
    end loop;
    return state;
  end color2state;

  function state2color(cell: CELL; color: std_ulogic_vector) return std_ulogic_vector is
  begin
    return color(8*CELL'POS(cell)+7 downto 8*CELL'POS(cell));
  end state2color;

-- invert signal function
  function invert(state: CELL) return CELL is
    variable new_state: CELL;
  begin
    new_state = CELL'VAL(3-CELL'POS(state)) -- ALIVE -> DEAAD, NEW_X -> NEW_Y
    return new_state;
  end invert;

end package body pack_cell;

    
