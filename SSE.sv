module SSE (
	input logic clk, rst, stop,
	input logic [31:0] A, B,
	output logic ready, next,
	output logic [31:0] Y
);

	logic [2:0] state = 3'd0;
	parameter idle = 3'd0, subtract = 3'd1, multiply = 3'd2, add = 3'd3, stopped = 3'd4;
	logic [31:0] difference, product;
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
			next <= 1;
			state <= idle;
			ready <= 0;
		end
	
		case(state)
			
			idle: begin
				if (!busy1) begin
					next <= 0;
					start1 <= 1;
					state <= subtract;
					wc <= 0;
				end
			end
			
			subtract: begin
				start1 <= 0;
				wc <= wc + 1;
				if (!busy1 && !busy2 && wc > 0) begin
					start2 <= 1;
					state <= multiply;
				end
			end
			
			multiply: begin
				start2 <= 0;
				if (!busy2 && !busy3) begin
					start3 <= 1;
					state <= add;
				end
			end
			
			add: begin
				start3 <= 0;
				if (!busy3) begin
					next <= 1;
					if (stop) begin
						state <= stopped;
					end
					else begin
						state <= idle;
					end
				end
			end
			
			stopped: begin
				ready <= 1;
				state <= idle;
			end
			
		endcase
		
	end
	
endmodule