module SSE (
	input logic clk, rst, stop,
	input logic [31:0] A, B,
	output logic ready, next,
	output logic [31:0] Y
);

	logic [2:0] state;
	parameter idle = 3'd0, subtract = 3'd1, multiply = 3'd2, add = 3'd3, stopped = 3'd4;
	logic [31:0] difference, product;
	logic [4:0] wc;
	logic start1, ready1, busy1, start2, ready2, busy2, start3, ready3, busy3;

	adder_fp adder1 (
		.clk(clk), .start(start1), .op(1),
		.A(A), .B(B),
		.ready(ready1), .busy(busy1),
		.Y(difference)
	);
	
	multiplier_fp multiplier1 (
		.clk(clk), .start(start2),
		.A(difference), .B(difference),
		.ready(ready2), .busy(busy2),
		.Y(product)
	);

	adder_fp adder2 (
		.clk(clk), .start(start3), .op(0),
		.A(Y), .B(product),
		.ready(ready3), .busy(busy3),
		.Y(Y)
	);
	
	always_ff @(posedge clk) begin
	
		if(rst) begin
			Y <= 0;
			//next <= 1;
			state <= idle;
			ready <= 0;
			wc <= 0;
		end

		case(state)
			
			idle: begin
				if (!busy1) begin
					start1 <= 1;
					state <= subtract;
					next <= 0;
				end
			end
			
			subtract: begin
				if (!busy1 && !start1) begin
					if( wc == 1 ) begin
						wc <= wc + 1;
					end
					else if (wc == 2) begin
						next <= 1;
						wc <= wc + 1;
					end
					else begin
						wc <= 0;
						start1 <= 1;
						start2 <= 1;
						state <= multiply;
						next <= 0;
					end 
				end
				else begin
					start1 <= 0;
					next <= 0;
					wc <= 1;
				end
			end
			
			multiply: begin
				if (!busy1 && !busy2 && !start1 && !start2) begin
					if (wc == 1) begin
						wc <= wc + 1;
					end		
					if (wc == 2) begin
						next <= 1;
						wc <= wc + 1;
					end
					else if (wc == 3) begin
						wc <= 0;
						start1 <= 1;
						start2 <= 1;
						start3 <= 1;
						state <= add;
						next <= 0;
					end
				end
				else begin
					start1 <= 0;
					start2 <= 0;
					next <= 0;
					wc <= 1;
				end
			end
			
			add: begin
				if ((!busy1 && !busy2 && !busy3) && !(start1 || start2 || start3)) begin
					if(stop) begin
						if(wc == 1) begin
							wc <= wc + 1;
						end
						else if (wc == 2) begin
							start1 <= 0;
							start2 <= 1;
							start3 <= 1;
							wc <= wc + 1;
						end
						else if (wc == 3) begin
							wc <= wc + 1;
						end
						else if (wc == 4) begin
							start1 <= 0;
							start2 <= 0;
							start3 <= 1;
							wc <= wc + 1;
						end
						else begin
							start1 <= 0;
							start2 <= 0;
							start3 <= 0;
							state <= stopped;
							ready <= 1;
						end
						next <= 0;
					end
					else begin
						if (wc == 1) begin
							wc <= wc + 1;
						end				
						else if (wc == 2) begin
							next <= 1;
							wc <= wc + 1;						end
						else begin
							wc <= 0;
							start1 <= 1;
							start2 <= 1;
							start3 <= 1;
							next <= 0;
						end
					end
				end
				else begin
					if( wc < 1) begin
						wc <= 1;
					end
					start1 <= 0;
					start2 <= 0;
					start3 <= 0;
					next <= 0;
				end
			end
			
			stopped: begin
				wc <= 0;
			end
			
		endcase
		
	end
	
endmodule