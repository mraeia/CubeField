module cubefield (
	input CLOCK_50,
	input	[3:0]	KEY,					//	Button[3:0]
	input	[17:0]SW,						//	Switches[0:0]
	output VGA_CLK,   				//	VGA Clock
	output VGA_HS,				//	VGA H_SYNC
	output VGA_VS,					//	VGA V_SYNC
	output VGA_BLANK,				//	VGA BLANK
	output VGA_SYNC,				//	VGA SYNC
	output [9:0]	VGA_R,   				//	VGA Red[9:0]
	output [9:0]	VGA_G,	 				//	VGA Green[9:0]
	output [9:0]	VGA_B   				//	VGA Blue[9:0]
	);
	
	reg [1:0] Q,D;
	reg [14:0]background_counter;
	reg [7:0]cursor_counter;
	reg done_bkgrd;
	reg [3:0] ccounter_x;
	reg [3:0] ccounter_y;
	reg [7:0] bcounter_x;
	reg [6:0] bcounter_y;
	reg [7:0] x;
	reg [6:0] y;
	wire [2:0] color1;
	wire [2:0] color2;
	reg [2:0] color;
	parameter idle = 3'b000, draw_bkgrdx = 3'b001, draw_bkgrdy = 3'b010,draw_cursorx = 3'b011, draw_cursory = 3'b100;
	
	always @ *
		case (Q)
			
			idle:
				if(~KEY[0]) D =  draw_bkgrdx;
				else D = idle;
			draw_bkgrdx:
				if(bcounter_x<160) D = draw_bkgrdx;
				else D = draw_bkgrdy;
			draw_bkgrdy:
				if(bcounter_y<120) 
				D = draw_bkgrdx;
				else 
				begin
				D = draw_cursorx;
				done_bkgrd <= 1'b1;
				end
			draw_cursorx:
				if(ccounter_x<16)
					D = draw_cursorx;
				else D=draw_cursory;
			draw_bkgrdy:
				if (ccounter_y<16)
					D = draw_cursorx;
				else D = idle;
		endcase
	
	always @ (CLOCK_50)
		begin
			Q<=D;
			if (Q == idle)
				begin
					cursor_counter<=0;
					background_counter<=0;
					bcounter_x<=0;
					bcounter_y<=0;
					ccounter_x<=0;
					ccounter_y<=0;
					done_bkgrd<=0;
				end
			if (Q == draw_bkgrdx)
				begin
					x = bcounter_x;
					bcounter_x<=bcounter_x+1;
					background_counter<=background_counter+1;
				end
			if (Q == draw_bkgrdy)
				begin
					bcounter_x <= 0;
					bcounter_y <= bcounter_y + 1;
					background_counter<=background_counter+1;
				end
			if (Q == draw_cursorx)
				begin
					x = 7'b1000111 + ccounter_x;
					ccounter_x <= ccounter_x+1;
					cursor_counter <= cursor_counter + 1 ;
				end
			if (Q == draw_cursory)
				begin 
					ccounter_x <= 0; 
					y = 7'b1011111 + ccounter_y;
					ccounter_y <= ccounter_y+1;
					cursor_counter <= cursor_counter + 1;
				end
		end
	background(background_counter,CLOCK_50,3'b000,1'b0,color1);
	cursormemory(cursor_counter,CLOCK_50,3'b000,1'b0,color2);
	
	always @ *
		begin 
		if (!done_bkgrd)
			color=color1;
		else color=color2;
		end
	
	display(CLOCK_50,VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_R, VGA_G, VGA_B,color, x,y );
		
endmodule

module display
	(
		CLOCK_50,						//	On Board 50 MHz
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,						//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,	  						//	VGA Blue[9:0]
		color,
		x,
		y
	);

	input	CLOCK_50;				//	50 MHz
	input [2:0] color;
	output	VGA_CLK;   				//	VGA Clock
	output	VGA_HS;					//	VGA H_SYNC
	output	VGA_VS;					//	VGA V_SYNC
	output	VGA_BLANK;				//	VGA BLANK
	output	VGA_SYNC;				//	VGA SYNC
	output	[9:0] VGA_R;   			//	VGA Red[9:0]
	output	[9:0] VGA_G;	 		//	VGA Green[9:0]
	output	[9:0] VGA_B;   			//	VGA Blue[9:0]
	
	wire resetn, plot;
	input [7:0] x;
	input [6:0] y;

	assign resetn = 1'b1;
	assign plot=1'b1;

	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(color),
			.x(x),
			.y(y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "";
		
endmodule
