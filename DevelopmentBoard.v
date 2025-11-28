`timescale 1ns / 1ns

module DevelopmentBoard(
    input  wire        clk,
    input  wire        reset,
    input  wire        B2,       
    input  wire        B3,      
    input  wire        B4,       
    input  wire        B5,
    
    output wire        h_sync,
    output wire        v_sync,
    output wire [15:0] rgb,
    
    output wire        led1,     
    output wire        led2,    
    output wire        led3,    
    output wire        led4, 
    output wire        led5     
);

    wire [2:0] state_leds;


    vga_state_machine state_machine_inst(
        .sys_clk      (clk),
        .sys_rst_n    (reset),
        .button_press (~B2),    
        .left_btn     (~B3),   
        .right_btn    (~B4),    
        .hsync        (h_sync),
        .vsync        (v_sync),
        .rgb          (rgb),
        .state_leds   (state_leds)
    );

  
    assign led1 = 1'b1;                   
    assign led2 = ~B2;                    
    assign led3 = state_leds[0];          
    assign led4 = state_leds[1];          
    assign led5 = state_leds[2];          
endmodule
