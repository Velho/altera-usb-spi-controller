# usb spi controller

## Description

Implements USB host on Altera DE2 development board.
Data from the USB is prepared and sent over the SPI interface
to any connecting SPI master device.

Project was designed for the Altera DE2 and built using the Quartus II 13.0 WebEdition
Nucleo-l432kc was used to test the SPI slave implementation on the Cyclone II -fpga.

This project currently implements operation only to receive/send
data from a keyboard device. https://wiki.osdev.org/USB_Human_Interface_Devices

If you have any feedback, please open up an issue.

## Build

Build scripts are found from the _build_ folder.

Requirements:

- Quartus II v13.0

`quartus_env.ps1`

- Set toolchain env variable for compilation

`quartus_compile.ps1`

- Compiles the projects using the env variable

## TODO

Implement the SPI controller separately using the GPIO for the data sent to
master. I want the buffer concept to be designed well because data from the USB
peripheral has quite a lot of data to be processed and then read by master SPI.

Idea is simple,

- Input 8 bit data using the toggle buttons
  - SW[7 downto 0]
- Use the push buttons to write the toggle button state to a buffer for master to read.


### USB

- Read and writing to the uC
    - 16bit & 32bit

Addressing the USB host device
| | | |
|--|--|--|
| | A0 | A1
| Data | 0 | 0
| Command | 1 | 0



Setting up the device

1. Configure the peripheral
    - Register to be set
        | | |
        |-|-|
        | _HcATLBufferSize_ | 1536 |
        | _HcINTLBufferSize_ | 1024 |
        | _HcISTLBufferSize_ | 512 |
1. Setting the Host controller to the operational state
1. Enabling the port on detecting a connection
1. Assigning an address to the connected device
1. Getting required descriptors
1. Settings configuration
1. Polling for keyboard data


## SPI


### SPI Interface

Implements spi slave interface for the spi master to make any requests.
Master will always start with the address and clock the byte in.

|||||
|---|---|---|---|
| Clock polarity | CPOL | 0 | Idle at low |
| Clock phase | CPHA | 0 | First bit valid before leading clock edge |

With full duplex the slave device could output the control register,
but for now this is not implemented.
SPI slave operates as `half-duplex`.

__SPI Command Byte__

| MOSI Bit| Signal | | |
|-|-|-|-|
|7| REG4 |
|6| REG3 |
|5| REG2 |
|4| REG1 |
|3| REG0 |
|2| 0 |
|1 | Direction| 1 Write | 0 Read|
|0| 0 |

Only reading from the SPI interface is currently supported.
Please see the notes how to extend the vhdl for more devices.

### Registers

List of registers available
| Name | Reg ||
|-|-|-|
| FIFO | 2 |
| CTRL | ? |

## USB

USB peripheral on the board is _ISP1362_. Please see docs for
more information (includes datasheet and programming manual).

1. Configure the peripheral
2. Setting the Host controller to the operational state
3. Enabling the port on detecting a connection
4. Assigning an address to the connected device
5. Getting required descriptors
6. Settings configuration
7. Polling for keyboard data
