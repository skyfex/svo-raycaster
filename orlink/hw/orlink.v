`timescale 1ns / 1ps

module orlink(
	input wb_clk,
	input wb_rst,
	
	input ifclk_in,
	inout [7:0] fifoData_io,
	input gotData_in,
	input gotRoom_in,
	
	output sloe_out,     
	output slrd_out,    
	output slwr_out,   
	output reg [1:0] fifoAddr_out, 
	output reg pktEnd_out,
		
	output [31:0]   m_wb_adr_o,
   output reg [3:0]    m_wb_sel_o,
   output reg          m_wb_we_o,
   input [31:0]    m_wb_dat_i,
   output [31:0]   m_wb_dat_o,
   output reg      m_wb_cyc_o,
   output reg      m_wb_stb_o,
   input           m_wb_ack_i,
   input           m_wb_err_i,
   output [2:0]    m_wb_cti_o,   // Cycle Type Identifier
   output [1:0]    m_wb_bte_o,   // Burst Type Extension

	output cpu_stall_o,
	output cpu_rst_o,
	
	output [7:0] led
    );

parameter IDLE = 0, R_COUNT0 = 1, R_COUNT1 = 2, R_COUNT2 = 3, R_COUNT3 = 4,
				READ = 5, READ_WAIT = 6, READ_COUNT = 13,
			 	BEGIN_WRITE = 7, WRITE_WAIT = 8, WRITE = 9, END_WRITE = 10, 
				WTL_READ1 = 11, WTL_READ2 = 12;
				
parameter OUT_FIFO = 2'b10, IN_FIFO = 2'b11;
parameter FIFO_READ = 3'b100, FIFO_WRITE = 3'b011, FIFO_NOP = 3'b111; //slwr, slrd, sloe

// FPGAlink state registers
reg [3:0] state, state_n;
reg is_write, is_write_n;
reg is_aligned, is_aligned_n;
reg [7:0] addr, addr_n;
reg [31:0] count, count_n;

// Data registers
reg [7:0] test_reg, test_reg_n;
reg [7:0] wtl_reg, wtl_reg_n;

// Control wires
reg fifoData_out_drive;
reg [7:0] fifoData_out;
reg [2:0] fifoOp;

// Link to WB FIFO
wire [7:0] ltw_din;  
reg ltw_wr_en;  
reg ltw_rd_en;  
wire [31:0] ltw_dout; 
wire ltw_full; 	 
wire ltw_empty;  

assign ltw_din = fifoData_io;

// WB to Link FIFO
wire [31:0] wtl_din;  
reg wtl_wr_en;  
reg wtl_rd_en;  
wire [7:0] wtl_dout; 
wire wtl_full; 	 
wire wtl_empty;


assign fifoData_io = fifoData_out_drive ? fifoData_out : 8'bz;

assign m_wb_cti_o = 0;
assign m_wb_bte_o = 0;
	
assign sloe_out = fifoOp[0];
assign slrd_out = fifoOp[1];
assign slwr_out = fifoOp[2];

assign cpu_stall_o = test_reg[0];
assign cpu_rst_o = test_reg[1];

always @(*)
begin
	case(addr)
		0: fifoData_out = test_reg;
		1: fifoData_out = wtl_reg;
		default: fifoData_out = 8'h00;
	endcase
end

always @(*) // asynchronous reset!
	begin
		
		state_n = state;
		is_write_n = is_write;
		is_aligned_n = is_aligned;
		addr_n = addr;
		count_n = count;
		
		test_reg_n = test_reg;
		wtl_reg_n = wtl_reg;
		
		fifoAddr_out = OUT_FIFO;
		fifoOp = FIFO_NOP;
		pktEnd_out = 1;
		fifoData_out_drive = 0;
		
		ltw_wr_en = 0;
		wtl_rd_en = 0;
		
		case(state)
			IDLE: begin
				fifoOp = FIFO_READ;
				if (gotData_in)
				begin
					is_write_n = fifoData_io[7];
					addr_n[2:0] = fifoData_io[2:0];
					state_n = R_COUNT0;
				end
			end
			R_COUNT0: begin
				fifoOp = FIFO_READ;
				if (gotData_in)
				begin
					count_n[31:24] = fifoData_io;
					state_n = R_COUNT1;
				end
			end
			R_COUNT1: begin
				fifoOp = FIFO_READ;
				if (gotData_in)
				begin
					count_n[23:16] = fifoData_io;
					state_n = R_COUNT2;
				end
			end
			R_COUNT2: begin
				fifoOp = FIFO_READ;
				if (gotData_in)
				begin
					count_n[15:8] = fifoData_io;
					state_n = R_COUNT3;
				end
			end
			R_COUNT3: begin
				fifoOp = FIFO_READ;
				if (gotData_in)
				begin
					count_n[7:0] = fifoData_io;
					if (is_write)
						state_n = BEGIN_WRITE;
					else
					begin
						state_n = READ_WAIT;
					end
				end
			end
			BEGIN_WRITE: begin
					fifoAddr_out = IN_FIFO;
					is_aligned_n = ~(count[0] | count[1] | count[2] | count[3] | count[4] | count[5] | count[6] | count[7] | count[8]);
					state_n = WRITE_WAIT;
				end
			WRITE_WAIT: begin
					fifoAddr_out = IN_FIFO;
					if (gotRoom_in) // && ready
					begin
						case (addr)
							0: state_n = WRITE;
							1: state_n = WTL_READ1;
							default: state_n = WRITE;
						endcase
					end
			end
			WTL_READ1: begin
				fifoAddr_out = IN_FIFO;
				if (!wtl_empty) begin
					state_n = WTL_READ2;
					wtl_rd_en = 1;
				end
			end
			WTL_READ2: begin
				fifoAddr_out = IN_FIFO;
				wtl_reg_n = wtl_dout;
				state_n = WRITE;
			end
			WRITE: begin		
					fifoData_out_drive = 1;
					fifoOp = FIFO_WRITE;
					fifoAddr_out = IN_FIFO;
					
					count_n = count-1;
					if (count == 1)
						state_n = END_WRITE;
					else
						state_n = WRITE_WAIT;
			end
			END_WRITE: begin
				pktEnd_out = is_aligned;
				fifoAddr_out = IN_FIFO;
				state_n = IDLE;
			end
			
			READ:	begin
				fifoOp = FIFO_READ;
				if (gotData_in)
				begin
					case(addr)
						0: test_reg_n = fifoData_io;
						1: begin
							ltw_wr_en = 1;
						end
					endcase
					
					state_n = READ_COUNT;
				end
			end
			READ_COUNT: begin
				count_n = count-1;
				if (count == 1)
					state_n = IDLE;
				else
					state_n = READ_WAIT;
			end
			READ_WAIT: begin
				case (addr)
					0: state_n = READ;
					1: if (!ltw_full) state_n = READ;
					default: state_n = READ;
				endcase
			end
			
			default: begin
				state_n = IDLE;
			end
		endcase
	end
	
always @(posedge ifclk_in or posedge wb_rst) // asynchronous reset!
	if (wb_rst)
	begin
		state <= IDLE;
		is_write <= 0;
		is_aligned <= 0;
		addr <= 8'b0;
		count <= 32'b0;
		test_reg <= 8'b0;
		wtl_reg <= 8'b0;
	end
	else
	begin
		state <= state_n;
		is_write <= is_write_n;
		is_aligned <= is_aligned_n;
		addr <= addr_n;
		count <= count_n;
		test_reg <= test_reg_n;
		wtl_reg <= wtl_reg_n;
	end	

parameter CMD_NOP = 8'h00, CMD_WRITE = 8'h01, CMD_READ = 8'h02, CMD_CRC = 8'h03, CMD_STALL = 8'h04, CMD_RESET = 8'h05;

parameter S_WB_IDLE = 0, S_WB_READ_CMD = 1, S_WB_COUNT_WAIT = 2, S_WB_COUNT_READ = 3,
				S_WB_ADR_WAIT = 4, S_WB_ADR_READ = 5, S_WB_WRITE1 = 6, S_WB_WRITE2 = 7,
				S_WB_WRITE3 = 8, S_WB_READ1 = 9, S_WB_READ2 = 10, S_WB_READ3 = 11, S_WB_ERR = 12;

reg [3:0] wb_state, wb_state_n;
reg [31:0] wb_cmd, wb_cmd_n;
reg [31:0] wb_count, wb_count_n;
reg [31:0] wb_adr, wb_adr_n;
reg [31:0] wb_dat, wb_dat_n;


assign wtl_din = wb_dat;
assign m_wb_adr_o = wb_adr;
assign m_wb_dat_o = wb_dat;
assign led = {state[3:0], wb_state[3:0]};


always @(*)
begin
	wb_state_n = wb_state;
	wb_cmd_n = wb_cmd;
	wb_count_n = wb_count;
	wb_adr_n = wb_adr;
	wb_dat_n = wb_dat;
	
	ltw_rd_en = 0;
	wtl_wr_en = 0;
	
	m_wb_cyc_o = 0;
	m_wb_stb_o = 0;
	m_wb_we_o = 0;
	m_wb_sel_o = 4'b1111;
	
	case (wb_state)
		S_WB_IDLE: begin
			if (!ltw_empty) begin
				ltw_rd_en = 1;
				wb_state_n = S_WB_READ_CMD;
			end
		end
		
		S_WB_READ_CMD: begin
			wb_cmd_n = ltw_dout;
			case (ltw_dout[7:0]) 
				CMD_WRITE:	wb_state_n = S_WB_COUNT_WAIT;
				CMD_READ: wb_state_n = S_WB_COUNT_WAIT;
				default: wb_state_n = S_WB_IDLE;
			endcase 
		end
		
		S_WB_COUNT_WAIT: begin
			if (!ltw_empty) begin
				ltw_rd_en = 1;
				wb_state_n = S_WB_COUNT_READ;
			end
		end
		S_WB_COUNT_READ: begin
			wb_count_n = ltw_dout;
			wb_state_n = S_WB_ADR_WAIT;
		end
		
		S_WB_ADR_WAIT: begin
			if (!ltw_empty) begin
				ltw_rd_en = 1;
				wb_state_n = S_WB_ADR_READ;
			end
		end
		S_WB_ADR_READ: begin
			wb_adr_n = ltw_dout;
			case (wb_cmd[7:0])
				CMD_WRITE: wb_state_n = S_WB_WRITE1;
				CMD_READ:  wb_state_n = S_WB_READ1;
				default: wb_state_n = S_WB_IDLE;
			endcase
		end
		
		S_WB_WRITE1: begin
			if (!ltw_empty) begin
				ltw_rd_en = 1;
				wb_state_n = S_WB_WRITE2;
			end
		end
		S_WB_WRITE2: begin
			wb_dat_n = ltw_dout;
			wb_state_n = S_WB_WRITE3;
		end
		S_WB_WRITE3: begin
			m_wb_cyc_o = 1;
			m_wb_stb_o = 1;
			m_wb_we_o = 1;
			if (m_wb_ack_i) begin
				wb_adr_n = wb_adr+4;
				wb_count_n = wb_count-1;
				if (wb_count==32'd1)
					wb_state_n = S_WB_IDLE;
				else
					wb_state_n = S_WB_WRITE1;
			end
			else if (m_wb_err_i) begin
				wb_state_n = S_WB_ERR;
			end
		end
		
		S_WB_READ1: begin
			m_wb_cyc_o = 1;
			m_wb_stb_o = 1;
			if (m_wb_ack_i) begin
				wb_dat_n = m_wb_dat_i;
				wb_state_n = S_WB_READ2;
			end		
			else if (m_wb_err_i) begin
				wb_state_n = S_WB_ERR;
			end	
		end
		S_WB_READ2: begin
			if (!wtl_full) begin
				wb_state_n = S_WB_READ3;
			end
		end
		S_WB_READ3: begin
			wtl_wr_en = 1;
			
			wb_adr_n = wb_adr+4;
			wb_count_n = wb_count-1;
			if (wb_count==32'd1)
				wb_state_n = S_WB_IDLE;
			else
				wb_state_n = S_WB_READ1;			
		end
		S_WB_ERR: begin
			
		end
	endcase
end

always @(posedge wb_clk)
begin
	if (wb_rst) begin
		wb_state <= S_WB_IDLE;
		wb_cmd <= 32'd0;
		wb_count <= 32'd0;
		wb_adr <= 32'd0;
		wb_dat <= 32'd0;
	end
	else begin
		wb_state <= wb_state_n;
		wb_cmd <= wb_cmd_n;
		wb_count <= wb_count_n;
		wb_adr <= wb_adr_n;
		wb_dat <= wb_dat_n;
	end
end

orlink_ltw_fifo link_to_wb_fifo (
  .rst		(wb_rst), 	
  .wr_clk	(ifclk_in), 
  .rd_clk	(wb_clk),	
  .din		(ltw_din), 	
  .wr_en		(ltw_wr_en),
  .rd_en		(ltw_rd_en),
  .dout		(ltw_dout), 
  .full		(ltw_full), 
  .empty		(ltw_empty) 
);
	
orlink_wtl_fifo wb_to_link_fifo (
  .rst		(wb_rst), 	
  .wr_clk	(wb_clk), 	
  .rd_clk	(ifclk_in),	
  .din		(wtl_din), 	
  .wr_en		(wtl_wr_en),
  .rd_en		(wtl_rd_en),
  .dout		(wtl_dout), 
  .full		(wtl_full), 
  .empty		(wtl_empty) 
);

endmodule
