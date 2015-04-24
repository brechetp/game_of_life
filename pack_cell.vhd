package pack_cell is

  type STATUS is (DEAD, ALIVE);
  subtype N_COUNT is INTEGER range 0 to 8;
  
  function "+"(S1, S2: STATUS) return N_COUNT;
  function "+"(N: N_COUNT; S: STATUS) return N_COUNT;

end package pack_cell;


package body pack_cell is

  function "+"(S1, S2: STATUS) return N_COUNT is
    variable SUM: N_COUNT := 0;
  begin
    if S1 = ALIVE then
      SUM := SUM + 1;
    end if;
    if S2 = ALIVE then
      SUM := SUM + 1;
    end if;
    return SUM;
  end "+";

  function "+"(N: N_COUNT; S: STATUS) return N_COUNT is
    variable SUM: N_COUNT := N;
  begin
    if S = ALIVE then
      SUM := SUM + 1;
    end if;
    return SUM;
  end "+";
end package body pack_cell;

    
