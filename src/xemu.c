#include <xemu.h>
#include <mega65/memory.h>
#include <mega65/debug_calypis.h>

#include <stdio.h>
#include <stdlib.h>


void xemu_exit(int exit_code)
{
    POKE(XEMU_CONTROL, (uint8_t)exit_code);
    POKE(XEMU_CONTROL, XEMU_QUIT);
    exit(exit_code);
}

void assert_eq(int64_t a, int64_t b)
{
    char msg[40 + 1];
    sprintf(msg, "ASSERT-EQ %lld == %lld", a, b);
    debug_msg(msg);
    if (a != b) {
        xemu_exit(EXIT_FAILURE);
    }
}