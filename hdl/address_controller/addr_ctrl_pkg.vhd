-- package definition for the address controller 

library ieee;
use ieee.std_logic_1164.all;


package addr_ctrl_pkg is 

  type ADDR_CTRL_STATE is (IDLE, START_LINE, INLINE, PRELOAD);

  constant W_BASE_ADDRESS: std_ulogic_vector := X"0123456789abcdef"
  constant R_BASE_ADDRESS: std_ulogic_vector := X"0123456789abcdef"

end package addr_ctrl_pkg;
