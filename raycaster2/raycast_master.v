
// TODO: Make far ptr relative to root

`include "raycast_defines.v"

module raycast_master
    (

        // WB Master
       m_wb_adr_o, m_wb_sel_o, m_wb_we_o,
       m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o,
       m_wb_stb_o, m_wb_ack_i, m_wb_err_i,
       m_wb_cti_o, m_wb_bte_o,

        // Controller i/o
        ctrl_wb_adr_i, ctrl_wb_sel_i, ctrl_wb_we_i,
        ctrl_wb_dat_o, ctrl_wb_dat_i, ctrl_wb_cyc_i,
        ctrl_wb_stb_i, ctrl_wb_ack_o,
        ctrl_wb_cti_i, ctrl_wb_bte_i,

        // Core i/o
`ifdef CORE0
        c0_wb_adr_i, c0_wb_dat_o, c0_wb_cyc_i, c0_wb_stb_i,
        c0_wb_ack_o,
`endif
`ifdef CORE1
        c1_wb_adr_i, c1_wb_dat_o, c1_wb_cyc_i, c1_wb_stb_i,
        c1_wb_ack_o,
`endif
`ifdef CORE2
        c2_wb_adr_i, c2_wb_dat_o, c2_wb_cyc_i, c2_wb_stb_i,
        c2_wb_ack_o,
`endif
`ifdef CORE3
        c3_wb_adr_i, c3_wb_dat_o, c3_wb_cyc_i, c3_wb_stb_i,
        c3_wb_ack_o,
`endif

        wb_clk, wb_rst,

    );

    // = Parameters =
    parameter CS = 64, CS_L2 = 6;
    parameter WRAP_BITS = 5;
    parameter WRAP_CNT = 8;
    parameter WRAP_BTE = 2'b00; // 01 for 4-beat, 10 for 8-beat, 11 for 16-beat
    // --

    // = Ports =
    input wb_clk;
    input wb_rst;

    // WISHBONE master
   output [31:0]        m_wb_adr_o;
   output [3:0]         m_wb_sel_o;
   output               m_wb_we_o;
   input  [31:0]         m_wb_dat_i;
   output [31:0]        m_wb_dat_o;
   output               m_wb_cyc_o;
   output               m_wb_stb_o;
   input                m_wb_ack_i;
   input                m_wb_err_i;
   output [2:0]         m_wb_cti_o;   // Cycle Type Identifier
   output [1:0]         m_wb_bte_o;   // Burst Type Extension


    input [31:0]    ctrl_wb_adr_i;
    input [3:0]      ctrl_wb_sel_i;
    input            ctrl_wb_we_i;
    output [31:0]    ctrl_wb_dat_o;
    input [31:0]     ctrl_wb_dat_i;
    input            ctrl_wb_cyc_i;
    input            ctrl_wb_stb_i;
    output           ctrl_wb_ack_o;
    input [2:0]     ctrl_wb_cti_i;
    input [1:0]     ctrl_wb_bte_i;


`ifdef CORE0
    input            c0_wb_cyc_i;
    input            c0_wb_stb_i;
    input [31:0]     c0_wb_adr_i;
    output           c0_wb_ack_o;
    output reg [31:0]    c0_wb_dat_o;

    wire c0_wb_req = c0_wb_cyc_i & c0_wb_stb_i;
    assign c0_wb_ack_o = c0_ack & c0_wb_cyc_i;
`else
    wire [31:0] c0_wb_adr_i = 0;
    reg [31:0] c0_wb_dat_o;
    wire c0_wb_req = 0;
`endif
`ifdef CORE1
    input            c1_wb_cyc_i;
    input            c1_wb_stb_i;
    input [31:0]     c1_wb_adr_i;
    output           c1_wb_ack_o;
    output reg [31:0]    c1_wb_dat_o;

    wire c1_wb_req = c1_wb_cyc_i & c1_wb_stb_i;
    assign c1_wb_ack_o = c1_ack & c1_wb_cyc_i;
`else
    wire [31:0] c1_wb_adr_i = 0;
    reg [31:0] c1_wb_dat_o;
    wire c1_wb_req = 0;
`endif
`ifdef CORE2
    input            c2_wb_cyc_i;
    input            c2_wb_stb_i;
    input [31:0]     c2_wb_adr_i;
    output           c2_wb_ack_o;
    output reg [31:0]    c2_wb_dat_o;

    wire c2_wb_req = c2_wb_cyc_i & c2_wb_stb_i;
    assign c2_wb_ack_o = c2_ack & c2_wb_cyc_i;
