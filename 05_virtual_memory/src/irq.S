.global enable_irq
enable_irq:
    msr daifclr, #2
    ret

.global disable_irq
disable_irq:
    msr daifset, #2
    ret
