`default_nettype none
module servant
(
 input wire  wb_clk,
 input wire  wb_rst,
 //SPI init
 input wire  i_sck,
 input wire  i_copi,
 output wire o_cipo,
 input wire  i_cs,
 //SPI end
 output wire q);

   parameter memfile = "zephyr_hello.hex";
   parameter memsize = 8192;
   parameter reset_strategy = "MINI";
   parameter sim = 0;
   parameter with_csr = 1;

   wire 	timer_irq;

   wire [31:0] 	wb_ibus_adr;
   wire 	wb_ibus_cyc;
   wire [31:0] 	wb_ibus_rdt;
   wire 	wb_ibus_ack;

   wire [31:0] 	wb_dbus_adr;
   wire [31:0] 	wb_dbus_dat;
   wire [3:0] 	wb_dbus_sel;
   wire 	wb_dbus_we;
   wire 	wb_dbus_cyc;
   wire [31:0] 	wb_dbus_rdt;
   wire 	wb_dbus_ack;

   wire [31:0] 	wb_dmem_adr;
   wire [31:0] 	wb_dmem_dat;
   wire [3:0] 	wb_dmem_sel;
   wire 	wb_dmem_we;
   wire 	wb_dmem_cyc;
   wire [31:0] 	wb_dmem_rdt;
   wire 	wb_dmem_ack;
//SPI init
   wire [31:0] 	wb_spi_adr;
   wire [31:0] 	wb_spi_dat;
   wire [3:0] 	wb_spi_sel;
   wire 	wb_spi_we;
   wire 	wb_spi_cyc;
   wire [31:0] 	wb_spi_rdt;
   wire 	wb_spi_ack;
   
   wire cpu_reset;
   wire system_reset;
   
   wire i_rst_cpu;
   wire i_rst_system;
     
   wire         [71:0] spi_out;
   wire         [39:0] spi_in;
   
   wire  i_nrst;
   
   assign i_nrst = ~wb_rst;
//SPI end

   wire [31:0] 	wb_mem_adr;
   wire [31:0] 	wb_mem_dat;
   wire [3:0] 	wb_mem_sel;
   wire 	wb_mem_we;
   wire 	wb_mem_cyc;
   wire [31:0] 	wb_mem_rdt;
   wire 	wb_mem_ack;

   wire 	wb_gpio_dat;
   wire 	wb_gpio_we;
   wire 	wb_gpio_cyc;
   wire 	wb_gpio_rdt;

   wire [31:0] 	wb_timer_dat;
   wire 	wb_timer_we;
   wire 	wb_timer_cyc;
   wire [31:0] 	wb_timer_rdt;
   
   assign i_rst_system = system_reset || wb_rst;
   assign i_rst_cpu = cpu_reset || i_rst_system;

   spi #(.outputs(9), .inputs(5)) spi_1( //max 255
    .i_sck(i_sck),
    .i_copi(i_copi),
    .o_cipo(o_cipo),
    .i_cs(i_cs),
    .i_nrst(i_nrst),
    .rout(spi_out),
    .rin(spi_in)
    );

// SPI init
   spi_slave spi_slave
     (.clk(wb_clk),
      .i_wb_cpu_spi_adr (wb_spi_adr),
      .i_wb_cpu_spi_dat (wb_spi_dat),
      .i_wb_cpu_spi_sel (wb_spi_sel),
      .i_wb_cpu_spi_we  (wb_spi_we ),
      .i_wb_cpu_spi_cyc (wb_spi_cyc),
      .o_wb_cpu_spi_rdt (wb_spi_rdt),
      .o_wb_cpu_spi_ack (wb_spi_ack),
      .cpu_reset        (cpu_reset),
      .spi_reset	(i_nrst),//i_nrst
      .system_reset(system_reset),
      .spi_out(spi_out),
      .spi_in(spi_in));
//SPI end

   servant_arbiter arbiter
     (.i_wb_cpu_dbus_adr (wb_dmem_adr),
      .i_wb_cpu_dbus_dat (wb_dmem_dat),
      .i_wb_cpu_dbus_sel (wb_dmem_sel),
      .i_wb_cpu_dbus_we  (wb_dmem_we ),
      .i_wb_cpu_dbus_cyc (wb_dmem_cyc),
      .o_wb_cpu_dbus_rdt (wb_dmem_rdt),
      .o_wb_cpu_dbus_ack (wb_dmem_ack),
// SPI init
      .i_wb_cpu_spi_adr (wb_spi_adr),
      .i_wb_cpu_spi_dat (wb_spi_dat),
      .i_wb_cpu_spi_sel (wb_spi_sel),
      .i_wb_cpu_spi_we  (wb_spi_we ),
      .i_wb_cpu_spi_cyc (wb_spi_cyc),
      .o_wb_cpu_spi_rdt (wb_spi_rdt),
      .o_wb_cpu_spi_ack (wb_spi_ack),
//SPI end

      .i_wb_cpu_ibus_adr (wb_ibus_adr),
      .i_wb_cpu_ibus_cyc (wb_ibus_cyc),
      .o_wb_cpu_ibus_rdt (wb_ibus_rdt),
      .o_wb_cpu_ibus_ack (wb_ibus_ack),

      .o_wb_cpu_adr (wb_mem_adr),
      .o_wb_cpu_dat (wb_mem_dat),
      .o_wb_cpu_sel (wb_mem_sel),
      .o_wb_cpu_we  (wb_mem_we ),
      .o_wb_cpu_cyc (wb_mem_cyc),
      .i_wb_cpu_rdt (wb_mem_rdt),
      .i_wb_cpu_ack (wb_mem_ack));

   servant_mux #(sim) servant_mux
     (
      .i_clk (wb_clk),
      .i_rst (i_rst_system & (reset_strategy != "NONE")),
      .i_wb_cpu_adr (wb_dbus_adr),
      .i_wb_cpu_dat (wb_dbus_dat),
      .i_wb_cpu_sel (wb_dbus_sel),
      .i_wb_cpu_we  (wb_dbus_we),
      .i_wb_cpu_cyc (wb_dbus_cyc),
      .o_wb_cpu_rdt (wb_dbus_rdt),
      .o_wb_cpu_ack (wb_dbus_ack),

      .o_wb_mem_adr (wb_dmem_adr),
      .o_wb_mem_dat (wb_dmem_dat),
      .o_wb_mem_sel (wb_dmem_sel),
      .o_wb_mem_we  (wb_dmem_we),
      .o_wb_mem_cyc (wb_dmem_cyc),
      .i_wb_mem_rdt (wb_dmem_rdt),

      .o_wb_gpio_dat (wb_gpio_dat),
      .o_wb_gpio_we  (wb_gpio_we),
      .o_wb_gpio_cyc (wb_gpio_cyc),
      .i_wb_gpio_rdt (wb_gpio_rdt),

      .o_wb_timer_dat (wb_timer_dat),
      .o_wb_timer_we  (wb_timer_we),
      .o_wb_timer_cyc (wb_timer_cyc),
      .i_wb_timer_rdt (wb_timer_rdt));

   servant_ram
     #(.memfile (memfile),
       .depth (memsize),
       .RESET_STRATEGY (reset_strategy))
   ram
     (// Wishbone interface
      .i_wb_clk (wb_clk),
      .i_wb_rst (i_rst_system),
      .i_wb_adr (wb_mem_adr[$clog2(memsize)-1:2]),
      .i_wb_cyc (wb_mem_cyc),
      .i_wb_we  (wb_mem_we) ,
      .i_wb_sel (wb_mem_sel),
      .i_wb_dat (wb_mem_dat),
      .o_wb_rdt (wb_mem_rdt),
      .o_wb_ack (wb_mem_ack));

   generate
      if (with_csr) begin
	 servant_timer
	   #(.RESET_STRATEGY (reset_strategy),
	     .WIDTH (32))
	 timer
	   (.i_clk    (wb_clk),
	    .i_rst    (i_rst_system),
	    .o_irq    (timer_irq),
	    .i_wb_cyc (wb_timer_cyc),
	    .i_wb_we  (wb_timer_we) ,
	    .i_wb_dat (wb_timer_dat),
	    .o_wb_dat (wb_timer_rdt));
      end else begin
	 assign wb_timer_rdt = 32'd0;
	 assign timer_irq = 1'b0;
      end
   endgenerate

   servant_gpio gpio
     (.i_wb_clk (wb_clk),
      .i_wb_dat (wb_gpio_dat),
      .i_wb_we  (wb_gpio_we),
      .i_wb_cyc (wb_gpio_cyc),
      .o_wb_rdt (wb_gpio_rdt),
      .o_gpio   (q));

   serv_rf_top
     #(.RESET_PC (32'h0000_0000),
       .RESET_STRATEGY (reset_strategy),
       .WITH_CSR (with_csr),
       .RF_WIDTH (8))
   cpu
     (
      .clk      (wb_clk),
      .i_rst    (i_rst_cpu),//SPI reset
      .i_timer_irq  (timer_irq),
`ifdef RISCV_FORMAL
      .rvfi_valid     (),
      .rvfi_order     (),
      .rvfi_insn      (),
      .rvfi_trap      (),
      .rvfi_halt      (),
      .rvfi_intr      (),
      .rvfi_mode      (),
      .rvfi_ixl       (),
      .rvfi_rs1_addr  (),
      .rvfi_rs2_addr  (),
      .rvfi_rs1_rdata (),
      .rvfi_rs2_rdata (),
      .rvfi_rd_addr   (),
      .rvfi_rd_wdata  (),
      .rvfi_pc_rdata  (),
      .rvfi_pc_wdata  (),
      .rvfi_mem_addr  (),
      .rvfi_mem_rmask (),
      .rvfi_mem_wmask (),
      .rvfi_mem_rdata (),
      .rvfi_mem_wdata (),
`endif

      .o_ibus_adr   (wb_ibus_adr),
      .o_ibus_cyc   (wb_ibus_cyc),
      .i_ibus_rdt   (wb_ibus_rdt),
      .i_ibus_ack   (wb_ibus_ack),

      .o_dbus_adr   (wb_dbus_adr),
      .o_dbus_dat   (wb_dbus_dat),
      .o_dbus_sel   (wb_dbus_sel),
      .o_dbus_we    (wb_dbus_we),
      .o_dbus_cyc   (wb_dbus_cyc),
      .i_dbus_rdt   (wb_dbus_rdt),
      .i_dbus_ack   (wb_dbus_ack));

endmodule
