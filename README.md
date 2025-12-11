# FPGA-Based Digital Magic Screen Implementation

**Platform:** Terasic DE10-Nano (Cyclone V SoC)
**Language:** VHDL (IEEE 1076)
**Development Environment:** Intel Quartus Prime Lite Edition 24.1

## 1. Project Abstract

This repository hosts the source code for a digital implementation of a "Magic Screen" (mechanical drawing toy), developed on an FPGA architecture. The system interfaces with mechanical rotary encoders to control X/Y coordinate generation and utilizes a VGA/HDMI controller to render the output to an external monitor. A central aspect of the design is the implementation of a video frame buffer using Dual-Port RAM to achieve persistent storage of the drawing path.

## 2. Hardware Specifications

* **Target Device:** Cyclone V SE (`5CSEBA6U23I7`) on Terasic DE10-Nano board.
* **Input Interface:** Custom Mezzanine board equipped with two quadrature rotary encoders (integrated push-buttons).
* **Output Interface:** HDMI Monitor (driven via FPGA GPIOs).
* **Clock Source:** 50 MHz on-board oscillator.

## 3. Technical Architecture

The design is modularized into several distinct logical blocks, synthesized using VHDL:

### 3.1. Input Signal Processing (Encoders)
The `encoder_manager` entity handles the quadrature decoding of signals A and B.
* **Debouncing & Synchronization:** Input signals are synchronized to the system clock to prevent metastability.
* **Edge Detection:** The logic identifies rising and falling edges on channel A relative to channel B to determine the direction of rotation.
* **Coordinate Management:** Two up/down counters maintain the current X (horizontal) and Y (vertical) pixel coordinates.

### 3.2. HDMI Controller
The video output generation is handled by the `hdmi_controler` entity.
* **Timing Generation:** Produces strict HSYNC, VSYNC, and Data Enable signals compliant with 640x480 resolution standards.
* **Clocking:** Utilizes a Phase-Locked Loop (PLL) to derive the required pixel clock frequency from the system's 50 MHz base clock.

### 3.3. Memory & Frame Buffer
To support image persistence, the system utilizes a **Dual-Port RAM** architecture (`dpram.vhd`).
* **Port A (Write Operation):** Dedicated to the drawing logic. When the encoders move, the system writes a "White" value (0xFFFFFF) to the memory address corresponding to the current (X, Y) coordinates.
* **Port B (Read Operation):** Dedicated to the HDMI controller. During the raster scan, the controller reads the pixel data from memory to drive the display output.

### 3.4. Screen Clearing Mechanism
A Finite State Machine (FSM) is implemented to handle the screen reset function. Upon activation of the encoder push-button:
1.  Normal read/write operations are suspended.
2.  The FSM iterates through the entire memory address space.
3.  A "Black" value (0x000000) is written to every pixel address to clear the canvas.

## 4. Implementation Instructions

### 4.1. Prerequisites
* Intel Quartus Prime Lite (v24.1 or compatible).
* USB-Blaster drivers configured (For Linux: ensure `/etc/udev/rules.d/51-usbblaster.rules` is present).

### 4.2. Synthesis and Bitstream Generation
1.  **Project Setup:** Open the `.qpf` project file in Quartus Prime.
2.  **Device Verification:** Confirm the target device is set to `5CSEBA6U23I7`.
3.  **Pin Planning:** Verify that I/O assignments match the DE10-Nano schematics (HDMI TX pins and GPIOs for encoders).
4.  **Compilation:** Execute the "Compile Design" process to generate the `.sof` file.

### 4.3. Hardware Programming
1.  Connect the DE10-Nano board via the USB Blaster II interface.
2.  Open the **Programmer** tool within Quartus.
3.  Select "Auto Detect" followed by the `5CSEBA6` device.
4.  Load the generated `.sof` bitstream.
5.  Execute the programming sequence.

## 5. Directory Structure

* `/src`: Contains all VHDL source files (`top_level.vhd`, `hdmi_controler.vhd`, `dpram.vhd`, etc.).
* `/output_files`: Contains the synthesized bitstream and synthesis reports.
* `/simulation`: Testbenches and ModelSim simulation scripts.

---
## 6. Demonstration video 
* link :https://youtube.com/shorts/WZ2j1-vuMrI?feature=share
**Author:** Agheles Mekdache
**Course:** FPGA Laboratory
