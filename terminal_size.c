#include <sys/ioctl.h>
#include <stdio.h>
int main(int argc, char **argv)
{
  struct winsize sz;

  ioctl(0, TIOCGWINSZ, &sz);
  printf("%i %i %i %i\n", sz.ws_col, sz.ws_row, sz.ws_xpixel, sz.ws_ypixel);
  return 0;
}
