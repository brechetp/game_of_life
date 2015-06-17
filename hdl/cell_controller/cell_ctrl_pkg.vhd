-- cell_ctrl package for the game of life
--
library celloux_lib;
use celloux_lib.cell_pkg.all;

library address_controller_lib;
use address_controller_lib.addr_ctrl_pkg.all;

package cell_ctrl_pkg is

  -- constant declarations
  constant WINDOW_HEIGHT: POSITIVE := 2; -- the number of rows

  -- type declarations
  type WINDOW is array (0 to WINDOW_HEIGHT-1, 0 to N_CELL-1) of CELL_STATE;
  type CELL_CTRL_STATE is (FREEZE, READ, WRITE, NORMAL);


end package cell_ctrl_pkg;

