#include "arm/sysregs.h"
#include "entry.h"
#include "timer.h"

.macro handle_invalid_entry el, type
    kernel_entry \el 
    mov x0, #\type
    mrs x1, esr_el1
    mrs x2, elr_el1
    bl  show_invalid_entry_message
    b   _loop
.endm

.macro  ventry label
.align  7
    b       \label
.endm

.macro  kernel_entry, el
    sub sp, sp, #S_FRAME_SIZE
    stp x0, x1, [sp, #16 * 0]
    stp x2, x3, [sp, #16 * 1]
    stp x4, x5, [sp, #16 * 2]
    stp x6, x7, [sp, #16 * 3]
    stp x8, x9, [sp, #16 * 4]
    stp x10, x11, [sp, #16 * 5]
    stp x12, x13, [sp, #16 * 6]
    stp x14, x15, [sp, #16 * 7]
    stp x16, x17, [sp, #16 * 8]
    stp x18, x19, [sp, #16 * 9]
    stp x20, x21, [sp, #16 * 10] 
    stp x22, x23, [sp, #16 * 11] 
    stp x24, x25, [sp, #16 * 12] 
    stp x26, x27, [sp, #16 * 13] 
    stp x28, x29, [sp, #16 * 14] 

    // TODO: understand here
    .if \el == 0
        mrs x21, sp_el0
    .else
        add x21, sp, #S_FRAME_SIZE
    .endif /* \el == 0 */

    mrs x22, elr_el1
    mrs x23, spsr_el1

    stp x30, x21, [sp, #16 * 15]
    stp x22, x23, [sp, #16 * 16]
.endm

.macro  kernel_exit, el
    ldp x22, x23, [sp, #16 * 16]
    ldp x30, x21, [sp, #16 * 15]

    // TODO: Understand here
    .if \el == 0
    msr sp_el0, x21
    .endif /* \el == 0 */

    msr elr_el1, x22
    msr spsr_el1, x23

    ldp x0, x1, [sp, #16 * 0]
    ldp x2, x3, [sp, #16 * 1]
    ldp x4, x5, [sp, #16 * 2]
    ldp x6, x7, [sp, #16 * 3]
    ldp x8, x9, [sp, #16 * 4]
    ldp x10, x11, [sp, #16 * 5]
    ldp x12, x13, [sp, #16 * 6]
    ldp x14, x15, [sp, #16 * 7]
    ldp x16, x17, [sp, #16 * 8]
    ldp x18, x19, [sp, #16 * 9]
    ldp x20, x21, [sp, #16 * 10]
    ldp x22, x23, [sp, #16 * 11]
    ldp x24, x25, [sp, #16 * 12]
    ldp x26, x27, [sp, #16 * 13]
    ldp x28, x29, [sp, #16 * 14]
    add sp, sp, #S_FRAME_SIZE
    eret
.endm

.global el1_vector_init
el1_vector_init:
    adr x0, el1_vector // Get the address of vector table
    msr vbar_el1, x0
    ret 

/* Exception vectors */
.align  11
.global el1_vector
el1_vector:
    ventry  sync_invalid_el1t           // Synchronous EL1t
    ventry  irq_invalid_el1t            // IRQ EL1t
    ventry  fiq_invalid_el1t            // FIQ EL1t
    ventry  error_invalid_el1t          // Error EL1t

    ventry  sync_invalid_el1h           // Synchronous EL1h
    ventry  el1_irq                     // IRQ EL1h
    ventry  fiq_invalid_el1h            // FIQ EL1h
    ventry  error_invalid_el1h          // Error EL1h

    ventry  el0_sync                    // Synchronous 64-bit EL0
    ventry  el0_irq                     // IRQ 64-bit EL0
    ventry  fiq_invalid_el0_64          // FIQ 64-bit EL0
    ventry  error_invalid_el0_64        // Error 64-bit EL0

    ventry  sync_invalid_el0_32         // Synchronous 32-bit EL0
    ventry  irq_invalid_el0_32          // IRQ 32-bit EL0
    ventry  fiq_invalid_el0_32          // FIQ 32-bit EL0
    ventry  error_invalid_el0_32        // Error 32-bit EL0

/* invalid handler */
sync_invalid_el1t:
    handle_invalid_entry  1, SYNC_INVALID_EL1t

irq_invalid_el1t:
    handle_invalid_entry  1, IRQ_INVALID_EL1t

fiq_invalid_el1t:
    handle_invalid_entry  1, FIQ_INVALID_EL1t

error_invalid_el1t:
    handle_invalid_entry  1, ERROR_INVALID_EL1t


sync_invalid_el1h:
    handle_invalid_entry  1, SYNC_INVALID_EL1h

irq_invalid_el1h:
    handle_invalid_entry  1, IRQ_INVALID_EL1h

fiq_invalid_el1h:
    handle_invalid_entry  1, FIQ_INVALID_EL1h

error_invalid_el1h:
    handle_invalid_entry  1, ERROR_INVALID_EL1h


sync_invalid_el0_64:
    handle_invalid_entry  0, SYNC_INVALID_EL0_64

irq_invalid_el0_64:
    handle_invalid_entry  0, IRQ_INVALID_EL0_64

fiq_invalid_el0_64:
    handle_invalid_entry  0, FIQ_INVALID_EL0_64

error_invalid_el0_64:
    handle_invalid_entry  0, ERROR_INVALID_EL0_64


sync_invalid_el0_32:
    handle_invalid_entry  0, SYNC_INVALID_EL0_32

irq_invalid_el0_32:
    handle_invalid_entry  0, IRQ_INVALID_EL0_32

fiq_invalid_el0_32:
    handle_invalid_entry  0, FIQ_INVALID_EL0_32

error_invalid_el0_32:
    handle_invalid_entry  0, ERROR_INVALID_EL0_32


/* handle defined exception */
el0_sync:
    kernel_entry 0
    mrs x25, esr_el1
    lsr x24, x25, #ESR_ELx_EC_SHIFT
    cmp x24, #ESR_ELx_EC_SVC64
    b.eq el0_svc
    handle_invalid_entry 0, SYNC_ERROR

el0_svc:
    bl handle_el0_sync
    bl ret_from_syscall
    kernel_exit 0

ret_from_syscall:
    str x0, [sp, #0]
    ret

el0_irq:
    kernel_entry 0
    bl handle_irq
    kernel_exit 0

sync_el1h:
    kernel_entry 1
    // TODO: Understand here
    mrs x0, esr_el1
    mrs x1, elr_el1
    bl handle_el1_sync
    kernel_exit 1

el1_irq:
    kernel_entry 1
    bl handle_irq
    kernel_exit 1

.global ret_from_fork
ret_from_fork:
    bl  schedule_tail
    cbz x19, ret_to_user
    blr x19                 // return when kernel threads end
ret_to_user:                // then go to user mode
    bl disable_irq          // TODO: why disable_irq
    kernel_exit 0

_loop:
    b _loop
