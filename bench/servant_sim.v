`default_nettype none
module servant_sim
  (input wire  wb_clk,
   input wire  wb_rst,
   output wire q);

	parameter memfile = "";
	parameter memsize = 8192;
	parameter with_csr = 1;
	
	parameter  Name = "jtag0";
	parameter  ListenPortJtag = 44809;
	parameter  ListenPortSpi = 44853;


	wire trst_ni;
	wire tck_i;
	wire tms_i;
	wire td_i;
	wire td_o;


   wire  i_sck;
   wire  i_copi;
   wire  o_cipo;
   wire  i_cs;
   
   reg [1023:0] firmware_file;
   initial
     if ($value$plusargs("firmware=%s", firmware_file)) begin
	$display("Loading RAM from %0s", firmware_file);
	$readmemh(firmware_file, dut.ram.mem);
     end
	 
 spidpi #(
     .ListenPort(ListenPortSpi)
   ) simspi (
     .wb_clk(wb_clk),
     .wb_rst(wb_rst),
     .spi_sck(i_sck),
     .spi_copi(i_copi),
     .spi_cipo(o_cipo),
     .spi_cs(i_cs),
     .spi_nrst()
   );
   
servant      
	#(.memfile  	(memfile),
       .memsize  (memsize),
       .sim      		(1),
       .with_csr 	(with_csr))
dut(
		.wb_clk		(wb_clk),
		.wb_rst		(wb_rst),
		.q				(q),
		.trst_ni		(trst_ni),
		.tck_i		(tck_i),
		.tms_i		(tms_i),
		.td_i			(td_i),
		.td_o			(td_o),
		.i_sck		(i_sck),
		.i_copi		(i_copi),
		.o_cipo		(o_cipo),
		.i_cs			(i_cs)
		);

jtagdpi  
	#(.Name(Name),
	.ListenPort(ListenPortJtag))
jtag(
		.clk_i					(wb_clk),
		.rst_ni					(wb_rst),
		.jtag_tck				(tck_i),
		.jtag_tms				(tms_i),
		.jtag_tdi				(td_i),
		.jtag_tdo				(td_o),
		.jtag_trst_n			(trst_ni),
		.jtag_srst_n			()
);

endmodule
