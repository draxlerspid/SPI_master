module spi_master_tb();

    // Shared Inputs
    logic       clk;
    logic       rst_n;
    logic       start;
    logic [7:0] tx_data;
    logic       miso;

    // Mode 0 Outputs (CPOL = 0, CPHA = 0)
    logic [7:0] rx_data_m0;
    logic       sclk_m0, mosi_m0, ss_n_m0;

    // Mode 1 Outputs (CPOL = 0, CPHA = 1)
    logic [7:0] rx_data_m1;
    logic       sclk_m1, mosi_m1, ss_n_m1;

    // Mode 2 Outputs (CPOL = 1, CPHA = 0)
    logic [7:0] rx_data_m2;
    logic       sclk_m2, mosi_m2, ss_n_m2;

    // Mode 3 Outputs (CPOL = 1, CPHA = 1)
    logic [7:0] rx_data_m3;
    logic       sclk_m3, mosi_m3, ss_n_m3;

    // Instantiate Mode 0
    spi_master #(.DATA_WIDTH(8), .CPOL(0), .CPHA(0)) uut0 (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .rx_data(rx_data_m0), .busy(), .done(),
        .sclk(sclk_m0), .mosi(mosi_m0), .miso(miso), .ss_n(ss_n_m0)
    );

    // Instantiate Mode 1
    spi_master #(.DATA_WIDTH(8), .CPOL(0), .CPHA(1)) uut1 (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .rx_data(rx_data_m1), .busy(), .done(),
        .sclk(sclk_m1), .mosi(mosi_m1), .miso(miso), .ss_n(ss_n_m1)
    );

    // Instantiate Mode 2
    spi_master #(.DATA_WIDTH(8), .CPOL(1), .CPHA(0)) uut2 (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .rx_data(rx_data_m2), .busy(), .done(),
        .sclk(sclk_m2), .mosi(mosi_m2), .miso(miso), .ss_n(ss_n_m2)
    );

    // Instantiate Mode 3
    spi_master #(.DATA_WIDTH(8), .CPOL(1), .CPHA(1)) uut3 (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .rx_data(rx_data_m3), .busy(), .done(),
        .sclk(sclk_m3), .mosi(mosi_m3), .miso(miso), .ss_n(ss_n_m3)
    );

    // Generate clock (10ns period)
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize signals
        clk     = 0;
        rst_n   = 0;
        start   = 0;
        tx_data = 8'h00;
        miso    = 0;

        // 2. Release reset
        #20;
        rst_n = 1;
        #20;

        // 3. First Transfer: Send 0xA5 (1010_0101), hold MISO = 1
        tx_data = 8'hA5;
        miso    = 1'b1;
        start   = 1'b1;
        #10;
        start   = 1'b0;

        // Wait enough time for 8 bits to finish
        #1500;

        // 4. Second Transfer: Send 0x3C (0011_1100), toggle MISO mid-way
        tx_data = 8'h3C;
        miso    = 1'b0;
        start   = 1'b1;
        #10;
        start   = 1'b0;

        #600;
        miso    = 1'b1;
        #900;

        $finish;
    end

endmodule
