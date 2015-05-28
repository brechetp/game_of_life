-- main package for the game of life
--

library CELLOUX_LIB;
use CELLOUX_LIB.PACK_CELL;

package main_pkg is

  -- constant declarations
  constant WIDTH: POSITIVE := 1280; -- the world width
  constant HEIGHT: POSITIVE := 840; -- the world height
  constant N_CELL: POSITIVE := 128; -- the number of cells per row
  constant WINDOW_HEIGHT: POSITIVE := 3; -- the number of rows
  constant BUFFER_SIZE: POSITIVE := N_CELL * 8; -- the length of the buffer

  -- type declarations
  type WINDOW is array (0 to WINDOW_HEIGHT-1, 0 to N_CELL-1) of CELL_STATE;


end package main_pkg;

