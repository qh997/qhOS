
SELECTOR_KERNEL_CS  equ  8 ; LABEL_DESC_FLAT_C  - LABEL_GDT = 8

extern  cstart
extern  exception_handler
extern  spurious_irq

extern  disp_pos
extern  gdt_ptr
extern  idt_ptr

[section .bss]
StackSpace:  resb  2 * 1024 ; 2KB 的堆栈
StackTop:

[section .text]
global  _start

global  divide_error
global  single_step_exception
global  nmi
global  breakpoint_exception
global  overflow
global  bounds_check
global  inval_opcode
global  copr_not_available
global  double_fault
global  copr_seg_overrun
global  inval_tss
global  segment_not_present
global  stack_exception
global  general_protection
global  page_fault
global  copr_error

global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15

; 内存示意图
    ;           ┃             ...            ┃
    ;           ┃                            ┃
    ;           ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┃■■■■■■■ Page  Tables ■■■■■■■┃
    ;           ┃■■■■ (Decide by LOADER) ■■■■┃ PageTblBase
    ; 00101000h ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┃■■■ Page Directory Table ■■■┃ PageDirBase = 1M
    ; 00100000h ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┃□□□□ Hardware  Reserved □□□□┃ B8000h ← gs
    ;    9FC00h ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┃■■■■■■■■ LOADER.BIN ■■■■■■■■┃ somewhere in LOADER ← esp
    ;    90000h ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┃■■■■■■■■ KERNEL.BIN ■■■■■■■■┃
    ;    80000h ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┃■■■■■■■■■■ KERNEL ■■■■■■■■■■┃ 30400h ← KERNEL 入口 (KernelEntryPointPhyAddr)
    ;    30000h ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    ;           ┋            ...             ┋
    ;           ┋                            ┋
    ;        0h ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ← cs, ds, es, fs, ss

_start:
    mov    esp, StackTop       ; 切换堆栈
    mov    dword [disp_pos], 0
    
    sgdt   [gdt_ptr] ; ┓
    call   cstart    ; ┣ 更换 GDT
    lgdt   [gdt_ptr] ; ┛

    lidt   [idt_ptr]

    jmp    SELECTOR_KERNEL_CS:csinit ; 这个跳转指令强制使用刚刚初始化的结构

csinit:
    sti
    hlt

%macro  hwint_master 1
    push   %1
    call   spurious_irq
    add    esp, 4
    hlt
%endmacro
%macro  hwint_slave 1
    push   %1
    call   spurious_irq
    add    esp, 4
    hlt
%endmacro
; 硬件中断
    ALIGN  16
    hwint00:            ; clock
        hwint_master  0
    ALIGN  16
    hwint01:            ; keyboard
        hwint_master  1
    ALIGN  16
    hwint02:            ; cascade!
        hwint_master  2
    ALIGN  16
    hwint03:            ; second serial
        hwint_master  3
    ALIGN  16
    hwint04:            ; first serial
        hwint_master  4
    ALIGN  16
    hwint05:            ; XT winchester
        hwint_master  5
    ALIGN  16
    hwint06:            ; floppy
        hwint_master  6
    ALIGN  16
    hwint07:            ; printer
        hwint_master  7
    ALIGN  16
    hwint08:            ; realtime clock
        hwint_slave   8
    ALIGN  16
    hwint09:            ; irq 2 redirected
        hwint_slave   9
    ALIGN  16
    hwint10:            ; 
        hwint_slave  10
    ALIGN  16
    hwint11:            ; 
        hwint_slave  11
    ALIGN  16
    hwint12:            ; 
        hwint_slave  12
    ALIGN  16
    hwint13:            ; FPU exception
        hwint_slave  13
    ALIGN  16
    hwint14:            ; AT winchester
        hwint_slave  14
    ALIGN  16
    hwint15:            ; 
        hwint_slave  15

; 异常
    divide_error:
        push   0xFFFFFFFF
        push   0
        jmp    exception
    single_step_exception:
        push   0xFFFFFFFF
        push   1
        jmp    exception
    nmi:
        push   0xFFFFFFFF
        push   2
        jmp    exception
    breakpoint_exception:
        push   0xFFFFFFFF
        push   3
        jmp    exception
    overflow:
        push   0xFFFFFFFF
        push   4
        jmp    exception
    bounds_check:
        push   0xFFFFFFFF
        push   5
        jmp    exception
    inval_opcode:
        push   0xFFFFFFFF
        push   6
        jmp    exception
    copr_not_available:
        push   0xFFFFFFFF
        push   7
        jmp    exception
    double_fault:
        push   8
        jmp    exception
    copr_seg_overrun:
        push   0xFFFFFFFF
        push   9
        jmp    exception
    inval_tss:
        push   10
        jmp    exception
    segment_not_present:
        push   11
        jmp    exception
    stack_exception:
        push   12
        jmp    exception
    general_protection:
        push   13
        jmp    exception
    page_fault:
        push   14
        jmp    exception
    copr_error:
        push   0xFFFFFFFF
        push   16
        jmp    exception

    exception:
        call   exception_handler
        add    esp, 4 * 2
        hlt
