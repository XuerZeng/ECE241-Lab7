//
// This is the template for Part 2 of Lab 7.
//
// Paul Chow
// November 2021

// Part 2 skeleton




module part2(iResetn,iPlotBox,iBlack,iColour,iLoadX,iXY_Coord,iClock,oX,oY,oColour,oPlot,oDone);
   parameter X_SCREEN_PIXELS = 8'd160;
   parameter Y_SCREEN_PIXELS = 7'd120;
   
   input wire iResetn, iPlotBox, iBlack, iLoadX;
   input wire [2:0] iColour;//
   input wire [6:0] iXY_Coord;//
   input wire 	    iClock;//
   output wire [7:0] oX;    //     // VGA pixel coordinates
   output wire [6:0] oY;//
   output wire oDone;
   output wire [2:0] oColour;     // VGA pixel colour (0-7)
   output wire 	     oPlot;       // Pixel draw enable
   
	wire ld_x, ld_y, ld_c, blackEn, drawDone, blackDone;
	
	datapath D0(
		.clk(iClock),
		.resetn(iResetn),
		.ld_x(ld_x),
		.ld_y(ld_y),
		
		.x(oX),
		.y(oY),
		.blackEn(iBlack),
		.data_in(iXY_Coord),
		.color(oColour),
		.color_in(iColour),
		.startDraw(oPlot),
		.drawDone(drawDone),
		.blackDone(blackDone)
	);
	
	control C0(
		.clk(iClock),
		.resetn(iResetn),
		.black(iBlack),
		.ld_x(ld_x),
		.ld_y(ld_y),
		.draw(iPlotBox),
		.ld(iLoadX),
		.writeEn(oPlot),
		.drawDone(drawDone),
		.blackDone(blackDone),
		.blackEn(blackEn),
		.oDone(oDone)
	);
   
endmodule 

