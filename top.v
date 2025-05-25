`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Institution: Digital Innovation Laboratory  
// Engineering Group: Embedded Systems Team
// 
// Project Start: 2025/02/19 15:36:30
// Architecture: Scalable Processing Framework
// Module: top
// Platform: Reconfigurable Computing System
// Target Platform: Xilinx Programmable Logic
// CAD Environment: Vivado Synthesis Suite 2023.x
// Function: Top-level system orchestration linking computational core with storage and interface modules
// 
// Required Components: SCPU1, ROM_D, RAM_B, MIO_BUS, Multi_8CH32, SSeg7, SPIO, clk_div, Counter_x, Enter
// 
// Revision History:
// Rev 0.01 - Baseline Implementation
// Design Notes: Hierarchical architecture ensures optimal signal routing and timing closure
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
input clk,
input rstn,
input  [4:0]btn_i,
input [15:0]sw_i,
output [7:0]disp_an_o,
output [7:0]disp_seg_o,
output [15:0]led_o
    );

// User interface signal processing
wire [15:0] switch_debounced;
wire [4:0] button_debounced;

// Clock domain and frequency management
wire [31:0] divided_clock_array;
wire cpu_operating_clock;

// Program execution control paths
wire [31:0] instruction_memory_data;
wire [31:0] program_counter_value;

// CPU internal communication buses
wire memory_io_enable;
wire [31:0]address_output_bus;
wire [31:0]processor_data_out;
wire [2:0]data_memory_control;
wire memory_write_control;

// Data storage and retrieval infrastructure  
wire [31:0] memory_data_input;
wire [31:0] block_ram_data_out;
wire [31:0] dm_output_data;
wire [3:0] write_enable_signals;

// Peripheral and system bus architecture
wire [31:0]peripheral_input_data;
wire [31:0]cpu_bus_interface;
wire gpio_enable_port_e;
wire gpio_enable_port_f;
wire timer_write_control;
wire [31:0]memory_write_data;
wire [9:0]block_ram_address;

// Display subsystem control signals
wire [7:0]led_enable_signals;
wire [7:0]decimal_point_signals;
wire [31:0]numeric_display_value;
wire [15:0] led_controller_output;
wire [1:0] counter_selection;

// Timing and interrupt generation
wire interrupt_source_0;
wire interrupt_source_1;  
wire interrupt_source_2;

// User input interface processing - signal conditioning and debouncing
Enter U10_Enter(
    .SW(sw_i),
    .BTN(btn_i),
    .clk(clk),
    .SW_out(switch_debounced),
    .BTN_out(button_debounced)
);

// Frequency synthesis and clock distribution network
clk_div U8_clk_div(
        .clkdiv(divided_clock_array),
        .rst(~rstn),
        .SW2(switch_debounced[2]),
        .Clk_CPU(cpu_operating_clock),
        .clk(clk)
);

// Programmable timer and event counting subsystem
Counter_x U9_Counter_x(
    .counter_we(timer_write_control),
    .rst(~rstn),
    .counter_val(peripheral_input_data),
    .clk2(divided_clock_array[11]),
    .counter1_OUT(interrupt_source_1),
    .clk1(divided_clock_array[9]),
    .counter_ch(counter_selection),
    .counter0_OUT(interrupt_source_0),
    .clk0(divided_clock_array[6]),
    .counter2_OUT(interrupt_source_2),
    .clk(~cpu_operating_clock)
);

// Special purpose input/output controller
SPIO U7_SPIO(
        .counter_set(counter_selection),
        .clk(~cpu_operating_clock),
        .LED_out(led_controller_output),
        .led(led_o),
        .P_Data(peripheral_input_data),
        .rst(~rstn),
        .EN(gpio_enable_port_f)
 );

// Instruction memory interface - ROM access
ROM_D ROM_D(
    .spo(instruction_memory_data),
    .a(program_counter_value[11:2])
);

// High-performance block memory storage
RAM_B RAM_B(
    .douta(block_ram_data_out),
    .wea(write_enable_signals),
    .clka(~clk),
    .dina(dm_output_data),
    .addra(block_ram_address)
);

// Main processor core - computational engine
SCPU1 U1_SCPU1(
    .PC_out(program_counter_value),
    .reset(~rstn),
    .mem_w(memory_write_control),
    .CPU_MIO(memory_io_enable),
    .clk(cpu_operating_clock),
    .Data_out(processor_data_out),
    .inst_in(instruction_memory_data),
    .INT(interrupt_source_0),
    .DMType(data_memory_control),
    .Addr_out(address_output_bus),
    .MIO_ready(memory_io_enable),
    .Data_in(memory_data_input)
);

// Data memory access controller and interface
dm_controller U3_dm_controller(
    .Data_write_to_dm(dm_output_data),
    .wea_mem(write_enable_signals),
    .mem_w(memory_write_control),
    .Data_read_from_dm(cpu_bus_interface),
    .dm_ctrl(data_memory_control),
    .Data_read(memory_data_input),
    .Addr_in(address_output_bus),
    .Data_write(memory_write_data)
);

// Seven-segment display driver and formatter
SSeg7 U6_SSeg7(
    .seg_sout(disp_seg_o),
    .point(decimal_point_signals),
    .seg_an(disp_an_o),
    .clk(clk),
    .flash(divided_clock_array[10]),
    .SW0(switch_debounced[0]),
    .rst(~rstn),
    .LES(led_enable_signals),
    .Hexs(numeric_display_value)
);

// Multi-channel display data multiplexer
Multi_8CH32 U5_Multi_8CH32(
    .data7(program_counter_value),
    .LE_out(led_enable_signals),
    .data3(32'h0000),
    .point_out(decimal_point_signals),
    .data6(cpu_bus_interface),
    .LES(~64'h00000000),
    .data1({1'b0, 1'b0, program_counter_value[31:2]}),
    .Switch(switch_debounced[7:5]),
    .data4(address_output_bus),
    .EN(gpio_enable_port_e),
    .data0(peripheral_input_data),
    .clk(~cpu_operating_clock),
    .data5(processor_data_out),
    .point_in({divided_clock_array[31:0], divided_clock_array[31:0]}),
    .rst(~rstn),
    .Disp_num(numeric_display_value),
    .data2(instruction_memory_data)
);

// System bus controller and memory-mapped I/O arbiter
MIO_BUS U4_MIO_BUS(
    .ram_data_in(memory_write_data),
    .counter_we(timer_write_control),
    .led_out(led_controller_output),
    .GPIOf0000000_we(gpio_enable_port_f),
    .counter2_out(interrupt_source_2),
    .ram_addr(block_ram_address),
    .Peripheral_in(peripheral_input_data),
    .counter0_out(interrupt_source_0),
    .SW(switch_debounced),
    .mem_w(memory_write_control),
    .GPIOe0000000_we(gpio_enable_port_e),
    .rst(~rstn),
    .counter_out(32'h0000),
    .BTN(button_debounced),
    .clk(clk),
    .ram_data_out(block_ram_data_out[31:0]),
    .Cpu_data4bus(cpu_bus_interface),
    .counter1_out(interrupt_source_1),
    .addr_bus(address_output_bus),
    .Cpu_data2bus(processor_data_out)
);

endmodule