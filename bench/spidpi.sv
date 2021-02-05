module spidpi #(
		parameter string Name = "spi0", // name of the SPI interface (display only)
  	parameter int ListenPort = 44853 // TCP port to listen on)
  	)(
  input  wb_clk,
  input  wb_rst,

  output spi_sck,
  output spi_copi,
  input  spi_cipo,
  output spi_cs,
  output spi_nrst
);

  import "DPI-C"
  function chandle spidpi_create(input string name, input int listen_port);

  import "DPI-C"
  function void spidpi_tick(input chandle ctx, output bit sck, 
                             output bit csn, output bit mosi, 
                             output bit rst_n, input bit miso);

  import "DPI-C"
  function void spidpi_close(input chandle ctx);

  chandle ctx;
  
  reg [1:0] counter = 0;
  reg [31:0] rbbport = 44853;

  initial begin
    if ($value$plusargs("rbbport=%d", rbbport)) begin
      $display("Changing port of rbb to %d", rbbport);
      ctx = spidpi_create(Name, rbbport);
    end else begin
      ctx = spidpi_create(Name, ListenPort);
    end
  end

  final begin
    spidpi_close(ctx);
    ctx = 0;
  end
  //need a clock divider for wb_clk?, maybe 4 clock cycles
  always_ff @(posedge wb_clk, posedge wb_rst) begin
  	if (wb_rst == 1'b1)counter <= 0;
  	else counter <= counter +1;
  	if (counter == 2'b11) spidpi_tick(ctx, spi_sck, spi_cs, spi_copi, spi_nrst, spi_cipo);
  end

endmodule
