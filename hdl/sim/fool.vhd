library ieee;
use ieee.std_logic_1164.all;


entity fool is
  port(
  s: out STD_LOGIC
);
end entity fool;

architecture arc of fool is
  signal clk: std_ulogic := '0';
  signal s_local: STD_LOGIC := 'L';
  signal stop: integer range 0 to 10 := 10;

begin
  aclk: process
  begin
    clk <= '0';
    wait for 20 ns;
    clk <= '1';
    wait for 20 ns;
    if stop = 0 then
      wait;
    end if;
  end process;

  process(clk)
  begin
    if clk = '1' then
      stop <= stop -1;
    end if;
  end process;

  process(clk)
  begin
    if clk = '1' then
      s_local <= 'H';
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and stop = 5) or (clk = '0') then
      s_local <= 'L';
    end if;
  end process;

  s <= s_local;

end architecture arc;
