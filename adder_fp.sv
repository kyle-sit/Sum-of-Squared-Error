/* File containing module code for a floating point adder
*/

//adder module
module adder_fp(
	input logic clk, start, op,
	input logic [31:0] A, B,
	output logic ready, busy,
	output logic [31:0] Y	
);

	logic [3:0] state = 4'd0; // 3 states = 2 bits
	parameter idle = 4'd0, checks = 4'd1, operation = 4'd2, addition = 4'd3, subtraction = 4'd4, leadingZero = 4'd5, 
		finished = 4'd6;
	logic A_sign, B_sign, isSet, group2;
	logic [23:0] A_mantissa, B_mantissa, final_mantissa;
	logic [7:0] A_exponent, B_exponent, final_exponent;
	logic [24:0] output_mantissa;
	
	always_ff @(posedge clk) begin
		case(state)
			idle: begin
				ready <= 0;
				busy <= 0;
				if (start) begin
					state <= checks;
					A_sign <= A[31];
					A_exponent <= A[30:23];
					A_mantissa <= {1'b1, A[22:0]};
					B_sign <= B[31];
					B_exponent <= B[30:23];
					B_mantissa <= {1'b1, B[22:0]};
					isSet <= 0;
					group2 <= 0;
				end
			end
			
				// infinity = 8'b11111111 for exponent, 0 for mantissa
				// NaN = 8'b11111111 for exponent, xxxx... for mantissa
				//case if either input is NaN
			
			checks: begin
				busy <= 1;
				if(((A_exponent == 8'b11111111) && (A_mantissa[22:0] > 0)) || ((B_exponent == 8'b11111111) && (B_mantissa[22:0] > 0))) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					isSet <= 1;
					state <= finished;
				end
				//case if both inputs are infinity
				else if ((A_exponent == 8'b11111111 && A_mantissa[22:0] == 0) && (B_exponent == 8'b11111111 && B_mantissa[22:0] == 0)) begin
					if (A_sign == B_sign) begin
						Y <= A;
						isSet <= 1;
						state <= finished;
					end
					else begin
						Y <= {1'b0,8'b11111111,22'b0,1'b1};
						isSet <= 1;
						state <= finished;
					end
				end
				//case if A input is infinity
				else if (A_exponent == 8'b11111111 && A_mantissa[22:0] == 0) begin
					Y <= A;
					isSet <= 1;
					state <= finished;
				end
				//case if B input is infinity
				else if (B_exponent == 8'b11111111 && B_mantissa[22:0] == 0) begin
					Y <= B;
					isSet <= 1;
					state <= finished;
				end
				else begin
					// figure out which number is bigger
					if (A_exponent < B_exponent) begin
						A_mantissa <= A_mantissa >> (B_exponent - A_exponent);
						final_exponent <= B_exponent;
					end
					else begin 
						B_mantissa <= B_mantissa >> (A_exponent - B_exponent);
						final_exponent <= A_exponent;
					end
					state <= operation;
				end
			end
			
			// 3
			operation: begin
					// adding same sign or subtracting different signs = addition logic
					if ((!op && !A_sign && !B_sign) || (!op && A_sign && B_sign) || (op && !A_sign && B_sign) || (op && A_sign && !B_sign)) begin
						output_mantissa <= A_mantissa + B_mantissa;
						state <= addition;
					end
					else begin
						group2 <= 1;
						state <= subtraction;
					end
			end
			
			// 4
			addition: begin
				// if there's overflow
				if (output_mantissa[24] == 1) begin
					final_exponent <= final_exponent + 1;
					if (output_mantissa[0] == 1) begin
						final_mantissa <= output_mantissa[24:1] + 1;
					end
					else begin
						final_mantissa <= output_mantissa[24:1];
					end
								
					if (final_exponent == 255) begin
						final_mantissa <= 0;
					end
								
				end
				// no overflow
				else begin
					final_mantissa <= output_mantissa[23:0];
				end
	
				state <= finished;
			end
			
			// 4
			subtraction: begin
				// adding different sign or subtracting same signs
				if (A_mantissa < B_mantissa) begin 
					output_mantissa <= B_mantissa - A_mantissa;
					state <= leadingZero;
				end
				else if (B_mantissa < A_mantissa) begin
					output_mantissa <= A_mantissa - B_mantissa;
					state <= leadingZero;
				end
				else begin
						Y <= 0;
						state <= finished;
				end

			end
			
			// 5
			leadingZero: begin
				if (output_mantissa[23] != 0) begin
					final_mantissa <= output_mantissa[23:0];
					state <= finished;
				end
				else begin
					output_mantissa <= output_mantissa << 1;
					final_exponent <= final_exponent - 1;
					state <= leadingZero;
				end
			end
			
			// 6
			finished: begin
				if (isSet) begin
				end
				else if ((A_mantissa < B_mantissa) && group2 ) begin
					Y <= {!A_sign, final_exponent, final_mantissa[22:0]};
				end
				else begin
					Y <= {A_sign, final_exponent, final_mantissa[22:0]};
				end
				ready <= 1;
				state <= idle; 
			end
			
		endcase
	end

endmodule