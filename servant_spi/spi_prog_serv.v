module spi_prog_serv(
	//spi_signal
	input  wire i_sck,
	input  wire i_copi,
	output wire o_cipo,
	input  wire i_cs,
	input wire 	 clk,
	//open8 internals signal
	output wire [31:0] 	wb_mem_adr,
  output wire [31:0] 	wb_mem_dat,
  output wire [3:0] 	wb_mem_sel,
  output wire 	wb_mem_we,
  output wire 	wb_mem_cyc,
  input wire [31:0] 	wb_mem_rdt,
  input wire 	wb_mem_ack,
	//control
	input wire         wb_rst,
	output wire        cpu_reset,
	output wire        system_reset
);
   //wire i_rst_cpu;
   //wire i_rst_system;
     
   wire         [71:0] spi_out;
   wire         [39:0] spi_in;
   
   wire  i_nrst;
   
   assign i_nrst = ~wb_rst;
	
   assign i_rst_system = system_reset || wb_rst;
   assign i_rst_cpu = cpu_reset || i_rst_system;

   spi_serv #(.outputs(9), .inputs(5)) spi_1( //max 255
    .i_sck(i_sck),
    .i_copi(i_copi),
    .o_cipo(o_cipo),
    .i_cs(i_cs),
    .i_nrst(i_nrst),
    .rout(spi_out),
    .rin(spi_in)
    );

// SPI init
   spi_slave_serv spi_slave
     (.clk(clk),
      .i_wb_cpu_spi_adr (wb_mem_adr),
      .i_wb_cpu_spi_dat (wb_mem_dat),
      .i_wb_cpu_spi_sel (wb_mem_sel),
      .i_wb_cpu_spi_we  (wb_mem_we ),
      .i_wb_cpu_spi_cyc (wb_mem_cyc),
      .o_wb_cpu_spi_rdt (wb_mem_rdt),
      .o_wb_cpu_spi_ack (wb_mem_ack),
      .cpu_reset        (cpu_reset),
      .spi_reset	(i_nrst),//i_nrst
      .system_reset(system_reset),
      .spi_out(spi_out),
      .spi_in(spi_in));

endmodule 
