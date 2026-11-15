module spi_master #(
    parameter int DATA_WIDTH = 8,
    parameter int CPOL       = 0, // Clock Polarity (0: idle low, 1: idle high)
    parameter int CPHA       = 0  // Clock Phase    (0: sample on leading, 1: sample on trailing)
)(
    input  logic                   clk,       
    input  logic                   rst_n,     
    input  logic                   start,     
    input  logic [DATA_WIDTH-1:0]  tx_data,   
    output logic [DATA_WIDTH-1:0]  rx_data,   
    output logic                   busy,      
    output logic                   done,      
    

    output logic                   sclk,      
    output logic                   mosi,      
    input  logic                   miso,      
    output logic                   ss_n       
);

    
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        LOAD  = 2'b01,
        SHIFT = 2'b10,
        DONE  = 2'b11
    } state_t;

    state_t state, next_state;


    logic [DATA_WIDTH-1:0]         shift_reg_tx;
    logic [DATA_WIDTH-1:0]         shift_reg_rx;
    logic [$clog2(DATA_WIDTH)-1:0] bit_cnt;
    
    // Baud rate generator
    logic [3:0]                    clk_div;
    logic                          tick_lead; // Leading edge tick  (clk_div == 7)
    logic                          tick_full; // Trailing edge tick (clk_div == 15)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div <= '0;
        else if (state == SHIFT)
            clk_div <= clk_div + 1'b1;
        else
            clk_div <= '0; 
    end
    
    assign tick_lead = (clk_div == 4'd7);
    assign tick_full = (clk_div == 4'd15);

    // SCLK generation based on CPOL
    always_comb begin
        if (state == SHIFT) begin
            sclk = CPOL ? ~clk_div[3] : clk_div[3];
        end else begin
            sclk = CPOL; // Idle state matches CPOL
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            shift_reg_tx <= '0;
            shift_reg_rx <= '0;
            bit_cnt      <= '0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (start) begin
                        shift_reg_tx <= tx_data;
                        bit_cnt      <= DATA_WIDTH - 1;
                    end
                end

                LOAD: begin
                    shift_reg_rx <= '0;
                end

                SHIFT: begin
                    if (CPHA == 0) begin
                        // Mode 0 & 2: Sample MISO & shift next MOSI on trailing edge
                        if (tick_full) begin
                            shift_reg_rx <= {shift_reg_rx[DATA_WIDTH-2:0], miso};
                            shift_reg_tx <= {shift_reg_tx[DATA_WIDTH-2:0], 1'b0};
                        end
                    end else begin
                        // Mode 1 & 3: Launch next MOSI on leading edge (after first bit)
                        if (tick_lead && (bit_cnt != DATA_WIDTH - 1)) begin
                            shift_reg_tx <= {shift_reg_tx[DATA_WIDTH-2:0], 1'b0};
                        end
                        // Sample MISO on trailing edge
                        if (tick_full) begin
                            shift_reg_rx <= {shift_reg_rx[DATA_WIDTH-2:0], miso};
                        end
                    end

                    // Decrement bit counter at the end of every full bit period
                    if (tick_full && (bit_cnt != 0)) begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                DONE: begin
                    // Single-cycle completion pulse
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:  if (start) next_state = LOAD;
            LOAD:  next_state = SHIFT;
            SHIFT: if (bit_cnt == 0 && tick_full) next_state = DONE;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    assign ss_n    = (state == IDLE);
    assign busy    = (state != IDLE);
    assign done    = (state == DONE);
    assign mosi    = shift_reg_tx[DATA_WIDTH-1];
    assign rx_data = shift_reg_rx;

endmodule
