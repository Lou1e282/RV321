// axi_lite_regs testbench

module axi_lite_regs_tb;
    localparam int ADDR_WIDTH = 6;
    localparam int DATA_WIDTH = 32;
    localparam int REG_COUNT  = 8;

    logic clk;
    logic rst_n;

    logic [ADDR_WIDTH-1:0]     s_axi_awaddr;
    logic                      s_axi_awvalid;
    logic                      s_axi_awready;
    logic [DATA_WIDTH-1:0]     s_axi_wdata;
    logic [(DATA_WIDTH/8)-1:0] s_axi_wstrb;
    logic                      s_axi_wvalid;
    logic                      s_axi_wready;
    logic [1:0]                s_axi_bresp;
    logic                      s_axi_bvalid;
    logic                      s_axi_bready;

    logic [ADDR_WIDTH-1:0]     s_axi_araddr;
    logic                      s_axi_arvalid;
    logic                      s_axi_arready;
    logic [DATA_WIDTH-1:0]     s_axi_rdata;
    logic [1:0]                s_axi_rresp;
    logic                      s_axi_rvalid;
    logic                      s_axi_rready;

    logic [REG_COUNT-1:0][DATA_WIDTH-1:0] read_only_regs;
    logic [REG_COUNT-1:0][DATA_WIDTH-1:0] writable_regs;

    axi_lite_regs #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REG_COUNT (REG_COUNT)
    ) dut (
        .aclk          (clk),
        .aresetn       (rst_n),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .read_only_regs(read_only_regs),
        .writable_regs (writable_regs)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic axi_write(
        input logic [ADDR_WIDTH-1:0]     addr,
        input logic [DATA_WIDTH-1:0]     data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= strb;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;

            fork // concurrent
                begin
                    do @(posedge clk); while (!(s_axi_awvalid && s_axi_awready));
                    s_axi_awvalid <= 1'b0;
                    s_axi_awaddr  <= '0;
                end

                begin
                    do @(posedge clk); while (!(s_axi_wvalid && s_axi_wready));
                    s_axi_wvalid <= 1'b0;
                    s_axi_wdata  <= '0;
                    s_axi_wstrb  <= '0;
                end
            join

            do @(posedge clk); while (!(s_axi_bvalid && s_axi_bready));
            s_axi_bready <= 1'b0;

            assert (s_axi_bresp == 2'b00)
                else $fatal(1, "AXI write response error: addr=%0h bresp=%0b", addr, s_axi_bresp);
        end
    endtask

    task automatic axi_read(
        input logic [ADDR_WIDTH-1:0]     addr,
        output logic [DATA_WIDTH-1:0]    data
    );
        begin
            @(posedge clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;
            s_axi_rready  <= 1'b1;

            do @(posedge clk); while (!(s_axi_arvalid && s_axi_arready));
            s_axi_arvalid <= 1'b0;
            s_axi_araddr  <= '0;

            do @(posedge clk); while (!(s_axi_rvalid && s_axi_rready));
            data = s_axi_rdata;
            s_axi_rready <= 1'b0;

            assert (s_axi_rresp == 2'b00)
                else $fatal(1, "AXI read response error: addr=%0h rresp=%0b", addr, s_axi_rresp);
        end
    endtask

    task automatic assert_read_data(
        input string                    name,
        input logic [DATA_WIDTH-1:0]    got,
        input logic [DATA_WIDTH-1:0]    expected
    );
        begin
            assert (got === expected)
                else $fatal(1, "%s: got %08h expected %08h", name, got, expected);
            $display("[ OK ] %s = %08h", name, got);
        end
    endtask

    initial begin
        logic [31:0] read_data;

        rst_n = 1'b0;
        s_axi_awaddr  = '0;
        s_axi_awvalid = 1'b0;
        s_axi_wdata   = '0;
        s_axi_wstrb   = '0;
        s_axi_wvalid  = 1'b0;
        s_axi_bready  = 1'b0;
        s_axi_araddr  = '0;
        s_axi_arvalid = 1'b0;
        s_axi_rready  = 1'b0;
        read_only_regs = '0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        axi_write(6'h00, 32'h1234_5678, 4'b1111);
        axi_write(6'h18, 32'haabb_ccdd, 4'b1111);
        axi_write(6'h18, 32'h0000_00ee, 4'b0001);

        axi_read(6'h00, read_data);
        assert_read_data("read 0x00", read_data, 32'h1234_5678);

        axi_read(6'h18, read_data);
        assert_read_data("read 0x18 after byte write", read_data, 32'haabb_ccee);

        repeat (5) @(posedge clk);
        $finish;
    end
endmodule
