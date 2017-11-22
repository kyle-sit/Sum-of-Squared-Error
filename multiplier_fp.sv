/* File containing module code for a floating point multiplier
*/

//multiplier module
module multiplier_fp(
	input logic clk, start,
	input logic [31:0] A, B,
	output logic ready, busy,
	output logic [31:0] Y
);

	logic [3:0] state = 4'd0; // 3 states = 2 bits
	parameter idle = 4'd0, checks = 4'd1, normalize = 4'd2, round = 4'd3, stillnormalized = 4'd4, finished = 4'd5;
	logic A_sign, B_sign, isSet;
	logic [23:0] A_mantissa, B_mantissa;
	logic [24:0] final_mantissa;
	logic [7:0] A_exponent, B_exponent;
	logic signed [9:0] final_exponent;
	logic [47:0] output_mantissa;
	
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
					final_exponent <= (A_exponent + B_exponent) - 127;
					output_mantissa <= A_mantissa * B_mantissa;
					state <= normalize;
				end
			end
			
			normalize: begin
				if((final_exponent > 254) || (final_exponent < 1)) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
					isSet <= 1;
				end
				else if (output_mantissa[47] == 1) begin
					final_exponent <= final_exponent + 1;
					output_mantissa <= output_mantissa >> 23;
					state <= round;
				end
				else begin
					final_mantissa <= output_mantissa[46:23];
					state <= finished;
				end
			end
			
			round: begin
				if(final_exponent[8] == 1) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
					isSet <= 1;
				end
				else begin
					if (output_mantissa[0] == 1) begin
						final_mantissa <= output_mantissa[24:1] + 1;
					end
					else begin
						final_mantissa <= output_mantissa[24:1];
					end
				end
				state <= stillnormalized;
			end

			stillnormalized: begin
				if(final_exponent[8] == 1) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
					isSet <= 1;
				end
				else if(final_mantissa[24] == 1) begin
					if (final_mantissa[0] == 0) begin
						final_mantissa <= final_mantissa >> 1;
						final_exponent <= final_exponent + 1;
						state <= finished;
					end
					else begin
						final_mantissa <= final_mantissa[24:1] + 1;
						final_exponent <= final_exponent + 1;
						state <= stillnormalized;
					end
				end
				else begin
					state <= finished;
				end
			end
			
			finished: begin
				if (isSet) begin
				end
				else if( A_sign == B_sign ) begin
					Y <= {1'b0, final_exponent[7:0], final_mantissa[22:0]};
				end
				else begin
					Y <= {1'b1, final_exponent[7:0], final_mantissa[22:0]};
				end
				ready <= 1;
				state <= idle;
			end

		endcase
	end

endmodule