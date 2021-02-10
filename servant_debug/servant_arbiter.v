/* Arbitrates between dbus and ibus accesses.
 * Relies on the fact that not both masters are active at the same time
 */
module servant_arbiter
  (
	// data bus from cpu 
   input wire [31:0]  i_wb_cpu_dbus_adr,
   input wire [31:0]  i_wb_cpu_dbus_dat,
   input wire [3:0]   i_wb_cpu_dbus_sel,
   input wire 	      i_wb_cpu_dbus_we,
   input wire 	      i_wb_cpu_dbus_cyc,
   
   output wire 	      o_wb_cpu_dbus_ack,
   
	// instruction bus from cpu 
   input wire [31:0]  i_wb_cpu_ibus_adr,
   input wire 	      i_wb_cpu_ibus_cyc,
   
   // data and ack back to cpu
   output wire [31:0] o_wb_cpu_rdt,
   output wire 	      o_wb_cpu_ibus_ack,

	// wb signal to mux
   output wire [31:0] o_wb_cpu_adr,
   output wire [31:0] o_wb_cpu_dat,
   output wire [3:0]  o_wb_cpu_sel,
   output wire 	      o_wb_cpu_we,
   output wire 	      o_wb_cpu_cyc,
   
   //return data and ack from mux 
   input wire [31:0]  i_wb_cpu_rdt,
   input wire 	      i_wb_cpu_ibus_ack,
   input wire 	      i_wb_cpu_dbus_ack,
   
   input wire [31:0]  i_wb_cpu_spi_adr,
   input wire [31:0]  i_wb_cpu_spi_dat,
   input wire [3:0]   i_wb_cpu_spi_sel,
   input wire 	      i_wb_cpu_spi_we,
   input wire 	      i_wb_cpu_spi_cyc,
   output wire [31:0] o_wb_cpu_spi_rdt,
   output wire 	      o_wb_cpu_spi_ack
   );

	//return data and ack from mux to cpu 
   assign o_wb_cpu_rdt = i_wb_cpu_rdt;
   assign o_wb_cpu_dbus_ack = i_wb_cpu_dbus_ack & !i_wb_cpu_ibus_cyc;
   assign o_wb_cpu_ibus_ack = i_wb_cpu_ibus_ack & i_wb_cpu_ibus_cyc;

	// wb bus to mux 
   assign o_wb_cpu_adr = i_wb_cpu_spi_cyc ? i_wb_cpu_spi_adr : (i_wb_cpu_ibus_cyc ? i_wb_cpu_ibus_adr : i_wb_cpu_dbus_adr);
   assign o_wb_cpu_dat = i_wb_cpu_spi_cyc ? i_wb_cpu_spi_dat : i_wb_cpu_dbus_dat;
   assign o_wb_cpu_sel = i_wb_cpu_spi_cyc ? i_wb_cpu_spi_sel : i_wb_cpu_dbus_sel;
   assign o_wb_cpu_we = i_wb_cpu_spi_cyc ? i_wb_cpu_spi_we : (i_wb_cpu_dbus_we & !i_wb_cpu_ibus_cyc);
   assign o_wb_cpu_cyc = i_wb_cpu_spi_cyc | i_wb_cpu_ibus_cyc | i_wb_cpu_dbus_cyc;
   
   assign o_wb_cpu_spi_rdt = i_wb_cpu_rdt;
   assign o_wb_cpu_spi_ack = i_wb_cpu_ibus_ack & i_wb_cpu_spi_cyc /*& !i_wb_cpu_ibus_cyc*/;

endmodule
