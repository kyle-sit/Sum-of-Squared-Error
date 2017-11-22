`timescale 1ns / 1ps

module SSE_tb;

	logic [31:0] A, B;
	logic clk, rst, stop;
	logic [31:0] Y;
	logic ready, next;
	logic [2:0] state = 3'd0;
	logic [3:0] wc = 4'd0;
	parameter zero = 3'd0, one = 3'd1, two = 3'd2, three = 3'd3, four = 3'd4, 
			five = 3'd5, six = 3'd6, seven = 3'd7;
	
	SSE uut (
		.A(A), .B(B),
		.clk(clk), .rst(rst), .stop(stop),
		.ready(ready), .next(next),
		.Y(Y)
	);
	
	initial begin
		clk = 0;
	end
	
	always_ff @(posedge clk) begin
		case (state)	
			zero: begin
				stop <= 0;
				rst <= 1;
				wc <= 0;
				A <= 32'b01000000100000000000000000000000;
				B <= 32'b01000000000000000000000000000000;
				state <= one;
			end
			
			one: begin
				rst <= 0;
				if (next) begin
					A <= 32'b01000001000000000000000000000000;
					B <= 32'b01000000100000000000000000000000;
					state <= two;
				end
			end
		
			two: begin
				if (next) begin
					A <= 32'b01000001100000000000000000000000;
					B <= 32'b01000001000000000000000000000000;
					state <= three;
				end
			end
			
			three: begin
				if (next) begin
					A <= 32'b01000001000000000000000000000000;
					B <= 32'b01000000100000000000000000000000;
					state <= four;
				end
			end

			four: begin
				if (next) begin
					A <= 32'b01000000100000000000000000000000;
					B <= 32'b01000000000000000000000000000000;
					state <= five;
					//stop <= 1;
				end
			end
			
			five: begin
				rst <= 0;
				if (next) begin
					A <= 32'b01000001000000000000000000000000;
					B <= 32'b01000000100000000000000000000000;
					state <= six;
					//stop <= 1;
				end
			end

			six: begin
				if (next) begin
					A <= 32'b01000000100000000000000000000000;
					B <= 32'b01000000000000000000000000000000;
					state <= five;
					stop <= 1;
				end
			end

			seven: begin

			end
		endcase	
	end
	
	always begin
		#50
		clk = ~clk;
	end

endmodule