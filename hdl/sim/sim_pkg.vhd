library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;

library celloux_lib;
use celloux_lib.cell_pkg.all;


package sim_pkg is

  type data_row is array(0 to 10) of std_logic_vector(63 downto 0);
  type data_table is array(0 to 30) of data_row;
  type cell_table is array(0 to 30) of cell_vector(0 to 87);
  
  constant white_cells: data_table := (others => (others => (others =>'1')));

  type WRITE_STATE_TYPE is (W_IDLE, WRITE);
  type READ_STATE_TYPE is (R_IDLE, SEND);

  function gen_random_data_table(seed: natural) return data_table;
  function coloring(data: data_table) return cell_table;

end package sim_pkg;

package body sim_pkg is

  function gen_random_data_table(seed: natural) return data_table is
    variable rand: unsigned(31 downto 0) := to_unsigned(seed, 32);
    variable data: data_table;
    variable word: std_logic_vector(7 downto 0);
  begin
    for i in 0 to 30 loop
      for j in 0 to 10 loop
        rand := resize(to_unsigned(1664525, 32) * rand + to_unsigned(1013904223, 32), 32);
        for k in 0 to 7 loop
          word := std_logic_vector(COLORS(to_integer(rand(2*(k+1)-1 downto 2*k))));
          data(i)(j)(8*(k+1)-1 downto k*8) := word;
        end loop;
      end loop;
    end loop;
    return data;
  end gen_random_data_table;

  function coloring(data: data_table) return cell_table is
    variable res: cell_table;
  begin
    for i in 0 to 30 loop
      for j in 0 to 10 loop
        for k in 0 to 7 loop
          res(i)(j*8+k) := color2state(std_ulogic_vector(data(i)(j)(8*(k+1)-1 downto k*8)));
        end loop;
      end loop;
    end loop;
    return res;
  end coloring;

end package body;



