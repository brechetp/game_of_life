package pack_cell is

  type STATUS is (DEAD, ALIVE);
  subtype N_COUNT is INTEGER range 0 to 8;
  subtype BIT_COUNT is BIT_VECTOR (1 downto 0);
  
  function "+"(S1, S2: STATUS) return N_COUNT;
  function "+"(N: N_COUNT; S: STATUS) return N_COUNT;
  function invert(state: STATUS) return STATUS;
  function csa_adder(A, B, C: STATUS) return BIT_COUNT;
  function csa_adder(X, Y, Z: bit) return BIT_COUNT;

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
  
-- invert signal function
  function invert(state: STATUS) return STATUS is
    variable new_state: STATUS;
  begin
    if state = ALIVE then
      new_state := DEAD;
    else
      new_state := ALIVE;
    end if;
    return new_state;
  end invert;

  function csa_adder(A, B, C: STATUS) return BIT_COUNT is
    variable result: BIT_COUNT;
  begin
    result(0) := (A = ALIVE xor B = ALIVE xor C = ALIVE);
    result(1) := (A = ALIVE and B = ALIVE) or (A = ALIVE and C = ALIVE) or (B = ALIVE and C = ALIVE);
    return result;
  end csa_adder;

  function csa_adder(X, Y, Z: bit) return BIT_COUNT is
    varialbe result: BIT_COUNT;
  begin
    result(0) := X xor Y xor Z;
    result(1) := (X and Y) or (X and Z) or (Y and Z);
    return result;
  end csa_adder;

end package body pack_cell;

    
