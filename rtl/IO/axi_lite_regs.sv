// AXI4-Lite slave register bank.
//
// Single-clock, single-reset AXI-Lite peripheral with outstanding read and write response. Write update writable_regs with WSTRB byte lanes; read return writable_regs ORed with read_only_regs for wrapper to expose status/debug values bypassing software write access. 


module axi_lite_regs #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 32,
    parameter int REG_COUNT  = 8
) (
    input  logic                         aclk,
    input  logic                         aresetn,

    input  logic [ADDR_WIDTH-1:0]        s_axi_awaddr,
    input  logic                         s_axi_awvalid,
    output logic                         s_axi_awready,

    input  logic [DATA_WIDTH-1:0]        s_axi_wdata,
    input  logic [(DATA_WIDTH/8)-1:0]    s_axi_wstrb,
    input  logic                         s_axi_wvalid,
    output logic                         s_axi_wready,

    output logic [1:0]                   s_axi_bresp,
    output logic                         s_axi_bvalid,
    input  logic                         s_axi_bready,

    input  logic [ADDR_WIDTH-1:0]        s_axi_araddr,
    input  logic                         s_axi_arvalid,
    output logic                         s_axi_arready,

    output logic [DATA_WIDTH-1:0]        s_axi_rdata,
    output logic [1:0]                   s_axi_rresp,
    output logic                         s_axi_rvalid,
    input  logic                         s_axi_rready,

    input  logic [REG_COUNT-1:0][DATA_WIDTH-1:0] read_only_regs,
    output logic [REG_COUNT-1:0][DATA_WIDTH-1:0] writable_regs
);
    localparam int STRB_WIDTH = DATA_WIDTH / 8;
    localparam int ADDR_LSB   = $clog2(STRB_WIDTH);
    localparam int REG_BITS   = (REG_COUNT <= 1) ? 1 : $clog2(REG_COUNT);

    logic [ADDR_WIDTH-1:0] awaddr_q;
    logic                 aw_hold;
    logic [DATA_WIDTH-1:0] wdata_q;
    logic [STRB_WIDTH-1:0] wstrb_q;
    logic                  w_hold;

    wire write_fire = aw_hold && w_hold && !s_axi_bvalid;     // Handshake
    wire [REG_BITS-1:0] write_index = awaddr_q[ADDR_LSB +: REG_BITS];
    wire [REG_BITS-1:0] read_index  = s_axi_araddr[ADDR_LSB +: REG_BITS];
    wire write_in_range = (int'(write_index) < REG_COUNT);
    wire read_in_range  = (int'(read_index)  < REG_COUNT);

    assign s_axi_awready = !aw_hold && !s_axi_bvalid;
    assign s_axi_wready  = !w_hold  && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;

    assign s_axi_bresp = 2'b00; // OKAY
    assign s_axi_rresp = 2'b00; // OKAY


    // status change
    always_ff @(posedge aclk) begin
        if (!aresetn) begin // reset
            aw_hold <= 1'b0;
            w_hold  <= 1'b0;
            s_axi_bvalid <= 1'b0;
            for (int i = 0; i < REG_COUNT; i++) begin
                writable_regs[i] <= '0;
            end
        end 
        else begin 
            if (s_axi_awready && s_axi_awvalid) begin
                awaddr_q <= s_axi_awaddr;
                aw_hold  <= 1'b1;
            end

            if (s_axi_wready && s_axi_wvalid) begin
                wdata_q <= s_axi_wdata;
                wstrb_q <= s_axi_wstrb;
                w_hold  <= 1'b1;
            end

            if (write_fire) begin // write action
                if (write_in_range) begin
                    for (int b = 0; b < STRB_WIDTH; b++) begin // write strobe width
                        if (wstrb_q[b]) begin
                            writable_regs[write_index][8*b +: 8] <= wdata_q[8*b +: 8];
                        end
                    end
                end
                aw_hold <= 1'b0;
                w_hold  <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= '0;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                if (read_in_range) begin
                    s_axi_rdata <= writable_regs[read_index] | read_only_regs[read_index];
                end else begin
                    s_axi_rdata <= '0;
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule
