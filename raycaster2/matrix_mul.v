    module matrix_mul
    (
        input clk,
        input normalize,
        input t_mode,

        input nd,

        input invert_v_nd,

        input signed [31:0] v0,
        input signed [31:0] v1,
        input signed [31:0] v2,
        input signed [31:0] v3,

        input signed [31:0] m00,
        input signed [31:0] m01,
        input signed [31:0] m02,
        input signed [31:0] m03,
        input signed [31:0] m10,
        input signed [31:0] m11,
        input signed [31:0] m12,
        input signed [31:0] m13,
        input signed [31:0] m20,
        input signed [31:0] m21,
        input signed [31:0] m22,
        input signed [31:0] m23,
        input signed [31:0] m30,
        input signed [31:0] m31,
        input signed [31:0] m32,
        input signed [31:0] m33,

        output signed [31:0] u0,
        output signed [31:0] u1,
        output signed [31:0] u2,
        output signed [31:0] u3,

        output reg [127:0] test_o,

        output reg rdy


        );

    parameter CAS_LEN = 9;
    parameter CAS_NORM_LEN = 9;

    reg [CAS_LEN:0] cascade;
    reg do_normalize;
    reg dividing = 0;
    reg dividing_nxt;
    reg norming = 0;
    reg norming_nxt;
    reg [1:0] norm_cntr = 0;
    reg norm_cntr_reset;
    reg rdy_nxt;

    reg inverting = 0;
    reg inverting_nxt;
    reg [0:1] invert_in_ctr = 0;
    reg [0:1] invert_in_ctr_nxt;
    reg [0:1] invert_out_ctr = 0;
    reg [0:1] invert_out_ctr_nxt;

    // ----

    reg signed [31:0] a0;
    reg signed [31:0] a1;
    reg signed [31:0] a2;
    reg signed [31:0] a3;

    reg signed [31:0] b0;
    reg signed [31:0] b1;
    reg signed [31:0] b2;
    reg signed [31:0] b3;

    wire signed [63:0] p0;
    wire signed [63:0] p1;
    wire signed [63:0] p2;
    wire signed [63:0] p3;

    wire signed [31:0] pp0 = p0[47:16];
    wire signed [31:0] pp1 = p1[47:16];
    wire signed [31:0] pp2 = p2[47:16];
    wire signed [31:0] pp3 = p3[47:16];

    reg div_nd; // new data
    wire signed [3:0] div_dend = 4'h1; // dividend
    reg [31:0] div_isor; // divisor

    wire signed [3:0] div_quot;
    wire signed [31:0] div_frac;
    wire div_rdy;
    wire div_rfd;
    wire div_dbz; // divide by zero

    reg div_rfd_d;

    // -----

    reg signed [31:0] tmp0, tmp0_nxt;
    reg signed [31:0] tmp1, tmp1_nxt;
    reg signed [31:0] tmp2, tmp2_nxt;
    reg signed [31:0] tmp3, tmp3_nxt;

    // -----

    multiplier multiplier_u0 (.clk(clk), .a(a0), .b(b0), .p(p0));
    multiplier multiplier_u1 (.clk(clk), .a(a1), .b(b1), .p(p1));
    multiplier multiplier_u2 (.clk(clk), .a(a2), .b(b2), .p(p2));
    multiplier multiplier_u3 (.clk(clk), .a(a3), .b(b3), .p(p3));

    divider divider_u0 (
        .clk(clk),
        .nd(div_nd),
        .rdy(div_rdy),
        .rfd(div_rfd),
        .dividend(div_dend),
        .divisor (div_isor),
        .quotient(div_quot),
        .fractional(div_frac),
        .divide_by_zero(div_dbz)
    );

    // -----


    assign u0 = tmp0;
    assign u1 = tmp1;
    assign u2 = tmp2;
    assign u3 = tmp3;

    // ------

    always @(posedge clk)
    begin
        if (nd) begin
            cascade <= {cascade[CAS_LEN-1:0], 1'b1};
            do_normalize <= normalize;
        end
        else if (t_mode && cascade[6]) begin
            cascade <= 0;
        end
        else begin
            cascade <= {cascade[CAS_LEN-1:0], 1'b0};
        end
    end

    always @(posedge clk)
    begin
        dividing <= dividing_nxt;
        norming <= norming_nxt;
        rdy <= rdy_nxt;
        tmp0 <= tmp0_nxt;
        tmp1 <= tmp1_nxt;
        tmp2 <= tmp2_nxt;
        tmp3 <= tmp3_nxt;
        inverting <= inverting_nxt;
        invert_in_ctr <= invert_in_ctr_nxt;
        invert_out_ctr <= invert_out_ctr_nxt;
        div_rfd_d = div_rfd;
    end


    always @(posedge clk)
    begin
        if (norm_cntr_reset) begin
            norm_cntr <= 2'd3;
        end
        else if (norm_cntr != 0) begin
            norm_cntr <= norm_cntr - 1;
        end
    end

    // ----

    always @*
    begin
        a0 = v0;
        a1 = v0;
        a2 = v0;
        a3 = v0;
        b0 = m00;
        b1 = m10;
        b2 = m20;
        b3 = m30;
        tmp0_nxt = tmp0;
        tmp1_nxt = tmp1;
        tmp2_nxt = tmp2;
        tmp3_nxt = tmp3;

        div_isor = tmp3;

        div_nd = 0;
        dividing_nxt = dividing;
        norming_nxt = norming;
        norm_cntr_reset = 0;
        rdy_nxt = 0;

        inverting_nxt = inverting;
        invert_in_ctr_nxt = invert_in_ctr;
        invert_out_ctr_nxt = invert_out_ctr;

        if (cascade[0]) begin


            a0 = v0;
            a1 = v0;
            a2 = v0;
            a3 = v0;
            if (t_mode)
            begin
                a0 = v0;
                a1 = v1;
                a2 = v2;
            end
            b0 = m00;
            b1 = m10;
            b2 = m20;
            b3 = m30;
        end
        if (cascade[1]) begin
            a0 = v1;
            a1 = v1;
            a2 = v1;
            if (t_mode)
            begin
                a0 = v0;
                a1 = v1;
                a2 = v2;
            end
            a3 = v1;
            b0 = m01;
            b1 = m11;
            b2 = m21;
            b3 = m31;
        end
        if (cascade[2]) begin
            a0 = v2;
            a1 = v2;
            a2 = v2;
            a3 = v2;
            b0 = m02;
            b1 = m12;
            b2 = m22;
            b3 = m32;
        end
        if (cascade[3]) begin
            a0 = v3;
            a1 = v3;
            a2 = v3;
            a3 = v3;
            b0 = m03;
            b1 = m13;
            b2 = m23;
            b3 = m33;
        end
        if (cascade[4]) begin
            tmp0_nxt = pp0;
            tmp1_nxt = pp1;
            tmp2_nxt = pp2;
            tmp3_nxt = pp3;
            if (t_mode)
                rdy_nxt = 1;
        end
        if (t_mode) begin
            if (cascade[5]) begin
                tmp0_nxt = pp0;
                tmp1_nxt = pp1;
                tmp2_nxt = pp2;
                tmp3_nxt = pp3;
                rdy_nxt = 1;
            end
        end
        else begin
            if (cascade[5] || cascade[6] || cascade[7]) begin
            tmp0_nxt = tmp0 + pp0;
            tmp1_nxt = tmp1 + pp1;
            tmp2_nxt = tmp2 + pp2;
            tmp3_nxt = tmp3 + pp3;
            end
        end

        if (cascade[8]) begin
            if (do_normalize) begin
                div_nd = 1;
                dividing_nxt = 1;
            end
            else begin
                if (!t_mode)
                    rdy_nxt = 1; // could move ahead one clk
            end
        end
        if (dividing && div_rdy) begin
            a0 = tmp0;
            a1 = tmp1;
            a2 = tmp2;
            a3 = tmp3;
            b0 = div_frac;
            b1 = div_frac;
            b2 = div_frac;
            b3 = div_frac;
            norm_cntr_reset = 1;
            dividing_nxt = 0;
            norming_nxt = 1;
        end
        if (norming && norm_cntr==0) begin
            tmp0_nxt = pp0;
            tmp1_nxt = pp1;
            tmp2_nxt = pp2;
            tmp3_nxt = pp3;
            norming_nxt = 0;
            rdy_nxt = 1;
        end
        if (invert_v_nd) begin
            div_isor = v0;
            div_nd = 1;
            invert_in_ctr_nxt = 0;
            invert_out_ctr_nxt = 0;
            inverting_nxt = 1;
        end
        if (inverting) begin
            if (invert_in_ctr==0)
            begin
                div_isor = v1;
                if (div_rfd && div_rfd_d) begin
                    invert_in_ctr_nxt = 1;
                    div_nd = 1;
            end
            end
            if (invert_in_ctr==1)
            begin
                div_isor = v2;
                if (div_rfd && div_rfd_d) begin
                    invert_in_ctr_nxt = 1;
                    div_nd = 1;
                end
            end
             begin


            end
            if (div_rdy) begin
                if (invert_out_ctr==0)
                begin
                    tmp0_nxt = div_frac;
                    invert_out_ctr_nxt = 1;
                end
                if (invert_out_ctr==1)
                begin
                    tmp1_nxt = div_frac;
                    invert_out_ctr_nxt = 2;
                end
                if (invert_out_ctr==2)
                begin
                    tmp2_nxt = div_frac;
                    invert_out_ctr_nxt = 3;
                    inverting_nxt = 0;
                    rdy_nxt = 1;
                end
            end
        end
    end

    always @(posedge clk)
    begin
        if (dividing && div_rdy)
            test_o <= {a0, b0, a1, b1};
    end

endmodule
