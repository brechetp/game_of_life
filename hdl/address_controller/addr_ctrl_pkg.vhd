-- package definition for the address controller 

library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
library global_lib;
use global_lib.numeric_std.all;



package addr_ctrl_pkg is 

  type ADDR_CTRL_READ_STATE is (R_IDLE, R_START_LINE, R_INLINE, R_PRELOAD, R_POSTLOAD, R_WAIT); -- the read state
  type ADDR_CTRL_WRITE_STATE is (W_IDLE, W_START, W_WAIT); -- the write state (W_IDLE when waiting for a new generation to compute)

  constant W_BASE_ADDRESS: unsigned := X"0123456789abcdef";
  constant R_BASE_ADDRESS: unsigned := X"0123456789abcdef";
  constant WORLD_WIDTH_MAX: natural := 1920; -- world maximum dimensions
  constant WORLD_HEIGHT_MAX: natural := 1600;
  constant N_CELL: POSITIVE := 80; -- the number of cells read per row

  function coordinates2offset(current_line, column, width: natural) return unsigned; -- returns the offset of the cell in the world


end package addr_ctrl_pkg;

package body addr_ctrl_pkg is

  function coordinates2offset(current_line, column, width: natural) return unsigned is -- assuming we have enough space left ("small" world)
    variable uline, ucol: unsigned(31 downto 0);
    variable res : unsigned(31 downto 0);
  begin
    uline := to_unsigned(current_line, 32);
    ucol := to_unsigned(column, 32);
    res := to_unsigned(width, 32)*uline + ucol;
    return res(28 downto 0) & b"000"; -- left shift to multiply by 8
  end function;

end package body;