module datapath(
    input clk,
    input resetn,
    input startDraw,

    input [6:0] data_in,
    input ld_x, ld_y,
	input [2:0] color_in,
	input blackEn,
    output reg[2:0] color,
	output reg[7:0] x,
	output reg[7:0] y,
	output reg blackDone, drawDone
    );
    
	//wire y_en;
	reg [7:0] x_old;
	reg [6:0] y_old;
	//reg [2:0] color;
    reg [7:0] x_counter, y_counter;
    reg [4:0] counterDraw;
    // Registers x, y, color
    always@(posedge clk) begin
        if(!resetn) 
		begin
			x_old <= 8'b0;
			x <= 8'b0;
			y <= 7'b0;
			y_old <= 7'b0;
			color <= 3'b0;
			drawDone = 1'b0;
			blackDone = 1'b0; // reset pulse on low, reset in effect thus causing black screen
        	end
	else if (blackEn) 
		begin
		        x_old <= 8'b0;
			y_old <= 7'b0;
			color <= 3'b0; //pushbutton in effect for black screen
		end
        else begin
                if(ld_x)
		begin
			x <= {1'b0, data_in};
                	x_old <= {1'b0, data_in}; //register load 8 bits x coordinate, most significant bit = 0
		end
                if(ld_y)
		begin
			y <= data_in;
                	y_old <= data_in;
			color <= color_in; //register load y coordinate
		end
         end
    end
	
	
//use counter for deciding how much and whether or not to move in the next clock cycle	
    always @(posedge clk) begin
		if (!resetn) 
		begin
			x_counter <= 8'b0;
			y_counter <=8'b0;
			counterDraw = 5'b0;
		end //no moving in X coordinate in the next clock cycle
		else if(blackEn) begin //black screen enable is turned on
			if(x_counter == 8'b10100000 & y_counter == 7'b1111000)
			begin
				blackDone = 1'b1;
				x_counter <= 8'b0;
				y_counter <= 8'b0; //exceed screen size
			end
			else if(x_counter == 8'b0 & y_counter == 8'b0)
			begin
				blackDone = 1'b0;
				//x_counter <= x_counter +1'b1; 
			end
			else if(x_counter == 8'd159)
			begin
				x_counter <= 8'b0;
				y_counter <= y_counter +1'b1;
				end
			else 
				x_counter <= x_counter +1'b1;
		end
		else if(startDraw)
			begin
			if (counterDraw == 5'd16) //already at the end of all the 4x4 grid on the screen
				begin
				counterDraw <= 5'b0;
				drawDone = 1'b1; 
				end
			else
				begin
				counterDraw <= counterDraw + 1'b1; //increment one in x direction on the screen
				x <= x_old + {counterDraw[1], counterDraw[0]};
				y <= y_old + {counterDraw[3], counterDraw[2]};
				drawDone <= 1'b0;
				end
		end
	end
	
	
	//assign colour = color;
    
endmodule



module control(
    input clk,
    input resetn,
    input black,
    input blackDone,
    input drawDone,
    output reg writeEn,
    input ld,
    input draw,
    output reg  ld_x, ld_y, blackEn,oDone
    );

    reg [2:0] current_state, next_state; 
    
    localparam  S_LOAD_x        = 3'd0,
                S_LOAD_x_wait   = 3'd1,
                S_LOAD_y        = 3'd2,
                S_LOAD_y_wait   = 3'd3,
                Drawing		= 3'd4,
		//S_Black_wait    = 3'd5,
		S_Black		= 3'd5,
    		Done = 3'd6;
    
    always@(*)
    begin: state_table 
            case (current_state)
                
				S_LOAD_x: 
				if(black)
					next_state = S_Black; //allows to black screen at every stage
				else 
					next_state = ld ? S_LOAD_x_wait : S_LOAD_x; //if w=1, move to s_load_x_wait, else stay as s_load_x
				S_LOAD_x_wait: 
				if(black)
					next_state = S_Black;
				else
					next_state = ld ? S_LOAD_x_wait:S_LOAD_y;
				S_LOAD_y: 
				if(black)
					next_state = S_Black;
				else
					next_state = draw ? S_LOAD_y_wait : S_LOAD_y;
				S_LOAD_y_wait: 
				if(black)
					next_state = S_Black;
				else
					next_state = draw ? S_LOAD_y_wait : Drawing;
				Drawing: 
				if(black)
					next_state = S_Black;
				else
					next_state = drawDone ? Done : Drawing;
				Done:
				if(black)
					next_state = S_Black;
				else 
					next_state = ld ? S_LOAD_x : Done;
				
				//S_Black_wait: next_state = black ? S_Black_wait : S_Black;
				S_Black: next_state = blackDone ? Done : S_Black;
				
        endcase
    end 
   

    
    always @(*)
    begin: enable_signals //nothhing is turned on yet, just initialize
        ld_x = 1'b0;
        ld_y = 1'b0;
		  //ld_c = 1'b0;
		  blackEn = 1'b0;
		writeEn = 1'b0;
		oDone = 1'b0;
        case (current_state)
            S_LOAD_x: begin
                ld_x=1'b1;
				//ld_c = 1'b0;
				end
            //S_LOAD_x_wait: begin
                //ld_x=1'b1;
				//ld_c = 1'b0;
                //end
            S_LOAD_y: begin
                ld_y=1'b1;
		//ld_c = 1'b1;
                end
            //S_LOAD_y_wait: begin
                //ld_y=1'b1;
				//ld_c = 1'b0;
                //end
            Drawing: begin
				//ld_c = 1'b1;
				writeEn = 1'b1;
		     end
	    S_Black: begin
				blackEn = 1'b1;
				end
	    //S_Black_wait: begin
				//blackEn = 1'b1;
			//end
	    Done:
		begin
		oDone = 1'b1;
		writeEn = 1'b0;
		end
	endcase
    end 
   
    
    always@(posedge clk)
    begin: state_FFs
        if(!resetn) begin
            current_state <= S_LOAD_x;
		end
        else
            current_state <= next_state;
    end 
    always @(posedge clk)
	begin
	if(!resetn)
		oDone <=1'b0;
	else if(black)
		oDone <=1'b0;
    end
endmodule
