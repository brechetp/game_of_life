-- cell_ctrl package for the game of life
--
library celloux_lib;
use celloux_lib.cell_pkg.all;

package cell_ctrl_pkg is

  -- constant declarations
  constant WORLD_WIDTH_MAX: POSITIVE := 1900; -- the world width
  constant WORLD_HEIGHT_MAX: POSITIVE := 1200; -- the world height
  constant N_CELL: POSITIVE := 80; -- the number of cells read per row
  constant WINDOW_HEIGHT: POSITIVE := 3; -- the number of rows
  constant BUFFER_SIZE: POSITIVE := N_CELL * 8; -- the length of the buffer

  -- type declarations
  type WINDOW is array (0 to WINDOW_HEIGHT-1, 0 to N_CELL-1) of CELL_STATE;
  type CELL_CTRL_STATE is (FREEZE, READ, WRITE, NORMAL);


end package cell_ctrl_pkg;

