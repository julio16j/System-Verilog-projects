module master(M_CLK_E, M_RST, M_ADDR, M_DATA_OUT, M_DATA_IN, M_RW, M_RW_ENB, M_ACTIVE, 
              M_RETURN, M_SETUP, SDA, SCL);
  
  inout SDA;
  input logic [6:0] M_ADDR;
  input logic M_CLK_E, M_RW, M_RW_ENB;
  input logic [7:0] M_DATA_IN;
  input logic [7:0] M_SETUP;
  input logic M_RST;
  
  output logic M_RETURN;
  output logic M_ACTIVE;
  output logic SCL = 1;
  output logic [7:0] M_DATA_OUT = 8'hFF;
  
  logic CLK_IN = 0;
  int setup_contador = 0;
  logic [7:0] Setup_real;
  logic Restart = 0;
  logic Pula = 0;
  logic SDA_OUT = 1, SDA_IN, CTRL_MASTER = 1, ACK = 0;
  assign SDA_IN = SDA;
  assign SDA = CTRL_MASTER ? SDA_OUT : 1'bZ;
  
  int i = 7, SMALL_STATE = 1;
  int ATUAL = 0;
  localparam IDLE = 0, START = 1, ADRRESS = 2, ACK_ADDR = 3, STOP=4, 
  			 DATA_WRITE = 5, 
  			 ACK_WRITE = 6, DATA_READ = 7, ACK_MASTER = 8, TIMEOUT = 9;
  always @(posedge M_RST) begin
    ATUAL = IDLE;
  end
  
  always @(posedge M_CLK_E) begin
    if(setup_contador == M_SETUP) begin 
    	CLK_IN++;
      	setup_contador = 0;
   	end
    else setup_contador++;
  end
  always @(posedge CLK_IN) begin
    
    case(ATUAL)
      IDLE: begin
        i = 7;
        SDA_OUT = 1;
        SCL = 1;
        M_ACTIVE = 0;
      end
      START: begin
        case (SMALL_STATE)
          1: begin
            SCL = 1;
            SMALL_STATE = 2;
          end
          2: begin
            SMALL_STATE = 3;
          end
          3: begin
            SMALL_STATE = 4;
          end
          4: begin
            SDA_OUT = 0;
            SMALL_STATE = 5;
          end
          5: begin
            SMALL_STATE = 6;
          end
          6: begin
            SMALL_STATE = 7;
          end
          7: begin
            SMALL_STATE = 8;
          end
          8: begin
            SCL = 0;
            SMALL_STATE = 1;
            ATUAL = ADRRESS;
            i = 7;
          end
        endcase
      end
      ADRRESS: begin
        case (SMALL_STATE)
          1: begin
            if(i != 0) SDA_OUT = M_ADDR[i-1];
            else SDA_OUT = M_RW;
            SMALL_STATE = 2;
          end
          2: begin
            SMALL_STATE = 3;
          end
          3: begin
            SMALL_STATE = 4;
          end
          4: begin
            SMALL_STATE = 5;
          end
          5: begin
            SMALL_STATE = 6;
          end
          6: begin
            
            SMALL_STATE = 7;
          end
          7: begin
            SCL = 1;
            i --;
            SMALL_STATE = 8;
          end
          8: begin
            SCL = 0;
            SMALL_STATE = 1;
            if (i == -1) begin
              i = 9;
              ATUAL = ACK_ADDR;
              
            end
          end
        endcase
      end
      ACK_ADDR: begin
        case (SMALL_STATE)
          1: begin
            SDA_OUT = 1;
            SMALL_STATE = 2;
          end
          2: begin
            CTRL_MASTER = 0;
            SMALL_STATE = 3;
          end
          3: begin
            if (SDA_IN == 0) begin
              if (M_RW) begin
                 ATUAL = DATA_READ;
              	 SMALL_STATE = 1;
              end
              else  begin
                 ATUAL = DATA_WRITE;
                 SMALL_STATE = 1;
              end
            end
            else SMALL_STATE = 4;
          end
          4: begin
            if (SDA_IN == 0) begin
              if (M_RW) begin
                 ATUAL = DATA_READ;
                 SMALL_STATE = 1;
              end
          
              else begin
                SMALL_STATE = 1; 
                ATUAL = DATA_WRITE;
              end
            end
            else SMALL_STATE = 5;
          end
          5: begin
           if (SDA_IN == 0) begin
             if (M_RW) begin
                 SMALL_STATE = 1; 
                 ATUAL = DATA_READ;
             end
          
              else begin
                 SMALL_STATE = 1; 
                 ATUAL = DATA_WRITE;
              end
            end
            else SMALL_STATE = 6;
          end
          6: begin
           	if (SDA_IN == 0) begin
              if (M_RW) begin
                 SMALL_STATE = 1; 
                 ATUAL = DATA_READ;
              end
          
              else begin
                 SMALL_STATE = 1; 
                 ATUAL = DATA_WRITE;
                 Pula = 0;
              end
            end
            else SMALL_STATE = 7;
          end
          7: begin
            SCL = 1;
            
            SMALL_STATE = 8;
          end
          8: begin
            SCL = 0;
            CTRL_MASTER = 1;
            SMALL_STATE = 1;
            
            M_RETURN = 1;
            ATUAL = STOP;
          end
        endcase
      end
      STOP: begin
        case (SMALL_STATE)
          1: begin
            CTRL_MASTER = 1;
            SDA_OUT = 0;
            SMALL_STATE = 2;
          end
          2: begin
            SMALL_STATE = 3;
          end
          3: begin
            SCL = 1;
            SMALL_STATE = 4;
          end
          4: begin
            SMALL_STATE = 5;
          end
          5: begin
            SMALL_STATE = 6;
          end
          6: begin
            SMALL_STATE = 7;
          
          end
          7: begin
            SMALL_STATE = 8;
          end
          8: begin
            SMALL_STATE = 1;
            SDA_OUT = 1;
            ATUAL = IDLE;
          end
        endcase
      end
      DATA_WRITE: begin
        case (SMALL_STATE)
          1: begin
            SMALL_STATE = 2;
          end
          2: begin
            CTRL_MASTER = 1;
            SDA_OUT = 0;
            if (Pula != 0) begin
              i--;
              SDA_OUT = M_DATA_IN[i-1];
              
            end
            else Pula = 1;
            SMALL_STATE = 3;
          end
          3: begin
            SMALL_STATE = 4;
          end
          4: begin
            SMALL_STATE = 5;
          end
          5: begin
            SMALL_STATE = 6;
          end
          6: begin
            SMALL_STATE = 7;
          end
          7: begin
            SCL = 1;
            
            
            	
            SMALL_STATE = 8;
          end
          8: begin
            SCL = 0;
            if (i == 1) begin
              i = 9;
              ATUAL = ACK_WRITE;
            end
            SMALL_STATE = 1;
          end
        endcase
      end
      ACK_WRITE: begin
        case (SMALL_STATE)
          1: begin
            SDA_OUT = 1;
            SMALL_STATE = 2;
          end 
          2: begin
            CTRL_MASTER = 0;
            SMALL_STATE = 3;
          end
          3: begin
            if (SDA_IN == 0) begin
               ATUAL = TIMEOUT;
               SMALL_STATE = 1;
            end
            else SMALL_STATE = 4;
          end
          4: begin
            if (SDA_IN == 0) begin
             	ATUAL = TIMEOUT;
               SMALL_STATE = 1;
            end
            
            else SMALL_STATE = 5;
          end
          5: begin
           if (SDA_IN == 0) begin
             ATUAL = TIMEOUT;
               SMALL_STATE = 1;
            
            end
            else SMALL_STATE = 6;
          end
          6: begin
           	if (SDA_IN == 0) begin
              ATUAL = TIMEOUT;
               SMALL_STATE = 1;
            
            end
            else SMALL_STATE = 7;
          end
          7: begin
            SCL = 1;
            
            SMALL_STATE = 8;
          end
          8: begin
            SCL = 0;
            CTRL_MASTER = 1;
            SMALL_STATE = 1;
            
            M_RETURN = 1;
            ATUAL = STOP;
          
          
          
          end
        endcase
      end
      TIMEOUT:
        begin
        case(SMALL_STATE)
            1:begin
            SMALL_STATE = 2;
            end
            2:begin
            SMALL_STATE = 3;
            end
            3:begin
            SMALL_STATE = 4;
            end
            4:begin
            SMALL_STATE = 5;
            end
            5:begin
            SDA_OUT = 0;
            CTRL_MASTER = 1;
            SMALL_STATE = 6;
            end
            6:begin
            SMALL_STATE = 7;
            end
            7:begin
            SMALL_STATE = 8;
            end
            8:begin
            ATUAL = STOP;
            SMALL_STATE=1;
            end
        endcase
        end
      DATA_READ: begin
        case (SMALL_STATE)
          1: begin
            
           CTRL_MASTER = 0;
           SMALL_STATE = 2;
            
          end
          2: begin
            SMALL_STATE = 3;
          end
          3: begin
            SMALL_STATE = 4;
          end
          4: begin
            SMALL_STATE = 5;
          end
          5: begin
            SMALL_STATE = 6;
          end
          6: begin
            SCL = 1;
            i --;
            M_DATA_OUT[i] = SDA_IN;
            SMALL_STATE = 7;
          end
          7: begin
            
            SMALL_STATE = 8;
          end
          8: begin
           
            SCL = 0;
            if (i == 0) begin
              i = 8;
              ATUAL = ACK_MASTER;
            end
            SMALL_STATE = 1;
          end
        endcase
      end
      ACK_MASTER: begin
        case (SMALL_STATE)
          1: begin
            SDA_OUT = ACK;
            SMALL_STATE = 2;
          end
          2: begin
           
            SMALL_STATE = 3;
          end
          3: begin
            CTRL_MASTER = 1;
            SMALL_STATE = 4;
          end
          4: begin
            if (ACK == 1) M_RETURN = 1;
            
            SMALL_STATE = 5;
          end
          5: begin
            SCL = 1;
            SMALL_STATE = 6;
            end
         
          6: begin
            SMALL_STATE = 7;
          end
          7: begin
            SMALL_STATE = 8;
          end
          8: begin
            SCL = 0;
            SMALL_STATE = 4;
            ATUAL = TIMEOUT;
          end
        endcase
      end
    endcase
  end
  always @(posedge M_RW_ENB) begin
    if (ATUAL == IDLE) begin
      ATUAL = START;
      M_ACTIVE = 1;
    end
     
  end
endmodule


   