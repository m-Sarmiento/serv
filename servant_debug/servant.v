`default_nettype none
module servant
(
 input wire  wb_clk,
 input wire  wb_rst,
 output wire q,
 //jtag
 input logic trst_ni,
 input  logic tck_i,
 input  logic tms_i,
 input  logic td_i,
 output wire td_o,
 //jtag end 
 
 //SPI init
 input wire  i_sck,
 input wire  i_copi,
 output wire o_cipo,
 input wire  i_cs
 //SPI end 
 );

   parameter memfile = "zephyr_hello.hex";
   parameter memsize = 8192;
   parameter reset_strategy = "MINI";
   parameter sim = 0;
   parameter with_csr = 1;

   wire 	timer_irq;

	//ibus from cpu to arbiter
   wire [31:0] 	wb_ibus_adr;
   wire 	wb_ibus_cyc;

	// dbus from cpu to arbiter
   wire [31:0] 	wb_dbus_adr;
   wire [31:0] 	wb_dbus_dat;
   wire [3:0] 	wb_dbus_sel;
   wire 	wb_dbus_we;
   wire 	wb_dbus_cyc;
   
   
   //return data and ack from arbiter
   wire [31:0] wb_cpu_rdt; // new
   wire wb_cpu_dbus_ack; // new
   wire wb_cpu_ibus_ack; // new   
   
   //signal between mux and arbiter
   wire [31:0] 	wb_adr;
   wire [31:0] 	wb_dat;
   wire [3:0] 	wb_sel;
   wire 	wb_we;
   wire 	wb_cyc;
   wire [31:0] wb_rdt; 
   wire wb_dbus_ack; 
   wire wb_ibus_ack;

	// mux to mem
   wire [31:0] 	wb_mem_adr;
   wire [31:0] 	wb_mem_dat;
   wire [3:0] 	wb_mem_sel;
   wire 	wb_mem_we;
   wire 	wb_mem_cyc;
   wire [31:0] 	wb_mem_rdt;
   wire 	wb_mem_ack;


	// mux to gpio
   wire 	wb_gpio_dat;
   wire 	wb_gpio_we;
   wire 	wb_gpio_cyc;
   wire 	wb_gpio_rdt;

	//mux to timer 
   wire [31:0] 	wb_timer_dat;
   wire 	wb_timer_we;
   wire 	wb_timer_cyc;
   wire [31:0] 	wb_timer_rdt;
   
   	//debug_module
   wire [31:0] 	wb_debug_adr;
   wire [31:0] 	wb_debug_dat;
   wire [3:0] 	wb_debug_sel;
   wire 	wb_debug_we;
   wire 	wb_debug_cyc;
   wire [31:0] 	wb_debug_rdt;
   wire 	wb_debug_ack;
   

	wire debug_request;
	
	
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
   assign i_rst_system = system_reset || wb_rst;
   assign i_rst_cpu = cpu_reset || i_rst_system;
   
//SPI end
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
     (.i_wb_cpu_dbus_adr (wb_dbus_adr),
      .i_wb_cpu_dbus_dat (wb_dbus_dat),
      .i_wb_cpu_dbus_sel (wb_dbus_sel),
      .i_wb_cpu_dbus_we  (wb_dbus_we ),
      .i_wb_cpu_dbus_cyc (wb_dbus_cyc),
      .o_wb_cpu_rdt (wb_cpu_rdt),
      .o_wb_cpu_dbus_ack (wb_cpu_dbus_ack),

      .i_wb_cpu_ibus_adr (wb_ibus_adr),
      .i_wb_cpu_ibus_cyc (wb_ibus_cyc),
      // .o_wb_cpu_ibus_rdt (wb_ibus_rdt),
      .o_wb_cpu_ibus_ack (wb_cpu_ibus_ack),
	  
	// SPI init
      .i_wb_cpu_spi_adr (wb_spi_adr),
      .i_wb_cpu_spi_dat (wb_spi_dat),
      .i_wb_cpu_spi_sel (wb_spi_sel),
      .i_wb_cpu_spi_we  (wb_spi_we ),
      .i_wb_cpu_spi_cyc (wb_spi_cyc),
      .o_wb_cpu_spi_rdt (wb_spi_rdt),
      .o_wb_cpu_spi_ack (wb_spi_ack),
//SPI end

	//to mux 
      .o_wb_cpu_adr (wb_adr),
      .o_wb_cpu_dat (wb_dat),
      .o_wb_cpu_sel (wb_sel),
      .o_wb_cpu_we  (wb_we ),
      .o_wb_cpu_cyc (wb_cyc),
      .i_wb_cpu_rdt (wb_rdt),
      .i_wb_cpu_ibus_ack (wb_ibus_ack),
      .i_wb_cpu_dbus_ack (wb_dbus_ack)
	  );

   servant_mux #(sim) servant_mux
     (
      .i_clk (wb_clk),
      .i_rst (i_rst_system & (reset_strategy != "NONE")),
      .i_wb_cpu_adr (wb_adr),
      .i_wb_cpu_dat (wb_dat),
      .i_wb_cpu_sel (wb_sel),
      .i_wb_cpu_we  (wb_we),
      .i_wb_cpu_cyc (wb_cyc),
      .o_wb_cpu_rdt (wb_rdt),
      .o_wb_ibus_ack (wb_ibus_ack),
      .o_wb_dbus_ack (wb_dbus_ack),//new

      .o_wb_mem_adr (wb_mem_adr),
      .o_wb_mem_dat (wb_mem_dat),
      .o_wb_mem_sel (wb_mem_sel),
      .o_wb_mem_we  (wb_mem_we),
      .o_wb_mem_cyc (wb_mem_cyc),
      .i_wb_mem_rdt (wb_mem_rdt),
      .i_wb_mem_ack (wb_mem_ack),//new

      .o_wb_gpio_dat (wb_gpio_dat),
      .o_wb_gpio_we  (wb_gpio_we),
      .o_wb_gpio_cyc (wb_gpio_cyc),
      .i_wb_gpio_rdt (wb_gpio_rdt),

      .o_wb_timer_dat (wb_timer_dat),
      .o_wb_timer_we  (wb_timer_we),
      .o_wb_timer_cyc (wb_timer_cyc),
      .i_wb_timer_rdt (wb_timer_rdt),
	  
	  .o_wb_debug_adr (wb_debug_adr),
      .o_wb_debug_dat (wb_debug_dat),
      .o_wb_debug_sel (wb_debug_sel),
      .o_wb_debug_we  (wb_debug_we),
      .o_wb_debug_cyc (wb_debug_cyc),
      .i_wb_debug_rdt (wb_debug_rdt),
      .i_wb_debug_ack (wb_debug_ack)//new 
	  );

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
	  
 	 dm_wrapper
	#(.NrHarts (1),
       .BusWidth (32),
       .DmBaseAddress ('h1000),
       .SelectableHarts (1'b1),
       .ReadByteEnable (1))
   debug_module
     (
		.clk_i(wb_clk),
		.rst_ni(!wb_rst),
		.testmode_i(1'b0),
		.ndmreset_o(),
		.dmactive_o(), 
		.debug_req_o(debug_request),
		.unavailable_i(1'b0), 
		.hartinfo_i(32'h212380),//h212380

		.slave_req_i(wb_debug_cyc),
		.slave_we_i(wb_debug_we),
		.slave_addr_i(wb_debug_adr),
		.slave_be_i(wb_debug_sel),
		.slave_wdata_i(wb_debug_dat),
		.slave_rdata_o(wb_debug_rdt),
		.slave_ack_o(wb_debug_ack),

		.master_req_o(),
		.master_add_o(),
		.master_we_o(),
		.master_wdata_o(),
		.master_be_o(),
		.master_gnt_i(1'b0),
		.master_r_valid_i(1'b0),
		.master_r_rdata_i(),
		
		.tck_i(tck_i),
		.tms_i(tms_i),
		.trst_ni(trst_ni),
		.td_i(td_i),
		.td_o(td_o)
		); 
	  

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
     #(.RESET_PC (32'hC000_0000),
       .RESET_STRATEGY (reset_strategy),
       .WITH_CSR (with_csr))
   cpu
     (
      .clk      (wb_clk),
      .i_rst    (i_rst_cpu),
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
      .i_ibus_rdt   (wb_cpu_rdt),
      .i_ibus_ack   (wb_cpu_ibus_ack),//

      .o_dbus_adr   (wb_dbus_adr),
      .o_dbus_dat   (wb_dbus_dat),
      .o_dbus_sel   (wb_dbus_sel),
      .o_dbus_we    (wb_dbus_we),
      .o_dbus_cyc   (wb_dbus_cyc),
      .i_dbus_rdt   (wb_cpu_rdt),
      .i_dbus_ack   (wb_cpu_dbus_ack),
	  .i_debug_interrupt(debug_request));
	  

endmodule
