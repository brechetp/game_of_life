library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package pack_cell is

  type CELL_STATE is (DEAD, NEWDEAD, NEWALIVE, ALIVE); -- the cell status
  type CELL_VECTOR is array(natural range <>) of CELL_STATE;
  subtype COLOR is STD_ULOGIC_VECTOR(7 downto 0); -- the cell colors, in the same order as the cells. BLACK: 00000000, RED: 11100000, GREEN: 00011100, WHITE: 11111111 
  type COLOR_VECTOR is array(natural range <>) of COLOR;
  subtype N_COUNT is INTEGER range 0 to 8; -- the number of neighbors
  subtype BIT_COUNT is BIT_VECTOR (1 downto 0); -- the number of neighbors in binary
  
  function "+"(S1, S2: CELL_STATE) return N_COUNT;
  function "+"(N: N_COUNT; S: CELL_STATE) return N_COUNT;
  function invert(state: CELL_STATE) return CELL_STATE;
  function color2state(colour: COLOR) return CELL_STATE;
  function state2color(state: CELL_STATE) return COLOR; 

end package pack_cell;


package body pack_cell is

  function "+"(S1, S2: CELL_STATE) return N_COUNT is
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

  function "+"(N: N_COUNT; S: CELL_STATE) return N_COUNT is
    variable SUM: N_COUNT := N;
  begin
    if S = ALIVE or S = NEWALIVE then
      SUM := SUM + 1;
    end if;
    return SUM;
  end "+";

  function color2state(colour: COLOR) return CELL_STATE is -- returns the cell state matching the color colour
    variable index: natural; -- the index of the cell we are looking for, we just need to look at the bits #2 & #7 to find it
    variable b_index: std_ulogic_vector(1 downto 0) := colour(2) & colour(7); -- e.g RED |1|1100|0|00 --> 10 --> 01 --> NEWDEAD
  begin
    index := to_integer(unsigned(b_index));
    return CELL_STATE'VAL(index); -- we look up the correct index in the state tab
  end color2state;

  function state2color(state: CELL_STATE) return COLOR is -- returns the color matching the cell state of cell
  begin
    return COLORS(CELL_STATE'POS(state)); -- COLORS is the global array defined in this package
  end state2color;

-- invert signal function
  function invert(state: CELL_STATE) return CELL_STATE is
  begin
    return CELL_STATE'VAL(3-CELL_STATE'POS(state)); -- ALIVE -> DEAAD, NEW_X -> NEW_Y
  end invert;

end package body pack_cell;

    
