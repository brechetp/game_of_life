library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package pack_cell is

  type CELL_STATE is (DEAD, NEWDEAD, NEWALIVE, ALIVE); -- the cell status
  type CELL_VECTOR is array(natural range <>) of CELL_STATE;
  subtype COLOR is STD_ULOGIC_VECTOR(7 downto 0); -- the cell colors, in the same order as the cells. BLACK, RED, GREEN, WHITE
  type COLOR_VECTOR is array(natural range <>) of COLOR;
  subtype N_COUNT is INTEGER range 0 to 8; -- the number of neighbors
  subtype BIT_COUNT is std_ulogic_vector (1 downto 0); -- the number of neighbors in binary

  constant COLORS: COLOR_VECTOR := (b"00000000", b"11100000", b"00011100", b"11111111"); -- black, red, green, white rrrgggbb 8-bit colors
  

  
  function "+"(S1, S2: CELL_STATE) return N_COUNT;
  function "+"(N: N_COUNT; S: CELL_STATE) return N_COUNT;
  function invert(state: CELL_STATE) return CELL_STATE;
  function color2state(colour: COLOR) return CELL_STATE;
  function state2color(state: CELL_STATE) return COLOR; 
  function state2bit(s: cell_state) return std_ulogic; -- gives a 1 if alive/new_alive, else 0
  function csa_adder(s1, s2, s3: cell_state) return BIT_COUNT; -- returns a two bit value from states
  function csa_adder(x, y, z: std_ulogic) return BIT_COUNT; -- returns a two bit value from bits
  function right_count(s1, s2, s3, s4, s5, s6, s7, s8: cell_state) return BOOLEAN;

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
    variable b_index: std_ulogic_vector(1 downto 0) := colour(2) & colour(7);
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

  function state2bit (s: cell_state) return std_ulogic is
  begin
    return to_unsigned(CELL_STATE'POS(s), 2)(1);
  end state2bit;

-- csa adder implementation for cells
  function csa_adder(x, y, z: std_ulogic) return BIT_COUNT is
    variable result: BIT_COUNT;
  begin
    result(0) := (x xor y xor z); -- basic implemetation of csa adder
    result(1) := (x and y) or (x and z) or (y and z);
    return result;
  end csa_adder;

  function csa_adder(s1, s2, s3: cell_state) return BIT_COUNT is
  begin
    return csa_adder(state2bit(s1), state2bit(s2), state2bit(s3)); -- translates state to bit
  end csa_adder;

  function right_count(s1, s2, s3, s4, s5, s6, s7, s8: cell_state) return boolean is
    variable alpha_a, beta_b, gamma_c : BIT_COUNT; -- the first csa outputs
  begin
    alpha_a := csa_adder(s1, s2, s3);
    beta_b := csa_adder(s4, s5, s6);
    gamma_c := csa_adder(s7, s8, DEAD);
    return ((((alpha_a(0) and beta_b(0)) or (alpha_a(0) and gamma_c(0)) or (beta_b(0) and gamma_c(0))) xor (alpha_a(1) xor beta_b(1) xor gamma_c(1))) = '1'); -- te sum is a+b+c + 2*(alpha+beta+gamma) so we check if we have the 2 bit set
  end right_count;





end package body pack_cell;

    
