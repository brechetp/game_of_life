-- package definition for the address controller 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library main_lib;
use main_lib.main_pkg.all;


package addr_ctrl_pkg is 

  type ADDR_CTRL_STATE is (IDLE, START_LINE, INLINE, PRELOAD);

  constant W_BASE_ADDRESS: std_ulogic_vector := X"0123456789abcdef";
  constant R_BASE_ADDRESS: std_ulogic_vector := X"0123456789abcdef";

  function coordinates2offset(curretn_line, column: natural) return std_ulogic_vector(31 downto 0);


end package addr_ctrl_pkg;

package body addr_ctrl_pkg is

  function coordinates2offset(current_line, column: natural) return std_ulogic_vector(31 downto 0) is
    variable uline, ucol: unsigned(31 downto 0);
  begin
    uline := to_unsigned(current_line, 32);
    ucol := to_unsigned(column, 32);
    return (WORLD_WIDTH*uline + ucol) srl 3;
  end function;

end package body;


