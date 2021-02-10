`default_nettype none
module serv_rf_ram_if
  #(parameter width=8,
    parameter reset_strategy="MINI",
    parameter csr_regs=4,
    parameter depth=32*(32+csr_regs)/width,
    parameter l2w = $clog2(width))
  (
   //SERV side
   input wire 				i_clk,
   input wire 				i_rst,
   input wire 				i_wreq,
   input wire 				i_rreq,
   output wire 				o_ready,
   input wire [$clog2(32+csr_regs)-1:0] i_wreg0,
   input wire [$clog2(32+csr_regs)-1:0] i_wreg1,
   input wire 				i_wen0,
   input wire 				i_wen1,
   input wire 				i_wdata0,
   input wire 				i_wdata1,
   input wire [$clog2(32+csr_regs)-1:0] i_rreg0,
   input wire [$clog2(32+csr_regs)-1:0] i_rreg1,
   output wire 				o_rdata0,
   output wire 				o_rdata1,
   //RAM side
   output wire [$clog2(depth)-1:0] 	o_waddr,
   output wire [width-1:0] 		o_wdata,
   output wire 				o_wen,
   output wire [$clog2(depth)-1:0] 	o_raddr,
   input wire [width-1:0] 		i_rdata,
   
   //debug 
   input wire i_debug_we,
   input wire i_misa
   );

	//debug ROM address
	reg [31:0] debug_addr;
	reg [31:0] dcsr_update;
	reg [31:0] misa_csr;

   reg 				   rgnt;
   assign o_ready = rgnt | i_wreq;

   /*
    ********** Write side ***********
    */

   reg [4:0] 	     wcnt;
   reg 		     wgo;


   reg [width-2:0]   wdata0_r;
   reg [width-1:0]   wdata1_r;

   reg 		     wen0_r;
   reg 		     wen1_r;
   wire 	     wtrig0;
   wire 	     wtrig1;

   generate if (width == 2) begin
      assign wtrig0 = ~wcnt[0];
      assign wtrig1 =  wcnt[0];
   end else begin
      reg wtrig0_r;
      always @(posedge i_clk) wtrig0_r <= wtrig0;
      assign wtrig0 = (wcnt[l2w-1:0] == {{l2w-1{1'b1}},1'b0});
      assign wtrig1 = wtrig0_r;
   end
   endgenerate

   assign 	     o_wdata = wtrig1 ?
			       wdata1_r :
			       {i_wdata0, wdata0_r};

   wire [$clog2(32+csr_regs)-1:0] wreg  = wtrig1 ? i_wreg1 : i_wreg0;
   generate if (width == 32)
     assign o_waddr = wreg;
   else
     assign o_waddr = {wreg, wcnt[4:l2w]};
   endgenerate

   assign o_wen = wgo & ((wtrig0 & wen0_r) | (wtrig1 & wen1_r));

   reg 	      wreq_r;

   generate if (width > 2)
     always @(posedge i_clk) wdata0_r  <= {i_wdata0, wdata0_r[width-2:1]};
   else
     always @(posedge i_clk) wdata0_r  <= i_wdata0;
   endgenerate

   always @(posedge i_clk) begin
      wen0_r    <= i_wen0;
      wen1_r    <= i_wen1;
      wreq_r    <= i_wreq | rgnt;

      wdata1_r  <= {i_wdata1,wdata1_r[width-1:1]};

      if (wgo)
	wcnt <= wcnt+5'd1;

      if (wreq_r) begin
	 wgo <= 1'b1;
      end

      if (wcnt == 5'b11111)
	wgo <= 1'b0;

      if (i_rst) begin
	 if (reset_strategy != "NONE") begin
	   wcnt <= 5'd0;
	   wgo <= 1'b0; 
	 end
      end
   end

   /*
    ********** Read side ***********
    */

   reg [4:0] 	  rcnt;
   //debug counter
   reg [4:0] 	  dbg_cnt;

   wire 	  rtrig0;
   reg 		  rtrig1;

   wire [$clog2(32+csr_regs)-1:0] rreg = rtrig0 ? i_rreg1 : i_rreg0;
   generate if (width == 32)
     assign o_raddr = rreg;
   else
     assign o_raddr = {rreg, rcnt[4:l2w]};
   endgenerate

   reg [width-1:0]  rdata0;
   reg [width-2:0]  rdata1;

   assign o_rdata0 =  i_debug_we ? dcsr_update[dbg_cnt] : i_misa ? misa_csr[dbg_cnt] : rdata0[0];
   assign o_rdata1 = i_debug_we ? debug_addr [dbg_cnt] : rtrig1 ? i_rdata[0] : rdata1[0];

   assign rtrig0 = (rcnt[l2w-1:0] == 1);

   reg 	      rreq_r;

   generate if (width>2)
     always @(posedge i_clk) begin
	rdata1 <= {1'b0,rdata1[width-2:1]}; //Optimize?
	if (rtrig1)
	  rdata1[width-2:0] <= i_rdata[width-1:1];
     end
   else
     always @(posedge i_clk) if (rtrig1) rdata1 <= i_rdata[1];
   endgenerate

   always @(posedge i_clk) begin
      rtrig1 <= rtrig0;
      rcnt <= rcnt+5'd1;
      if (i_rreq)
	 rcnt <= 5'd0;
	 if(i_debug_we | (i_misa & i_wen0))
		dbg_cnt <= dbg_cnt + 5'b1;

      rreq_r <= i_rreq;
      rgnt <= rreq_r;

      rdata0 <= {1'b0,rdata0[width-1:1]};
      if (rtrig0)
	rdata0 <= i_rdata;

      if (i_rst) begin
	 if (reset_strategy != "NONE") begin
	    rgnt <= 1'b0;
	    rreq_r <= 1'b0;
		debug_addr <= 32'h800;
		dcsr_update <= 32'h400000C0;
		misa_csr <= 32'h40000100;
		dbg_cnt <= 5'b0;
	 end
      end
   end



endmodule
