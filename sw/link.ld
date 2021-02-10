OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0xC0000000;
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
}
