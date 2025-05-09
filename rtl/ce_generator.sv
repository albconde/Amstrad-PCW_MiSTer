module ce_generator(
    input wire clk,
    input wire reset,
    input wire [1:0] overclock,
    output logic cpu_ce_p,
    output logic cpu_ce_n,
    output logic sdram_clk_ref,
    output logic ce_16mhz,
    output logic ce_4mhz,
    output logic ce_1mhz,
    output logic clk_2mhz    
);	 
    reg [5:0] counter;
    reg [2:0] div_factor;

    always @(posedge clk or posedge reset) begin
        if (reset) counter <= 'b0;
        else counter <= counter + 1'b1;
    end

    always @(*) begin
        case (overclock)
            2'b00: div_factor = 3'd3; // 4 MHz
            2'b01: div_factor = 3'd2; // 8 MHz
            2'b10: div_factor = 3'd1; // 16 MHz
            2'b11: div_factor = 3'd0; // 32 MHz
            default: div_factor = 3'd3; // Default to 4 MHz
        endcase
    end
    reg cpu_4mhz_n;
    // Generar las señales de habilitación del reloj
    assign ce_4mhz =  ~counter[3] & ~counter[2] & ~counter[1] & ~counter[0]; // 4MHz positive CE
    assign cpu_4mhz_n =  counter[3] & ~counter[2] & ~counter[1] & ~counter[0]; // 4MHz negative CE
    assign cpu_ce_p = counter[div_factor] == 1'b0; // CE positivo
    assign cpu_ce_n = counter[div_factor] == 1'b1; // CE negativo
    assign ce_1mhz  = ~|counter;                    // 1MHz
    assign ce_16mhz = ~counter[1] & ~counter[0];    // 16MHz

    
	assign sdram_clk_ref = cpu_ce_p;
    
    // Generate 2MHz clock - toggle on every other 4MHz enable pulse
    reg clk_2mhz_reg;                // Renamed from clk_4mhz_reg
    reg toggle_control;              // Divider control
    
    // Create 2 MHz signal (half of 4 MHz)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            toggle_control <= 1'b0;
            clk_2mhz_reg <= 1'b0;
        end
        else if (ce_4mhz || cpu_4mhz_n) begin
            toggle_control <= ~toggle_control;
            if (toggle_control)      // Only toggle clk_2mhz on every other cpu_ce
                clk_2mhz_reg <= ~clk_2mhz_reg;
        end
    end
    
    assign clk_2mhz = clk_2mhz_reg;  
endmodule