`else
    wire [31:0] c2_wb_adr_i = 0;
    reg [31:0] c2_wb_dat_o;
    wire c2_wb_req = 0;
`endif
`ifdef CORE3
    input            c3_wb_cyc_i;
    input            c3_wb_stb_i;
    input [31:0]     c3_wb_adr_i;
    output           c3_wb_ack_o;
    output reg [31:0]    c3_wb_dat_o;

    wire c3_wb_req = c3_wb_cyc_i & c3_wb_stb_i;
    assign c3_wb_ack_o = c3_ack & c3_wb_cyc_i;
`else
    wire [31:0] c3_wb_adr_i = 0;
    reg [31:0] c3_wb_dat_o;
    wire c3_wb_req = 0;
`endif

    // --

    // == Registers/memories =

    reg cache_updating;
    reg [3:0] servicing_core;
    reg c0_ack, c1_ack, c2_ack, c3_ack;
    reg reading_cache;
    reg cache_did_write;
    reg cache_wb_cyc;
    reg [2:0] cache_wb_cti;
    reg [2:0] cache_burst_cnt;
    reg m_wb_blank;

    reg [31:0] cache_adr;
    reg [31:0] cache [0:CS-1];
    reg [31:0] tags [0:CS-1];
    reg valid [0:CS-1];

    reg [31:0] cache_hits = 0;
    reg [31:0] cache_miss = 0;
    // --

    // ==
    wire [CS_L2-1:0] cache_ptr = cache_adr[CS_L2-1:0];
    wire [31:0] cache_out = cache[cache_ptr];
    wire [31:0] tags_out = tags[cache_ptr];
    wire valid_out = valid[cache_ptr];
    wire cache_hit = (valid_out==1) && (tags[cache_ptr]==cache_adr);

    wire [WRAP_BITS-1:0] cache_wrap_inc = cache_adr[WRAP_BITS:0]+4'd4;

    wire cache_write = cache_updating && m_wb_ack_i;
    // --

    assign m_wb_cyc_o = !m_wb_blank & (!cache_updating ? ctrl_wb_cyc_i : cache_wb_cyc) ;
    assign m_wb_stb_o = !m_wb_blank & (!cache_updating ? ctrl_wb_stb_i : cache_wb_cyc) ;
    assign m_wb_adr_o = !cache_updating ? ctrl_wb_adr_i : cache_adr ;
    assign m_wb_sel_o = (!cache_updating & !m_wb_blank) ? ctrl_wb_sel_i : 4'b1111 ;
    assign m_wb_we_o  = (!cache_updating & !m_wb_blank) ? ctrl_wb_we_i  : 0 ;
    assign m_wb_dat_o = (!cache_updating & !m_wb_blank) ? ctrl_wb_dat_i : 0 ;
    assign m_wb_cti_o = (!cache_updating & !m_wb_blank) ? ctrl_wb_cti_i : 0;//cache_wb_cti ;
    assign m_wb_bte_o = (!cache_updating & !m_wb_blank) ? ctrl_wb_bte_i : WRAP_BTE ;

    assign ctrl_wb_dat_o = (!cache_updating & !m_wb_blank) ? m_wb_dat_i: 32'b0;
    assign ctrl_wb_ack_o = !m_wb_blank & !cache_updating & m_wb_ack_i;

    always @(posedge wb_clk) begin
        if (wb_rst) begin
            cache_updating <= 0;
            m_wb_blank <= 0;
        end
        else begin
            if (m_wb_blank) begin
                m_wb_blank <= 0;
            end
            else begin
                if (cache_updating) begin
                    if (m_wb_ack_i) begin
                        // cache_burst_cnt <= cache_burst_cnt-1;
                        // if (cache_burst_cnt==1) begin
                        //     cache_wb_cti <= 3'b111;
                        // end
                        // if (cache_burst_cnt==0) begin
                            cache_updating <= 0;
                            m_wb_blank <= 1;
                        // end
                    end
                end
                else if (!ctrl_wb_cyc_i && cache_wb_cyc) begin
                    cache_updating <= 1;
                    m_wb_blank <= 1;
                    // cache_wb_cti <= 3'b010;
                    // cache_burst_cnt <= WRAP_CNT-1;
                end
            end
        end
    end


    always @(posedge wb_clk) begin
        if (wb_rst) begin
            servicing_core <= 4'b0;
            reading_cache <= 0;
            cache_adr <= 0;
        end
        else if (!reading_cache && !cache_wb_cyc) begin
            if (c0_wb_req && !c0_ack) begin
                cache_adr <= c0_wb_adr_i;
                servicing_core[0] <= 1;
                reading_cache <= 1;
            end else
            if (c1_wb_req && !c1_ack) begin
                cache_adr <= c1_wb_adr_i;
                servicing_core[1] <= 1;
                reading_cache <= 1;
            end else
            if (c2_wb_req && !c2_ack) begin
                cache_adr <= c2_wb_adr_i;
                servicing_core[2] <= 1;
                reading_cache <= 1;
            end else
            if (c3_wb_req && !c3_ack) begin
                cache_adr <= c3_wb_adr_i;
                servicing_core[3] <= 1;
                reading_cache <= 1;
            end
        end
        else begin
            reading_cache <= 0;
            if (cache_write)
                cache_adr <= {cache_adr[31:WRAP_BITS], cache_wrap_inc};
            if (cache_hit || cache_write)
                servicing_core <= 0;
        end
    end

    always @(posedge wb_clk) begin
        if (wb_rst) begin
            // c0_wb_dat_o <= 0;
            // c1_wb_dat_o <= 0;
            // c2_wb_dat_o <= 0;
            // c3_wb_dat_o <= 0;
            cache_wb_cyc <= 0;
        end
        else if (cache_wb_cyc) begin
            if (cache_write) begin
                cache_miss = cache_miss + 1;
                if (servicing_core[0]) begin
                    c0_wb_dat_o <= m_wb_dat_i;
                end
                if (servicing_core[1]) begin
                    c1_wb_dat_o <= m_wb_dat_i;
                end
                if (servicing_core[2]) begin
                    c2_wb_dat_o <= m_wb_dat_i;
                end
                if (servicing_core[3]) begin
                    c3_wb_dat_o <= m_wb_dat_i;
                end
                // if (cache_burst_cnt==0)
                    cache_wb_cyc <= 0;
            end
        end
        else if (reading_cache) begin
            if (cache_hit) begin
                cache_hits = cache_hits + 1;
                if (servicing_core[0]) begin
                    c0_wb_dat_o <= cache_out;
                end
                if (servicing_core[1]) begin
                    c1_wb_dat_o <= cache_out;
                end
                if (servicing_core[2]) begin
                    c2_wb_dat_o <= cache_out;
                end
                if (servicing_core[3]) begin
                    c3_wb_dat_o <= cache_out;
                end
            end
            else begin
                cache_wb_cyc <= 1;
            end
        end
    end

    always @(posedge wb_clk)
    begin
        if (cache_write) begin
            cache_did_write <= 1;
            cache[cache_ptr] <= m_wb_dat_i;
            tags[cache_ptr] <= cache_adr;
            valid[cache_ptr] <= 1;
        end
        else begin
            cache_did_write <= 0;
        end
    end

    always @(posedge wb_clk)
        if (wb_rst)
            c0_ack <= 0;
        else if (c0_ack)
            c0_ack <= 0;
        else if (servicing_core[0]) begin
            if (cache_did_write)
                c0_ack <= 1;
            else if (reading_cache && cache_hit)
                c0_ack <= 1;
        end

    always @(posedge wb_clk)
        if (wb_rst)
            c1_ack <= 0;
        else if (c1_ack)
            c1_ack <= 0;
        else if (servicing_core[1]) begin
            if (cache_did_write)
                c1_ack <= 1;
            else if (reading_cache && cache_hit)
                c1_ack <= 1;
        end

    always @(posedge wb_clk)
        if (wb_rst)
            c2_ack <= 0;
        else if (c2_ack)
            c2_ack <= 0;
        else if (servicing_core[2]) begin
            if (cache_did_write)
                c2_ack <= 1;
            else if (reading_cache && cache_hit)
                c2_ack <= 1;
        end

    always @(posedge wb_clk)
        if (wb_rst)
            c3_ack <= 0;
        else if (c3_ack)
            c3_ack <= 0;
        else if (servicing_core[3]) begin
            if (cache_did_write)
                c3_ack <= 1;
            else if (reading_cache && cache_hit)
                c3_ack <= 1;
        end


    integer k;
    initial
        for (k = 0; k < CS - 1; k = k + 1)
        begin
            cache[k] = 0;
            tags[k] = 0;
            valid[k] = 0;
        end

endmodule