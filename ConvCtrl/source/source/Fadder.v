/* Name: Suhas Sunil Raut    SJSU ID: 011432980
   Verilog Code For IEEE 754 Single Precision (32 bit) Floating Point Adder
   
   This is a reduced complexity floating point adder.   
   NaN, overflow, underflow and infinity values not processed
   
   Format for IEEE 754 SP FP:
   S    Exp     Mantissa
   31   30:23   22:0     

   Note: Number = 0 for exp=0 and mantissa=0
*/

`timescale 1ns/10ps

module Fadder(input Clk, input Rst, input Valid, input [31:0]Number1, input [31:0]Number2, output [31:0]Result, output Ready);
    
    reg    [31:0] Num_shift_80,Num_shift_pipe2_80; 
    reg    [7:0]  Larger_exp_80,Larger_exp_pipe1_80,Larger_exp_pipe2_80,Larger_exp_pipe3_80,Larger_exp_pipe4_80,Larger_exp_pipe5_80,Final_expo_80;
    reg    [22:0] Small_exp_mantissa_80,Small_exp_mantissa_pipe2_80,S_exp_mantissa_pipe2_80,S_exp_mantissa_pipe3_80,Small_exp_mantissa_pipe3_80;
    reg    [22:0] S_mantissa_80,L_mantissa_80;
    reg    [22:0] L1_mantissa_pipe2_80,L1_mantissa_pipe3_80,Large_mantissa_80,Final_mant_80;
    reg    [22:0] Large_mantissa_pipe2_80,Large_mantissa_pipe3_80,S_mantissa_pipe4_80,L_mantissa_pipe4_80;
    reg    [23:0] Add_mant_80,Add1_mant_80,Add_mant_pipe5_80;
    reg    [7:0]  e1_80,e1_pipe1_80,e1_pipe2_80,e1_pipe3_80,e1_pipe4_80,e1_pipe5_80;
    reg    [7:0]  e2_80,e2_pipe1_80,e2_pipe2_80,e2_pipe3_80,e2_pipe4_80,e2_pipe5_80;
    reg    [22:0] m1_80,m1_pipe1_80,m1_pipe2_80,m1_pipe3_80,m1_pipe4_80,m1_pipe5_80;
    reg    [22:0] m2_80,m2_pipe1_80,m2_pipe2_80,m2_pipe3_80,m2_pipe4_80,m2_pipe5_80;

    reg           s1_80,s2_80,Final_sign_80,s1_pipe1_80,s1_pipe2_80,s1_pipe3_80,s1_pipe4_80,s1_pipe5_80;
    reg           s2_pipe1_80,s2_pipe2_80,s2_pipe3_80,s2_pipe4_80,s2_pipe5_80;
    reg    [3:0]     renorm_shift_80,renorm_shift_pipe5_80;
	reg           valid_pipe2, valid_pipe3, valid_pipe4, valid_pipe5;
    //integer signed   renorm_exp_80;
	reg    [3:0]  renorm_exp_80,renorm_exp_pipe5_80;
	reg           renorm_sgn_80,renorm_sgn_pipe5_80;

    //:w
    //reg    [3:0]  renorm_exp_80,renorm_exp_pipe5_80;
    reg    [31:0] Result_80;

    assign Result = Result_80;

    always @(*) begin
        ///////////////////////// Combinational stage1 ///////////////////////////
	e1_80 = Number1[30:23];
	e2_80 = Number2[30:23];
        m1_80 = Number1[22:0];
	m2_80 = Number2[22:0];
	s1_80 = Number1[31];
	s2_80 = Number2[31];
        
        if (e1_80  > e2_80) begin
            Num_shift_80           = e1_80 - e2_80;              // determine number of mantissa shift
            Larger_exp_80           = e1_80;                     // store higher exponent
            Small_exp_mantissa_80  = m2_80;
            Large_mantissa_80      = m1_80;
        end 
        else begin
            Num_shift_80           = e2_80 - e1_80;
            Larger_exp_80           = e2_80;
            Small_exp_mantissa_80  = m1_80;
            Large_mantissa_80      = m2_80;
        end

	if (e1_80 == 0 || e2_80 ==0) begin
	    Num_shift_80 = 0;
	end
	else begin
	    Num_shift_80 = Num_shift_80;
	end	
        ///////////////////////// Combinational stage2 ///////////////////////////
        //right shift mantissa of smaller exponent
	if (e1_pipe2_80 != 0 && e2_pipe2_80 != 0) begin
            S_exp_mantissa_pipe2_80  = {1'b1,Small_exp_mantissa_pipe2_80[22:1]};
	    S_exp_mantissa_pipe2_80  = (S_exp_mantissa_pipe2_80 >> Num_shift_pipe2_80);
        end
	else begin
	    S_exp_mantissa_pipe2_80 = Small_exp_mantissa_pipe2_80;
	end

	if (e1_pipe2_80 != 0 || e2_pipe2_80 != 0) begin
            L1_mantissa_pipe2_80      = {1'b1,Large_mantissa_pipe2_80[22:1]};
	end
	else begin
	    L1_mantissa_pipe2_80 = Large_mantissa_pipe2_80;
	end
        ///////////////////////// Combinational stage3 ///////////////////////////
	//compare which is smaller mantissa
        if (S_exp_mantissa_pipe3_80  < L1_mantissa_pipe3_80) begin
                S_mantissa_80 = S_exp_mantissa_pipe3_80;
		L_mantissa_80 = L1_mantissa_pipe3_80;
        end
        else begin 
		S_mantissa_80 = L1_mantissa_pipe3_80;
		L_mantissa_80 = S_exp_mantissa_pipe3_80;
        end       
	///////////////////////// Combinational stage4 ///////////////////////////      
        //add the two mantissa's
	if (e1_pipe4_80!=0 && e2_pipe4_80!=0) begin
		if (s1_pipe4_80 == s2_pipe4_80) begin
        		Add_mant_80 = S_mantissa_pipe4_80 + L_mantissa_pipe4_80;
		end else begin
			Add_mant_80 = L_mantissa_pipe4_80 - S_mantissa_pipe4_80;
		end
	end	
	else begin
		Add_mant_80 = L_mantissa_pipe4_80;
	end      
	//determine shifts for renormalization for mantissa and exponent
	if (Add_mant_80[23]) begin
		renorm_shift_80 = 4'd1;
		renorm_exp_80 = 1;
		renorm_sgn_80 = 0;
	end
	else if (Add_mant_80[22])begin
		renorm_shift_80 = 4'd2;
		renorm_exp_80 = 0;	
		renorm_sgn_80 = 0;	
	end
	else if (Add_mant_80[21])begin
		renorm_shift_80 = 4'd3; 
		renorm_exp_80 = 1;
		renorm_sgn_80 = 1;
	end 
	else if (Add_mant_80[20])begin
		renorm_shift_80 = 4'd4; 
		renorm_exp_80 = 2;
		renorm_sgn_80 = 1;		
	end  
	else if (Add_mant_80[19]) begin
		renorm_shift_80 = 4'd5; 
		renorm_exp_80 = 3;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[18]) begin
		renorm_shift_80 = 4'd6; 
		renorm_exp_80 = 4;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[17]) begin
		renorm_shift_80 = 4'd7; 
		renorm_exp_80 = 5;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[16]) begin
		renorm_shift_80 = 4'd8; 
		renorm_exp_80 = 6;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[15]) begin
		renorm_shift_80 = 4'd9;
		renorm_exp_80 = 7;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[14]) begin
		renorm_shift_80 = 4'd10;
		renorm_exp_80 = 8;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[13]) begin
		renorm_shift_80 = 4'd11;
		renorm_exp_80 = 9;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[12]) begin
		renorm_shift_80 = 4'd12;
		renorm_exp_80 = 10;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[11]) begin
		renorm_shift_80 = 4'd13;
		renorm_exp_80 = 11;
		renorm_sgn_80 = 1;
	end
	else if (Add_mant_80[10]) begin
		renorm_shift_80 = 4'd14;
		renorm_exp_80 = 12;
		renorm_sgn_80 = 1;
	end
	else begin
		renorm_shift_80 = 4'd15;
		renorm_exp_80 = 0;
		renorm_sgn_80 = 0;
	end
        
	///////////////////////// Combinational stage5 /////////////////////////////
	//Shift the mantissa as required; re-normalize exp; determine sign
    if (renorm_shift_pipe5_80 < 15) begin
		Final_expo_80 =  (renorm_sgn_pipe5_80)? (Larger_exp_pipe5_80 - renorm_exp_pipe5_80) : (Larger_exp_pipe5_80 + renorm_exp_pipe5_80);
		if (renorm_shift_pipe5_80 != 0) begin	
			Add1_mant_80 = Add_mant_pipe5_80 << renorm_shift_pipe5_80;
		end
		else begin
			Add1_mant_80 = Add_mant_pipe5_80;
		end
		Final_mant_80 = Add1_mant_80[23:1];  	      
		if (s1_pipe5_80 == s2_pipe5_80) begin
			Final_sign_80 = s1_pipe5_80;
		end
		else if (e1_pipe5_80 > e2_pipe5_80) begin
			Final_sign_80 = s1_pipe5_80;	
		end
		else if (e2_pipe5_80 > e1_pipe5_80) begin
			Final_sign_80 = s2_pipe5_80;
		end
		else begin
			if (m1_pipe5_80 > m2_pipe5_80) begin
				Final_sign_80 = s1_pipe5_80;		
			end
			else begin
				Final_sign_80 = s2_pipe5_80;
			end
		end	
		Result_80 = {Final_sign_80,Final_expo_80,Final_mant_80}; 
	end
	else begin
		Result_80 = 0;
	end
    end
    
    always @(posedge Clk) begin
            if(Rst) begin                           //Rst all reg at Rst signal
                s1_pipe2_80 <=   0;
		s2_pipe2_80 <=   0;
		e1_pipe2_80 <=   0;
		e2_pipe2_80 <=   0;	
		m1_pipe2_80 <=   0;
		m2_pipe2_80 <=   0;
		Larger_exp_pipe2_80 <=   0;
		valid_pipe2 <= 0;
		//stage2
		Small_exp_mantissa_pipe2_80 <=   0;
	        Large_mantissa_pipe2_80     <=   0;
		Num_shift_pipe2_80          <=   0;
		s1_pipe3_80 <=   0;
		s2_pipe3_80 <=   0;
		e1_pipe3_80 <=   0;
		e2_pipe3_80 <=   0;	
		m1_pipe3_80 <=   0;
		m2_pipe3_80 <=   0;
		Larger_exp_pipe3_80 <=   0; 
		valid_pipe3 <= 0;

		s1_pipe4_80 <=   0;
		s2_pipe4_80 <=   0;
		e1_pipe4_80 <=   0;
		e2_pipe4_80 <=   0;	
		m1_pipe4_80 <=   0;
		m2_pipe4_80 <=   0;
		Larger_exp_pipe4_80 <=  0; 
		valid_pipe4 <= 0;

		s1_pipe5_80 <=   0;
		s2_pipe5_80 <=   0;
		e1_pipe5_80 <=   0;
		e2_pipe5_80 <=   0;	
		m1_pipe5_80 <=   0;
		m2_pipe5_80 <=   0;
		Larger_exp_pipe5_80 <= 0; 
		valid_pipe5 <= 0;
		//stage3	
		S_exp_mantissa_pipe3_80  <= 0;
	       	L1_mantissa_pipe3_80     <= 0;
		//stage4
		S_mantissa_pipe4_80       <= 0;
		L_mantissa_pipe4_80       <= 0;	
		//stage5	
		Add_mant_pipe5_80 <= 0;
		renorm_shift_pipe5_80 <= 0;
		renorm_exp_pipe5_80 <= 0;
		renorm_sgn_pipe5_80 <= 0;

            end
	    else begin        
		///////////////////////////////PIPELINE STAGES and VARIABLES/////////////////
         	//propogate pipelined variables to next stages
		s1_pipe2_80 <=   s1_80;
		s2_pipe2_80 <=   s2_80;
		e1_pipe2_80 <=   e1_80;
		e2_pipe2_80 <=   e2_80;	
		m1_pipe2_80 <=   m1_80;
		m2_pipe2_80 <=   m2_80;
		Larger_exp_pipe2_80 <=   Larger_exp_80;
		valid_pipe2 <= 	 Valid;
		//stage2
		Small_exp_mantissa_pipe2_80 <=   Small_exp_mantissa_80;
	        Large_mantissa_pipe2_80     <=   Large_mantissa_80;
		Num_shift_pipe2_80          <=   Num_shift_80;
		s1_pipe3_80 <=   s1_pipe2_80;
		s2_pipe3_80 <=   s2_pipe2_80;
		e1_pipe3_80 <=   e1_pipe2_80;
		e2_pipe3_80 <=   e2_pipe2_80;	
		m1_pipe3_80 <=   m1_pipe2_80;
		m2_pipe3_80 <=   m2_pipe2_80;
		Larger_exp_pipe3_80 <=   Larger_exp_pipe2_80; 
		valid_pipe3 <= 	 valid_pipe2;

		s1_pipe4_80 <=   s1_pipe3_80;
		s2_pipe4_80 <=   s2_pipe3_80;
		e1_pipe4_80 <=   e1_pipe3_80;
		e2_pipe4_80 <=   e2_pipe3_80;	
		m1_pipe4_80 <=   m1_pipe3_80;
		m2_pipe4_80 <=   m2_pipe3_80;
		Larger_exp_pipe4_80 <=   Larger_exp_pipe3_80; 
		valid_pipe4 <= 	 valid_pipe3;

		s1_pipe5_80 <=   s1_pipe4_80;
		s2_pipe5_80 <=   s2_pipe4_80;
		e1_pipe5_80 <=   e1_pipe4_80;
		e2_pipe5_80 <=   e2_pipe4_80;	
		m1_pipe5_80 <=   m1_pipe4_80;
		m2_pipe5_80 <=   m2_pipe4_80;
		Larger_exp_pipe5_80 <=   Larger_exp_pipe4_80; 
		valid_pipe5 <= 	 valid_pipe4;
		//stage3	
		S_exp_mantissa_pipe3_80  <= S_exp_mantissa_pipe2_80;
	       	L1_mantissa_pipe3_80     <= L1_mantissa_pipe2_80;
		//stage4
		S_mantissa_pipe4_80         <=   S_mantissa_80;
		L_mantissa_pipe4_80         <=   L_mantissa_80;	
		//stage5	
		Add_mant_pipe5_80 <= Add_mant_80;
		renorm_shift_pipe5_80 <= renorm_shift_80;
		renorm_exp_pipe5_80 <= renorm_exp_80;	
		renorm_sgn_pipe5_80 <= renorm_sgn_80;	
	   end
    end

	assign Ready = valid_pipe5;
    
endmodule
