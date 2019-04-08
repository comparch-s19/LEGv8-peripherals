# LEGv8 Peripherals

This is a collection of student submitted peripherals for the LEGv8 processor

To the extent practical each peripheral should be contained in one Verilog file and depend only on AddressDetect.v. If other files are required then create a folder in the repository for your peripheral.

Each peripheral should interface with the processor via all or some of the memory interface signals (plus clock and reset):
64-bit bi-directional databus 
32-bit address input
1-bit mem_read
1-bit mem_write
2-bit size (00 8bit, 01 16bit, 10 32bit, 11 64bit)
Note: peripheral must not drive the bus unless the address matches and mem_read is on

All Special Function Register (SFR) addresses should be able to be changed using defparam.

When committing your peripheral make sure to edit the README file to add the name, filename, and short description to the table below. Also add the documentation or a link to it in the Peripheral Documentation section below

| Peripheral Name | Verilog File | Description |
| -- | -- | -- |
| Peripheral A | peripheral_a.v | If you are the first student to add a peripheral then replace this row |
| Another Peripheral | another_one.v | If you are the second student to add a peripheral then replace this row |

# Peripheral Documentation

## Peripheral A ##
The first student to commit a peripheral should replace this with documentation for the pheripheral or a link to where documentation can be found.

## Another Peripheral ##
The second student to add a peripheral should replace this with documentation for the peripheral or a link to where documentation can be found.