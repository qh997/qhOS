#ifndef _KERL__TTY_H_
#define _KERL__TTY_H_

#include "sys/const.h"
#include "sys/console.h"

#define TTY_IN_BYTES 256

typedef struct s_tty
{
    u32 in_buf[TTY_IN_BYTES]; // TTY 输入缓冲区
    u32 *p_inbuf_head;        // 指向缓冲区中下一个空闲位置
    u32 *p_inbuf_tail;        // 指向键盘任务应处理的键值
    int inbuf_count;          // 缓冲区中已经填充了多少

    struct s_console *p_console;
} TTY;

#endif