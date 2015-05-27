library ieee;
use ieee.std_logic_1164.all;

package pack_cell is

  type STATUS is (NEWDEAD, DEAD, NEWALIVE, ALIVE);
  subtype N_COUNT is INTEGER range 0 to 8;
  subtype BIT_COUNT is BIT_VECTOR (1 downto 0);
  constant NUMBER_CELL : integer := 80;
  type cell_array is array(0 to NUMBER_CELL-1) of STATUS;
  
  function "+"(S1, S2: STATUS) return N_COUNT;
  function "+"(N: N_COUNT; S: STATUS) return N_COUNT;
  function color2state(cell, color: std_ulogic_vector) return STATUS;
  function state2color(cell: STATUS; color: std_ulogic_vector) return std_ulogic_vector; 

end package pack_cell;


package body pack_cell is

  function "+"(S1, S2: STATUS) return N_COUNT is
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

  function "+"(N: N_COUNT; S: STATUS) return N_COUNT is
    variable SUM: N_COUNT := N;
  begin
    if S = ALIVE or S = NEWALIVE then
      SUM := SUM + 1;
    end if;
    return SUM;
  end "+";

  function color2state(cell, color: std_ulogic_vector) return STATUS is
    variable state: STATUS := DEAD;
  begin
    for i in 0 to 3 loop
      if cell = color(8*i+7 downto 8*i) then
        state := STATUS'VAL(i);
      end if;
    end loop;
    return state;
  end color2state;

  function state2color(cell: STATUS; color: std_ulogic_vector) return std_ulogic_vector is
  begin
    return color(8*STATUS'POS(cell)+7 downto 8*STATUS'POS(cell));
  end state2color;

end package body pack_cell;

    
