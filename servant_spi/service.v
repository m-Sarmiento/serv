`default_nettype none
module service
(
 input wire  CLK,
 input wire  BTN_N,
 //SPI init
 input wire  P1A1,
 input wire  P1A2,
 output wire P1A3,
 input wire  P1A4,
 //SPI end
 output wire LEDG_N,
 output wire LEDR_N,
 output wire TX);

   parameter memfile = "zephyr_hello.hex";
   parameter memsize = 8192;
   parameter PLL = "NONE";

   wire      wb_clk;
   wire      wb_rst;

   //
   wire  i_sck;
   wire  i_copi;
   wire o_cipo; 
   wire  i_cs;
   wire q;

   assign i_sck = P1A1;
   assign i_copi = P1A2;
   assign P1A3 = o_cipo;
   assign i_cs = P1A4;
   assign LEDG_N = q;
   assign LEDR_N = BTN_N;
   assign TX = q;

   servant_clock_gen #(.PLL (PLL))
   clock_gen
     (.i_clk (CLK),
      .o_clk (wb_clk),
      .o_rst (wb_rst));

   servant
     #(.memfile (memfile),
       .memsize (memsize))
   servant
     (.wb_clk (wb_clk),
      .wb_rst (wb_rst || ~BTN_N ),
      .i_sck(i_sck), 
      .i_copi(i_copi), 
      .o_cipo(o_cipo), 
      .i_cs(i_cs),
      .q      (q));

endmodule
