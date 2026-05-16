// wrapper with an AXI4-Lite control/status register window.
// Includes axi-lite regs and core_pipeline
//
// Register map, word offsets:
//   0x00 control    RW bit0: hold core in reset when 1
//   0x04 status     RO bit0: pass, bit1: fail
//   0x08 pc         RO current core PC
//   0x0c mem_addr   RO latest MEM-stage address
//   0x10 mem_wdata  RO latest MEM-stage write data
//   0x14 wb_data    RO latest WB data
//   0x18 scratch0   RW software scratch
//   0x1c scratch1   RW software scratch

module axi_lite_top (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [5:0]  s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [5:0]  s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    output logic        pass,
    output logic        fail,
    output logic [7:0]  debug_led
);
    localparam int REG_COUNT = 8;

    logic [REG_COUNT-1:0][31:0] ro_regs;
    logic [REG_COUNT-1:0][31:0] rw_regs;

    wire soft_reset = rw_regs[0][0];
    wire core_rst_n = rst_n && !soft_reset;

    core_pipeline u_core (
        .clk   (clk),
        .rst_n (core_rst_n)
    );

    (* mark_debug = "true" *) wire [31:0] pc;
    (* mark_debug = "true" *) wire [31:0] mem_addr;
    (* mark_debug = "true" *) wire [31:0] mem_write_data;
    (* mark_debug = "true" *) wire [31:0] wb_data;
    (* mark_debug = "true" *) wire        mem_write_enable;
    (* mark_debug = "true" *) logic       done_flag;

    assign pc               = u_core.pc;
    assign mem_addr         = u_core.ex_mem_alu_y;
    assign mem_write_data   = u_core.ex_mem_rs2_val;
    assign wb_data          = u_core.wb_data;
    assign mem_write_enable = |u_core.ex_mem_be;

    always_ff @(posedge clk) begin
        if (!core_rst_n) begin
            done_flag <= 1'b0;
        end else if (mem_write_enable && mem_addr == 32'h0 && mem_write_data == 32'd12) begin
            done_flag <= 1'b1;
        end
    end

    assign pass = done_flag;
    assign fail = 1'b0;

    always_comb begin
        ro_regs = '0;
        ro_regs[1] = {30'h0, fail, pass};
        ro_regs[2] = pc;
        ro_regs[3] = mem_addr;
        ro_regs[4] = mem_write_data;
        ro_regs[5] = wb_data;
    end

    axi_lite_regs #(
        .ADDR_WIDTH (6),
        .DATA_WIDTH (32),
        .REG_COUNT  (REG_COUNT)
    ) u_axi_regs (
        .aclk          (clk),       // use cpu clock for now 5.14
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
        .read_only_regs(ro_regs),
        .writable_regs (rw_regs)
    );

    assign debug_led = {
        pc[4],
        pc[3],
        pc[2],
        fail,
        pass,
        mem_write_data[2:0]
    };
endmodule
