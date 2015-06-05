-- main package for the game of life
--
library celloux_lib;
use celloux_lib.PACK_CELL.all;

package main_pkg is

  -- constant declarations
  constant WORLD_WIDTH: POSITIVE := 1280; -- the world width
  constant WORLD_HEIGHT: POSITIVE := 840; -- the world height
  constant N_CELL: POSITIVE := 10; -- the number of cells per row
  constant WINDOW_HEIGHT: POSITIVE := 3; -- the number of rows
  constant BUFFER_SIZE: POSITIVE := N_CELL * 8; -- the length of the buffer

  -- type declarations
  type WINDOW is array (0 to WINDOW_HEIGHT-1, 0 to N_CELL-1) of CELL_STATE;


end package main_pkg;

