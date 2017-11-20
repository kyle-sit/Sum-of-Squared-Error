`timescale 1ns / 1ps

module SSE_tb;

	logic [31:0] A, B;
	logic clk, rst, stop;
	logic [31:0] Y;
	logic ready, next;
	logic [2:0] state = 3'd0;
	parameter zero = 3'd0, one = 3'd1, two = 3'd2, three = 3'd3;
	
	SSE uut (
		.A(A), .B(B),
		.clk(clk), .rst(rst), .stop(stop),
		.ready(ready), .next(next)
	);
	
	initial begin
		clk = 0;
	end
	
	always_ff @(posedge clk) begin
		case (state)	
			zero: begin
				stop <= 0;
				rst <= 1;
				A <= 32'b01000000100000000000000000000000;
				B <= 32'b01000000000000000000000000000000;
				state <= one;
			end
			
			one: begin
				rst <= 0;
				if (next) begin
					A <= 32'b01000000100000000000000000000000;
					B <= 32'b01000000000000000000000000000000;
					state <= two;
				end
			end
		
			two: begin
				if (next) begin
					$display("%h", Y);
					A <= 32'b01000001000000000000000000000000;
					B <= 32'b01000000100000000000000000000000;
					state <= three;
				end
			end
			
			three: begin
				stop <= 1;
				if (ready) begin
					$display("%h", Y);
				end
			end
			
		endcase	
	end
	
	always begin
		#50
		clk = ~clk;
	end

endmodule