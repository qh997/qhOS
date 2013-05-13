#include "const.h"
#include "console.h"
#include "global.h"
#include "proto.h"

PRIVATE void set_cursor(unsigned int position);
PRIVATE void flush(CONSOLE *p_con);

PUBLIC void init_screen(TTY *tty)
{
    int nr_tty = tty - tty_table;
    tty->console = console_table + nr_tty;

    int v_mem_size = V_MEM_SIZE >> 1;

    int con_v_mem_size = v_mem_size / NR_CONSOLES;
    tty->console->original_addr = nr_tty * con_v_mem_size;
    tty->console->v_mem_limit = con_v_mem_size;
    tty->console->current_start_addr = tty->console->original_addr;

    tty->console->cursor = tty->console->original_addr;

    if (nr_tty == 0) {
        tty->console->cursor = disp_pos / 2;
        disp_pos = 0;
    }
    else {
        for (const char *p = "[TTY #?]\n"; *p; p++)
            out_char(tty->console, *p == '?' ? nr_tty + '0' : *p);
    }

    set_cursor(tty->console->cursor);
}

PUBLIC int is_current_console(CONSOLE *p_con)
{
    return (p_con == &console_table[nr_current_console]);
}

PUBLIC void out_char(CONSOLE *p_con, char ch)
{
    u8 *p_vmem = (u8 *)(V_MEM_BASE + p_con->cursor * 2);

    switch (ch) {
        case '\n':
            if (p_con->cursor < p_con->original_addr
                              + p_con->v_mem_limit
                              - SCREEN_WIDTH) {
                p_con->cursor = p_con->original_addr + SCREEN_WIDTH
                              * ((p_con->cursor - p_con->original_addr)
                                 / SCREEN_WIDTH + 1);
            }
            break;
        case '\b':
            if (p_con->cursor > p_con->original_addr) {
                p_con->cursor--;
                *(p_vmem - 2) = ' ';
                *(p_vmem - 1) = DEFAULT_CHAR_COLOR;
            }
            break;
        default:
            if (p_con->cursor < p_con->original_addr
                              + p_con->v_mem_limit - 1) {
                *p_vmem++ = ch;
                *p_vmem++ = DEFAULT_CHAR_COLOR;
                p_con->cursor++;
            }
            break;
    }

    while (p_con->cursor >= p_con->current_start_addr + SCREEN_SIZE)
        scroll_screen(p_con, SCR_DN);

    flush(p_con);
}

PRIVATE void set_cursor(unsigned int position)
{
    disable_interrupt();
    out_byte(CRTC_ADDR_REG, CURSOR_H);
    out_byte(CRTC_DATA_REG, (position >> 8) & 0xFF);
    out_byte(CRTC_ADDR_REG, CURSOR_L);
    out_byte(CRTC_DATA_REG, position & 0xFF);
    enable_interrupt();
}

PRIVATE void set_vedio_start_addr(u32 addr)
{
    disable_int();
    out_byte(CRTC_ADDR_REG, START_ADDR_H);
    out_byte(CRTC_DATA_REG, (addr >> 8) & 0xFF);
    out_byte(CRTC_ADDR_REG, START_ADDR_L);
    out_byte(CRTC_DATA_REG, addr & 0xFF);
    enable_int();
}

PUBLIC void select_console(int nr_console)
{
    if ((nr_console < 0) || (nr_console >= NR_CONSOLES))
        return;

    flush(&console_table[nr_current_console = nr_console]);
}

PUBLIC void scroll_screen(CONSOLE *p_con, int dir)
{
    if (dir == SCR_UP) {
        if (p_con->current_start_addr > p_con->original_addr)
            p_con->current_start_addr -= SCREEN_WIDTH;
    }
    else if (dir == SCR_DN) {
        if (p_con->current_start_addr + SCREEN_SIZE
            < p_con->original_addr + p_con->v_mem_limit)
            p_con->current_start_addr += SCREEN_WIDTH;
    }
    else
        assert(dir == SCR_DN || dir == SCR_UP);

    flush(p_con);
}

PRIVATE void flush(CONSOLE *p_con)
{
    if (is_current_console(p_con)) {
        set_cursor(p_con->cursor);
        set_vedio_start_addr(p_con->current_start_addr);
    }
}
