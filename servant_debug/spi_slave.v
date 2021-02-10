module spi_slave
     (
      input wire 	 clk,
      output wire [31:0] i_wb_cpu_spi_adr,
      output wire [31:0] i_wb_cpu_spi_dat,
      output wire [3:0]  i_wb_cpu_spi_sel,
      output wire        i_wb_cpu_spi_we,
      output wire        i_wb_cpu_spi_cyc,
      input wire [31:0]  o_wb_cpu_spi_rdt,
      input wire         o_wb_cpu_spi_ack,
      output wire        cpu_reset,
      output wire        system_reset,
      input wire         [71:0] spi_out,
      output wire        [39:0] spi_in,
      input wire         spi_reset
    );

      wire [31:0] addr;
      wire [31:0] data_out;
      reg  start;
      wire pulse_start;
      wire we;
      wire reset_cpu;
      wire reset_system;

      wire [31:0] data_in;
      wire is_busy;
      wire enable;

      reg [31:0]data;
      reg [2:0]status;

      assign addr = spi_out[71:40];
      assign data_out = spi_out[39:8];
      assign reset_cpu = spi_out[0];
      assign reset_system = spi_out[1];
      assign we = spi_out[3];
      //assign start = spi_out[2];

      assign i_wb_cpu_spi_adr = addr;
      assign i_wb_cpu_spi_dat = data_out;
      assign i_wb_cpu_spi_sel = 4'hF;
      assign i_wb_cpu_spi_we  = we;

      assign cpu_reset  = reset_cpu;
      assign system_reset  = reset_system;

      always @(posedge clk)
      begin
               start <=spi_out[2];
      end

      always @(posedge clk or negedge spi_reset)
      begin
          if (spi_reset == 1'b0) begin
               data <= 32'h0;
               status <= 3'h0;
          end else begin
               status <={is_busy, system_reset,reset_cpu};
               if (enable == 1 && we == 0) 
               begin
               data <= o_wb_cpu_spi_rdt;
               end
          end
      end

      assign spi_in = {data,5'd0,status};
      assign pulse_start = spi_out[2] &  ~start;

      fsm fsm
	(
	.clk(clk), 
	.rst(spi_reset), 
	.i_start(pulse_start), 
	.i_cpu_reset(reset_cpu), 
	.i_ack(o_wb_cpu_spi_ack), 
	.o_enable(enable), 
	.o_out_cyc(i_wb_cpu_spi_cyc),
	.o_busy(is_busy)
	);


endmodule
