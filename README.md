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
| Timer/Counter0 | timer_counter0.v | A 64-bit timer/counter peripheral with 4 operation modes and 2 PWM outputs  |
| 16-bit TimerA | Timer_TS.v | A 16-bit timer with period and configure registers |
| Matrix_Peripheral0 | matrix_peripheral.v | 16-bit registers to control what is displayed on the matrix |
| Another Peripheral | another_one.v | If you are the third student to add a peripheral then replace this row |

# Peripheral Documentation

## Timer/Counter0 ##
Written by Andrew Hollabaugh

A 64-bit timer/counter peripheral with 4 operation modes and 2 PWM outputs. It is based on the Timer/Counter0 perhipheral from the ATMEGA48/88/168/328 processor. Its four modes are: normal, clear on timer compare (CTC), PWM (TOP=MAX) and PWM (TOP=compare register A). A prescaler can be selected ranging from 8 to 1024. Output compares can also be forced for fine control. For more info, read the documentation [here.](https://docs.google.com/document/d/1DbuxtQeK8CZknk03VDcP6ilvkV-3jNcxF68iJGg44-w/edit?usp=sharing)

## 16-bit TimerA ##
Written by Thomas Schofield

TimerA is a 16-bit timer peripheral with a counter, configure, and period register. When instantiating the timer, use "defparam" to define a base addresss. The counter can be accessed directly at the base address. The configure and period registers are offset by 8 and 16 respectively. Example addresses are also provided in the file's comments. For more information about the configure and period registers, please visit the [documentation](https://docs.google.com/document/d/1194CkKZIows6x4uw8eE9A71nns8_jBOXP3iYx2TQ9FE/edit?usp=sharing).

## Matrix_Peripheral0 ##
Written by Richard Dell

Matrix_Peripheral0 is a collection of 8 16-bit registers that will display their values on the DE0 extension board's matrix. Each register can be given its own address and can only be written to when that specific address is called. The registers will output to the GPIO_Board module to convert the value into a signal that can be displayed on the matrix. For more information, see the [documentation](https://docs.google.com/document/d/1Q0sn7gO6WcJYBJXdXe38DZ1Wy6tpFMuzw1jIvvxrgDk/edit?usp=sharing). 

## Another Peripheral ##
The third student to add a peripheral should replace this with documentation for the peripheral or a link to where documentation can be found.
