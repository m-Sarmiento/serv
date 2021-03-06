module fsm_serv
(
input wire clk, 
input wire rst, 
input wire i_start, 
input wire i_cpu_reset, 
input wire i_ack, 
output reg o_enable, 
output reg o_out_cyc,
output reg o_busy
);

reg [1:0] state;

parameter init=0, wait_ack=1, load=2;

     /*always @(state) 
     begin
          case (state)
               init: 
               begin
                    o_enable <= 0;
                    o_out_cyc <= 0;
                    o_busy <= 0; 
               end
               wait_ack:
               begin
                    o_enable <= 0;
                    o_out_cyc <= 1;
                    o_busy <= 1;
               end
               load:
               begin
                    o_enable <= 1;
                    o_out_cyc <= 0;
                    o_busy <= 1;
               end
               default:
               begin
                    o_enable <= 0;
                    o_out_cyc <= 0;
                    o_busy <= 0;
               end
          endcase
     end*/ // Previous output logic, but verilator confuses blocking with non-blocking

always @(posedge clk or negedge rst)
     begin
          if (rst == 0) begin
              state <= init;
              o_enable <= 0;
              o_out_cyc <= 0;
              o_busy <= 0; 
          end else
               case (state)
                    init:
                        if (i_start == 1 && i_cpu_reset==1) begin
                              state <= wait_ack;
                              o_enable <= 0;
                              o_out_cyc <= 1;
                              o_busy <= 1;
                        end
                    wait_ack:
                        if (i_cpu_reset==0) begin
                            state <= init;
                            o_enable <= 0;
                            o_out_cyc <= 0;
                            o_busy <= 0; 
                        end else if (i_ack != 0) begin
                            state <= load;
                            o_enable <= 1;
                            o_out_cyc <= 0;
                            o_busy <= 1;
                        end
                    default: begin // Implicit load state also
                            state <= init;
                            o_enable <= 0;
                            o_out_cyc <= 0;
                            o_busy <= 0;
                        end
               endcase
     end

endmodule
