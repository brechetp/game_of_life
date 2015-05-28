library ieee;
use ieee.std_logic_1164.all;

package pack_cell is

  type CELL_STATE is (DEAD, NEWDEAD, NEWALIVE, ALIVE); -- the cell status
  subtype COLOR is STD_ULOGIC_VECTOR(7 downto 0); -- the cell colors, in the same order as the cells. BLACK, RED, GREEN, WHITE
  type COLOR_VECTOR is array(natural range <>) of COLOR;
  subtype N_COUNT is INTEGER range 0 to 8; -- the number of neighbors
  subtype BIT_COUNT is BIT_VECTOR (1 downto 0); -- the number of neighbors in binary

  constant COLORS: array(0 to 3) of COLOR := (b"00000000", b"11100000", b"00011100", b"11111111"); -- black, red, green, white rrrgggbb 8-bit colors
  

  
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
    variable index: natural := to_integer(unsigned(colour(2,7))); -- the index of the cell we are looking for, we just need to look at the bits #2 & #7 to find it
  begin
    return CELL_STATE'VAL(index); -- we look up the correct index in the state tab
  end color2state;

  function state2color(cell: CELL_STATE) return COLOR is -- returns the color matching the cell state of cell
  begin
    return colours(CELL_STATE'POS(cell));
  end state2color;

-- invert signal function
  function invert(state: CELL_STATE) return CELL_STATE is
  begin
    return CELL_STATE'VAL(3-CELL_STATE'POS(state)) -- ALIVE -> DEAAD, NEW_X -> NEW_Y
  end invert;

end package body pack_cell;

    
