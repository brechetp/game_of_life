#define WORLD_WIDTH_MAX 1900
#define WORLD_HEIGHT_MAX 1600
#define MIN(a,b) (((a)<(b))?(a):(b))
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char** argv)
{
  int width, height;
  FILE* fid;
  char line[WORLD_WIDTH_MAX];
  int i, read;
  size_t len;
  char* addresse;
  int count;
  int* start_addr, *width_addr, *height_addr, *write_addr, *read_addr;
  int write_base_addr, read_base_addr;
  char current_char;

  addresse = (char *)0x47824672;


  height_addr = (int *)0x1342fe5;
  width_addr  = height_addr + 1;
  start_addr  = width_addr + 2;
  read_addr   = start_addr + 1;
  write_addr  = read_addr + 1;

  
  if (argc != 4)
  {
    printf("Use: init_file width height\n");
    exit(1);
  }


  width = MIN(atoi(argv[2]), WORLD_WIDTH_MAX);
  height = MIN(atoi(argv[3]), WORLD_HEIGHT_MAX);

  read_base_addr = 0x50000000;
  write_base_addr = read_base_addr + (width * height) * 8;

  if ((fid = fopen(argv[1], "r")) == NULL)
  {
    printf("The file cannot be found\n");
    exit(1);
  }
  count = 0;

  while (fgets (line, width+1, fid) && count <= height)
  {

    for(i = 0; i < len; i++)
    {
      current_char = line[i];
      switch (current_char)
      {
        case '#': /* alive */
          *(addresse) = 28;
          break;

        case '_':
          *(addresse) = 0;
          break;

        default:
          printf("Parsing error.\n");
          exit(1);
      }
      addresse++;
    }
    count ++;
  }

  if (count != height)
  {
    printf("The height doesn't match the file height.\n");
    exit(1);
  }

  *(height_addr) = height;
  *(width_addr)  = width;
  *(write_addr)  = write_base_addr;
  *(read_addr) = read_base_addr;

  *(start_addr)  = 1; /* the life awakens */


}

