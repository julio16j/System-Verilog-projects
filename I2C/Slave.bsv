module slave(S_CLK_E, S_RST, S_ADDR, S_DATA_IN, S_DATA_OUT, S_DATA_OUT_ENB, S_ACTIVE, S_SCL, S_SDA);
  
  input logic S_CLK_E, S_RST;
  input logic [6:0] S_ADDR;
  input logic S_SCL ;
  input logic [7:0] S_DATA_IN;
  inout S_SDA;
  
  output logic S_ACTIVE = 0, S_DATA_OUT_ENB = 0;
  output logic [7:0] S_DATA_OUT;
  

  
  logic [3:0] delay = 0;
  
  logic [3:0] fecha = 0;
  
  logic abra = 0;
  
  logic S_CLK_IN = 0;
  
  logic S_SETUP_real;
  
  logic contador = 0;
  
  int contador_frequencia = 0;

  logic ACK = 0;
  
  logic Negedge_SDA = 1;
  
  logic Negedge = 0;
  
  logic [4:0] pulso = 1;
  
  logic controle_S_SDA = 0;
  
  logic S_SDA_wire = 0;
  
  logic [3:0] estado = 0;
  
  logic [7:0] aux;
  
  logic [3:0] indice = 8;
  
  logic [1:0] dados_transmitidos = 0;
  
  
  assign S_SDA = controle_S_SDA ? S_SDA_wire : 8'bz;
  
  parameter endereco   = 7'b0110101,
  			idle       = 3'd0,
  			Addr       = 3'd1,
  			ACK_R      = 3'd2,
  			ACK_W      = 3'd3,
  			leitura    = 3'd4,
  			escrita    = 3'd5,
  			ACK_DATA_R = 3'd6,
  			ACK_DATA_W = 3'd7,
  			espera = 4'd8;
  always @(posedge S_CLK_E) begin
    if(contador_frequencia == 5) begin 
      S_CLK_IN++;
      contador_frequencia = 0;
    end
    else contador_frequencia++;
  end

  always@(S_CLK_IN)begin
    case(estado)
      idle:	begin
        contador = 0;
        case(pulso)
            1: begin
              
              indice = 9;
              S_ACTIVE = 0;
              if (S_SCL)begin 
                pulso = 2;
              end
            end
          2:  begin
            if(Negedge_SDA) begin
              Negedge_SDA = 0;
              estado = Addr;
                S_ACTIVE = 1;
                pulso = 1;
            end
          end
        endcase
      end

      Addr: begin
        case (pulso)
          1: if (Negedge) pulso = 2;
          2: pulso = 3;
          3: pulso = 4;
          4: pulso = 5;
          5: begin
            indice--;
            aux[indice-1] = S_SDA;
            Negedge = 0;
            pulso = 1;
            if(indice == 1) begin
              if(aux[7:1] != S_ADDR && aux != 8'b00000000) estado = idle;
              else begin
                indice = 9;
                if(aux[0] == 0) estado = ACK_R;
                else if(aux[0] == 1) estado = ACK_W;
              end
            end
          end
          6: pulso = 1;
          endcase
      end

      ACK_R: begin
        case(pulso)
          1: if(Negedge) pulso = 2;
          2: pulso = 3;
          3: pulso = 4;
          4: begin
            if ( contador == 0) begin
              pulso = 5;
              contador = 0;
            end
            else contador++;
          end
          5: begin 
            Negedge = 0;
            controle_S_SDA = 1;
            pulso = 6;
          end
          6: pulso = 7;
          7: pulso = 8;
          8: begin
            controle_S_SDA = 0;
            indice = 9;
            pulso = 1;
            estado = leitura;
          end
        endcase
      end

      ACK_W: begin
        case(pulso)
          1: if(Negedge) pulso = 2;
          2: pulso = 3;
          3: pulso = 4;
          4: begin
              Negedge = 0;
              pulso = 5;
          end
          5:begin 
              pulso = 8;
              controle_S_SDA = 1;
          end
          6: pulso = 7;
          7: pulso = 8;
          8: pulso = 9;
          9: pulso = 10;
          10:pulso = 11;
          11: begin
            indice = 9;
            pulso = 1;
            estado = escrita;
          end
        endcase
      end

      leitura: begin
        case (pulso)
          1: begin
              if (Negedge)
              pulso = 2;
          end
          2: pulso = 3;
          3: pulso = 4;
          4: pulso = 5;
          5:begin
            indice--;
            S_DATA_OUT[indice-1] = S_SDA;
            Negedge = 0;
            pulso = 1;
            if(indice == 1) begin
                indice = 9;
                if(aux[0] == 0) estado = ACK_DATA_R;
                else if(aux[0] == 1) estado = ACK_DATA_W;
            end
          end
          6: pulso = 1;
        endcase
      end
    
      escrita: begin
        case(pulso)
          1: if(Negedge) pulso = 2;
          2: begin
            controle_S_SDA = 1;
            pulso = 3;
          end
          3: begin
            indice--;
            if(indice!= 0) S_SDA_wire = S_DATA_IN[indice-1];
            pulso = 4;
          end
          4: begin
            Negedge = 0;
            if(indice == 0) estado = ACK_DATA_W;
            pulso = 1;
          end
        endcase
      end
      
      ACK_DATA_R: begin
        case(pulso)
          1: if(Negedge) pulso = 2;
          2: begin 
            S_SDA_wire = ACK;
            pulso = 3;
            contador = 0;
          end
          3: pulso = 4;
          4: pulso = 5;
          5: pulso = 6;
          6: pulso = 7;
          7: pulso = 8;
          8: pulso = 9;
          9: pulso = 10;
          10: begin 
            controle_S_SDA = 1;
            pulso = 11;
          end
          11: begin
            Negedge = 0;
            pulso = 12;
          end
          12: pulso = 13;
          13: pulso = 14;
          14: begin
            pulso = 1;
            controle_S_SDA = 0;
            indice = 9;
            estado = espera;
          end
        endcase
      end
      
      ACK_DATA_W: begin
        case (pulso)
          1: begin
            dados_transmitidos ++;
            S_DATA_OUT_ENB = 1;
            S_SDA_wire = 1;
            pulso = 2;
          end 
          2: begin
            S_DATA_OUT_ENB = 0;
            controle_S_SDA = 0;
            pulso = 3;
          end
          3: begin
            if (S_SDA == 0) begin
              estado = espera;
              pulso = 1;
            end
            else pulso = 4;
          end
          4: begin
            if (S_SDA == 0) begin
              estado = espera;
              pulso = 1;
            end
            else pulso = 5;
          end
          5: begin
            if (S_SDA == 0) begin
            estado = espera;
              pulso = 1;
            end
            else pulso = 6;
          end
          6: begin
            if (S_SDA == 0) begin
              estado = espera;
              pulso = 1;
            end
            else pulso = 7;
          end
          7: pulso = 8;
          8: begin
            controle_S_SDA = 1;
            pulso = 1;
            estado = idle;
          end
        endcase
      end

      espera: begin
        case(pulso)
          1: begin 
            if(dados_transmitidos == 2) estado = idle;
            pulso = 2;
          end
          2:pulso = 3;
          3:pulso = 4;
          4:pulso = 5;
          5:pulso = 6;
          6:pulso = 7;
          7:pulso = 8;
          8: begin
            pulso = 1;
          end
        endcase
      end
    endcase
  end
  always@(posedge S_RST) begin
    S_SDA_wire = 0;
    dados_transmitidos = 0;
    indice = 9;
    estado = idle;
    pulso = 1;
  end
  always@(negedge S_SDA) begin
    if(estado == idle &&pulso == 2)
    	Negedge_SDA = 1;
    if(estado == espera && S_SCL) begin
      if (aux[0] && dados_transmitidos<2) begin
        Negedge = 0;
        estado = escrita;
        indice = 9;
        pulso = 1;
      end
      else if(!aux[0]) begin 
        estado = leitura;
        indice = 9;
        pulso = 1;
      end
    end
  end
  always@(posedge S_SDA) begin
    if(estado == espera && S_SCL) begin
             dados_transmitidos = 0;
      		 estado = idle;
             pulso = 1;
          end
        end
  always@(negedge S_SCL) Negedge = 1;
endmodule
  
