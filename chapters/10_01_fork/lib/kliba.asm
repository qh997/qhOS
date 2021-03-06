
%include "sys/sconst.inc"

extern  disp_pos

[SECTION .text]
global  disp_str
global  disp_color_str
global  out_byte
global  in_byte
global  disable_irq
global  enable_irq
global  disable_int
global  enable_int
global  port_read
global  port_write

disp_str:
    push   ebp
    mov    ebp, esp

    mov    esi, [ebp + 8]
    mov    edi, [disp_pos]
    mov    ah, 0Fh
    .1:
        lodsb
        test   al, al
        jz     .2
        cmp    al, 0Ah
        jnz    .3
        push    eax
        mov    eax, edi
        mov    bl, 160
        div    bl
        and    eax, 0FFh
        inc    eax
        mov    bl, 160
        mul    bl
        mov    edi, eax
        pop    eax
        jmp    .1
    .3:
        mov    [gs:edi], ax
        add    edi, 2
        jmp    .1

    .2:
        mov    [disp_pos], edi

    pop    ebp
    ret

disp_color_str:
    push   ebp
    mov    ebp, esp

    mov    esi, [ebp + 8]
    mov    edi, [disp_pos]
    mov    ah, [ebp + 12]
    .1:
        lodsb
        test   al, al
        jz     .2
        cmp    al, 0Ah
        jnz    .3
        push    eax
        mov    eax, edi
        mov    bl, 160
        div    bl
        and    eax, 0FFh
        inc    eax
        mov    bl, 160
        mul    bl
        mov    edi, eax
        pop    eax
        jmp    .1
    .3:
        mov    [gs:edi], ax
        add    edi, 2
        jmp    .1

    .2:
        mov    [disp_pos], edi

    pop    ebp
    ret

;==========================================================
; PUBLIC void out_byte(u16 port, u8 value);
;==========================================================
out_byte:
    mov    edx, [esp + 4]
    mov    al, [esp + 8]
    out    dx, al
    nop
    nop
    ret

;==========================================================
; PUBLIC u8 in_byte(u16 port);
;==========================================================
in_byte:
    mov    edx, [esp + 4]
    xor    eax, eax
    in     al, dx
    nop
    nop
    ret

;==========================================================
; PUBLIC int disable_irq(int irq);
;==========================================================
disable_irq:
    mov    ecx, [esp + 4]        ; ecx = irq
    pushf                        ;
    cli                          ; 关中断，将在 iretd 时打开
    mov    ah, 1                 ;
    rol    ah, cl                ; ah = 1 << (irq % 8)
    cmp    cl, 8                 ;
    jae    disable_8             ; if (cl < 8) // 主 8259A
    disable_0:                   ; {
        in     al, INT_M_CTLMASK ;
        test   al, ah            ;     if (中断已经禁用)
        jnz    dis_already       ;         return 0
        or     al, ah            ;
        out    INT_M_CTLMASK, al ;     屏蔽该中断
        popf                     ;
        mov    eax, 1            ;     return 1
        ret                      ; }
    disable_8:                   ; else { // 从 8259A
        in     al, INT_S_CTLMASK ;
        test   al, ah            ;     if (中断已经禁用)
        jnz    dis_already       ;         return 0
        or     al, ah            ;
        out    INT_S_CTLMASK, al ;     屏蔽该中断
        popf                     ;
        mov    eax, 1            ;     return 1
        ret                      ; }
    dis_already:
        popf
        xor    eax, eax
        ret

;==========================================================
; PUBLIC void enable_irq(int irq);
;==========================================================
enable_irq:
    mov    ecx, [esp + 4]
    pushf
    cli
    mov    ah, ~1
    rol    ah, cl
    cmp    cl, 8
    jae    enable_8
    enable_0:
        in     al, INT_M_CTLMASK
        and    al, ah
        out    INT_M_CTLMASK, al
        popf
        ret
    enable_8:
        in     al, INT_S_CTLMASK
        and    al, ah
        out    INT_S_CTLMASK, al
        popf
        ret

;==========================================================
;PUBLIC void disable_int();
;==========================================================
disable_int:
    cli
    ret

;==========================================================
;PUBLIC void enable_int();
;==========================================================
enable_int:
    sti
    ret

;==========================================================
; PUBLIC void port_read(u16 port, void *buf, int n);
;==========================================================
port_read:
    mov    edx, [esp + 4]  ; port
    mov    edi, [esp + 8]  ; buf
    mov    ecx, [esp + 12] ; n
    shr    ecx, 1
    cld
    rep    insw
    ret

;==========================================================
; PUBLIC void port_write(u16 port, void *buf, int n);
;==========================================================
port_write:
    mov    edx, [esp + 4]  ; port
    mov    esi, [esp + 8]  ; buf
    mov    ecx, [esp + 12] ; n
    shr    ecx, 1
    cld
    rep    outsw
    ret
