module dm_wrapper_serv #(
  parameter int unsigned        NrHarts          = 1,
  parameter int unsigned        BusWidth         = 32,
  parameter int unsigned        DmBaseAddress    = 'h1000, // default to non-zero page
  // Bitmask to select physically available harts for systems
  // that don't use hart numbers in a contiguous fashion.
  parameter logic [NrHarts-1:0] SelectableHarts  = {NrHarts{1'b1}},
  parameter bit                 ReadByteEnable   = 1 // toggle new behavior to drive master_be_o during a read
) (
  input  logic                  clk_i,       // clock
  input  logic                  rst_ni,      // asynchronous reset active low, connect PoR here, not the system reset
  input  logic                  testmode_i,
  output logic                  ndmreset_o,  // non-debug module reset
  output logic                  dmactive_o,  // debug module is active
  output logic [NrHarts-1:0]    debug_req_o, // async debug request
  input  logic [NrHarts-1:0]    unavailable_i, // communicate whether the hart is unavailable (e.g.: power down)
  input  dm::hartinfo_t [NrHarts-1:0] hartinfo_i,

  input  logic                  slave_req_i,
  input  logic                  slave_we_i,
  input  logic [BusWidth-1:0]   slave_addr_i,
  input  logic [BusWidth/8-1:0] slave_be_i,
  input  logic [BusWidth-1:0]   slave_wdata_i,
  output logic [BusWidth-1:0]   slave_rdata_o,
  output logic 							slave_ack_o,

  output logic                  master_req_o,
  output logic [BusWidth-1:0]   master_add_o,
  output logic                  master_we_o,
  output logic [BusWidth-1:0]   master_wdata_o,
  output logic [BusWidth/8-1:0] master_be_o,
  input  logic                  master_gnt_i,
  input  logic                  master_r_valid_i,
  input  logic [BusWidth-1:0]   master_r_rdata_i,
  
  input logic      trst_ni,
  input  logic        tck_i,
  input  logic        tms_i,
  input  logic        td_i,
  output wire         td_o         
);

// Debug
logic          debug_req_valid;
logic          debug_req_ready;
dm::dmi_req_t  debug_req;
logic          debug_resp_valid;
logic          debug_resp_ready;
dm::dmi_resp_t debug_resp;


//ack
always @(posedge clk_i)
	if (!rst_ni)
			slave_ack_o <= 1'b0;
	else
			slave_ack_o <= slave_req_i & !slave_ack_o;
// ---------------
// Debug Module
// ---------------
dmi_jtag_serv i_dmi_jtag_serv (
    .clk_i                (clk_i),
    .rst_ni               (rst_ni),
    .dmi_rst_no           (                      ), // keep open
    .testmode_i           (testmode_i),
    .dmi_req_valid_o      ( debug_req_valid      ),
    .dmi_req_ready_i      ( debug_req_ready      ),
    .dmi_req_o            ( debug_req            ),
    .dmi_resp_valid_i     ( debug_resp_valid     ),
    .dmi_resp_ready_o     ( debug_resp_ready     ),
    .dmi_resp_i           ( debug_resp           ),
    .tck_i                ( tck_i    ),
    .tms_i                ( tms_i    ),
    .trst_ni              ( trst_ni ),
    .td_i                 ( td_i    ),
    .td_o                 ( td_o    ),
    .tdo_oe_o             (        )
);

dm_top_serv #(
		.NrHarts (1),
       .BusWidth (32),
       .DmBaseAddress ('h1000),
       .SelectableHarts (1'b1),
       .ReadByteEnable (1)
) i_dm_top_serv (
    .clk_i            (clk_i),
    .rst_ni           (rst_ni), 
    .testmode_i       (testmode_i),
    .ndmreset_o       (ndmreset_o),
    .dmactive_o       (dmactive_o), 
    .debug_req_o      (debug_req_o),
    .unavailable_i    (unavailable_i),
    .hartinfo_i       (hartinfo_i),
    .slave_req_i      (slave_req_i),
    .slave_we_i       (slave_we_i),
    .slave_addr_i     (slave_addr_i),
    .slave_be_i       (slave_be_i),
    .slave_wdata_i    (slave_wdata_i),
    .slave_rdata_o    (slave_rdata_o),
    .master_req_o     (master_req_o),
    .master_add_o     (master_add_o),
    .master_we_o      (master_we_o),
    .master_wdata_o   (master_wdata_o),
    .master_be_o      (master_be_o),
    .master_gnt_i     (master_gnt_i),
    .master_r_valid_i (master_r_valid_i),
    .master_r_rdata_i (master_r_rdata_i),
    .dmi_rst_ni       (rst_ni),
    .dmi_req_valid_i  ( debug_req_valid   ),
    .dmi_req_ready_o  ( debug_req_ready   ),
    .dmi_req_i        ( debug_req         ),
    .dmi_resp_valid_o ( debug_resp_valid  ),
    .dmi_resp_ready_i ( debug_resp_ready  ),
    .dmi_resp_o       ( debug_resp        )
);

endmodule : dm_wrapper_serv