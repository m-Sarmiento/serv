`default_nettype none
module servant_spi_sim
  (input wire  wb_clk,
   input wire  wb_rst,
   output wire q);

   wire  i_sck;
   wire  i_copi;
   wire  o_cipo;
   wire  i_cs;

   parameter memfile = "";
   parameter memsize = 8192;
   parameter with_csr = 1;

   reg [1023:0] firmware_file;
   parameter rbbport = 44853;
   `ifndef YOSYS
   initial
     if ($value$plusargs("firmware=%s", firmware_file)) begin
	$display("Loading RAM from %0s", firmware_file);
	$readmemh(firmware_file, dut.ram.mem);
     end
   `endif

   spidpi #(
     .ListenPort(rbbport)
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
     #(.memfile  (memfile),
       .memsize  (memsize),
       .sim      (1),
       .with_csr (with_csr))
   dut(wb_clk, wb_rst, i_sck, i_copi, o_cipo, i_cs, q);//SPI interface

endmodule
