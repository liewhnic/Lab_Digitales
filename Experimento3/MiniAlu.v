`timescale 1ns / 1ps
`include "Defintions.v"


module MiniAlu
(

 // Entradas del módulo.
 input wire        Clock,
 input wire        Reset,

 // Salidas del módulo. Salidas de la LCD.
 output wire [3:0] oLCD,
 output reg        oReadWrite,
 output reg        oRegisterSelect,
 output wire       oEnable

);

wire [15:0]  wIP,wIP_temp;
reg         rWriteEnable,rBranchTaken;
wire [27:0] wInstruction;
wire [3:0]  wOperation;
reg signed [15:0]   rResult;
wire signed [7:0] wSourceAddr0,wSourceAddr1;
wire [7:0] wDestination;
wire [15:0] wSourceData0,wSourceData1,wIPInitialValue,wImmediateValue;

assign oReadWrite = 1'b0; //Sólo se lee de la LCD, nunca se escribe a ella.


ROM InstructionRom
(
	.iAddress(     wIP          ),
	.oInstruction( wInstruction )
);

RAM_DUAL_READ_PORT DataRam
(
	.Clock(         Clock        ),
	.iWriteEnable(  rWriteEnable ),
	.iReadAddress0( wInstruction[7:0] ),
	.iReadAddress1( wInstruction[15:8] ),
	.iWriteAddress( wDestination ),
	.iDataIn(       rResult      ),
	.oDataOut0(     wSourceData0 ),
	.oDataOut1(     wSourceData1 )
);

assign wIPInitialValue = (Reset) ? 8'b0 : wDestination;
UPCOUNTER_POSEDGE IP
(
.Clock(   Clock                ),
.Reset(   Reset | rBranchTaken ),
.Initial( wIPInitialValue + 1  ),
.Enable(  1'b1                 ),
.Q(       wIP_temp             )
);

assign wIP = (rBranchTaken) ? wIPInitialValue : wIP_temp;

FFD_POSEDGE_SYNCRONOUS_RESET # ( 8 ) FFD1
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[27:24]),
	.Q(wOperation)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( 8 ) FFD2
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[7:0]),
	.Q(wSourceAddr0)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( 8 ) FFD3
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[15:8]),
	.Q(wSourceAddr1)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( 8 ) FFD4
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[23:16]),
	.Q(wDestination)
);

// Flip-Flop de la LCD.
reg rFFLCD_EN, rEnable, rRegisterSelect;
FFD_POSEDGE_SYNCRONOUS_RESET # ( 8 ) FF_LEDS
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable( rFFLCD_EN ),
	.D( {3'b0, rEnable, wSourceData1[7:4]} ),
        .Q( { 3'b0, oEnable, oLCD})
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( 8 )
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(rCall_Addrs),
	.Q(wCall_Addrs)
);

   assign rEnable = 1'b1;
   assign wImmediateValue = {wSourceAddr1,wSourceAddr0};



always @ ( * )
begin
	case (wOperation)
	//-------------------------------------
	`NOP:
	begin
		rFFLCD_EN     <= 1'b0;
		rBranchTaken <= 1'b0;
		rWriteEnable <= 1'b0;
		rResult      <= 0;
	end
	//-------------------------------------
	`ADD:
	begin
		rFFLCD_EN     <= 1'b0;
		rBranchTaken <= 1'b0;
		rWriteEnable <= 1'b1;
		rResult   <= wSourceData1 + wSourceData0;
	end
        //-------------------------------------
	`SUB:
	begin
		rFFLCD_EN     <= 1'b0;
		rBranchTaken <= 1'b0;
		rWriteEnable <= 1'b1;
		rResult   <= wSourceData1 - wSourceData0;
	end
        //-------------------------------------

	`MUL:
	begin
		rFFLCD_EN     <= 1'b0;
		rBranchTaken <= 1'b0;
		rWriteEnable <= 1'b1;
		rResult   <= wSourceData1 * wSourceData0;
               	end
	//-------------------------------------
	`STO:
	begin
		rFFLCD_EN     <= 1'b0;
		rWriteEnable <= 1'b1;
		rBranchTaken <= 1'b0;
		rResult      <= wImmediateValue;
	end
	//-------------------------------------
	`BLE:
	begin
		rFFLCD_EN     <= 1'b0;
		rWriteEnable <= 1'b0;
		rResult      <= 0;
		if (wSourceData1 <= wSourceData0 )
			rBranchTaken <= 1'b1;
		else
			rBranchTaken <= 1'b0;

	end
	//-------------------------------------
	`JMP:
	begin
		rFFLCD_EN     <= 1'b0;
		rWriteEnable <= 1'b0;
		rResult      <= 0;
		rBranchTaken <= 1'b1;
	end
	//-------------------------------------
          // Escribe un NIBBLE en la LCD.
	`LCD:
	begin
           rFFLCD_EN     <= 1'b1;
           rWriteEnable <= 1'b0;
           rResult      <= 0;
           rRegisterSelect <= wSourceData0;
           rBranchTaken <= 1'b0;
	end
	//-------------------------------------
          // Corre los bits del registro en 8 bits.
	`SHL:
	begin
		rFFLCD_EN     <= 1'b0;
		rWriteEnable <= 1'b1;
		rResult   <= wSourceData1 >> wSourceData0;
		rBranchTaken <= 1'b0;
	end
	//-------------------------------------
       `CALL:
	begin
		rFFLCD_EN     <= 1'b0;
		rWriteEnable <= 1'b0;
		rResult   <= 1'b0;
		rBranchTaken <= 1'b1;
	end
	//-------------------------------------
        `RET:
	begin
		rFFLCD_EN     <= 1'b0;
		rWriteEnable <= 1'b0;
		rResult   <= wSourceData1 << wSourceData0;
		rBranchTaken <= 1'b0;
	end
	//-------------------------------------
	default:
	begin
		rFFLCD_EN     <= 1'b1;
		rWriteEnable <= 1'b0;
		rResult      <= 0;
		rBranchTaken <= 1'b0;
	end
	//-------------------------------------
	endcase
end


endmodule
