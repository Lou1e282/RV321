ENTRY(_start)

SECTIONS
{
    . = 0x00000000;    # bram start entry

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        *(.bss*)
        *(COMMON)
    }

}

