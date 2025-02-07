#ifndef __XEMU_H
#define __XEMU_H

#include <stdint.h>

#define XEMU_CONTROL 0xD6CF
#define XEMU_QUIT 0x42 //!< Command to make Xemu quit

void xemu_exit(int exit_code);

void assert_eq(int64_t a, int64_t b);

#endif
