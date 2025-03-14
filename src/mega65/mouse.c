#include <mega65/memory.h>
#include <mega65/mouse.h>

unsigned short mouse_min_x = 0;
unsigned short mouse_min_y = 0;
unsigned short mouse_max_x = 319;
unsigned short mouse_max_y = 199;
unsigned short mouse_x = 0;
unsigned short mouse_y = 0;
unsigned char mouse_sprite_number = 0xff;
unsigned char mouse_pot_x = 0;
unsigned char mouse_pot_y = 0;
char mouse_click_flag = 0;

void mouse_set_bounding_box(
    unsigned short x1, unsigned short y1, unsigned short x2, unsigned short y2)
{
    mouse_min_x = x1;
    mouse_min_y = y1;
    mouse_max_x = x2;
    mouse_max_y = y2;
}

void mouse_bind_to_sprite(unsigned char sprite_num)
{
    mouse_sprite_number = sprite_num;
}

void mouse_clip_position(void)
{
    if (mouse_x < mouse_min_x) {
        mouse_x = mouse_min_x;
    }
    if (mouse_y < mouse_min_y) {
        mouse_y = mouse_min_y;
    }
    if (mouse_x > mouse_max_x) {
        mouse_x = mouse_max_x;
    }
    if (mouse_y > mouse_max_y) {
        mouse_y = mouse_max_y;
    }
}

char mouse_clicked(void)
{
    if (!(PEEK(0xDC01) & 0x10)) {
        mouse_click_flag = 1;
    }
    if (mouse_click_flag) {
        mouse_click_flag = 0;
        return 1;
    }
    return 0;
}

void mouse_update_pointer(void)
{
    if (mouse_sprite_number < 8) {
        POKE(0xD000U + (unsigned char)(mouse_sprite_number << 1), mouse_x & 0xff);
        if (mouse_x & 0x100) {
            POKE(0xD010U, PEEK(0xD010U) | (unsigned char)(1 << mouse_sprite_number));
        }
        else {
            POKE(0xD010U, PEEK(0xD010U) & (0xFF - (unsigned char)(1 << mouse_sprite_number)));
        }
        if (mouse_x & 0x200) {
            POKE(0xD05FU, PEEK(0xD05FU) | (unsigned char)(1 << mouse_sprite_number));
        }
        else {
            POKE(0xD05FU, PEEK(0xD05FU) & (0xFF - (unsigned char)(1 << mouse_sprite_number)));
        }

        POKE(0xD001U + (unsigned char)(mouse_sprite_number << 1), mouse_y & 0xff);
        if (mouse_y & 0x100) {
            POKE(0xD077U, PEEK(0xD077U) | (unsigned char)(1 << mouse_sprite_number));
        }
        else {
            POKE(0xD077U, PEEK(0xD077U) & (0xFF - (1 << mouse_sprite_number)));
        }
        if (mouse_y & 0x200) {
            POKE(0xD05FU, PEEK(0xD05FU) | (unsigned char)(1 << mouse_sprite_number));
        }
        else {
            POKE(0xD078U, PEEK(0xD078U) & (0xFF - (1 << mouse_sprite_number)));
        }
    }
}

unsigned char inspect = 0;
void mouse_update_position(unsigned short* mx, unsigned short* my)
{
    unsigned char delta, v;
    v = (PEEK(0xD620) >> 1) & 0x3f;
    delta = v - mouse_pot_x;
    mouse_pot_x = v;
    if (delta < 0x10) {
        mouse_x += delta;
    }
    if (delta > 0xf0) {
        mouse_x -= 0x100 - delta;
    }

    v = (PEEK(0xD621) >> 1) & 0x3f;
    delta = v - mouse_pot_y;
    mouse_pot_y = v;
    if (delta < 0x10) {
        mouse_y -= delta;
    }
    if (delta > 0xf0) {
        mouse_y += 0x100 - delta;
    }

    mouse_clip_position();
    mouse_update_pointer();

    if (!(PEEK(0xDC01) & 0x10)) {
        mouse_click_flag = 1;
    }

    if (mx) {
        *mx = mouse_x;
    }
    if (my) {
        *my = mouse_y;
    }
}

void mouse_warp_to(unsigned short x, unsigned short y)
{
    mouse_x = x;
    mouse_y = y;
    mouse_clip_position();
    mouse_update_pointer();

    // Mark POT position as read
    mouse_pot_x = (PEEK(0xD620) >> 1) & 0x3f;
    mouse_pot_y = (PEEK(0xD621) >> 1) & 0x3f;
}
