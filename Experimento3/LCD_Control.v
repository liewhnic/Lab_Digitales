`timescale 1ns / 1ps

`include "Defintions.v"

`define STATE_RESET              0
`define STATE_POWERON_INIT_0_A   1
`define STATE_POWERON_INIT_0_B   2
`define STATE_POWERON_INIT_1     3
`define STATE_POWERON_INIT_2_A   4
`define STATE_POWERON_INIT_2_B   5
`define STATE_POWERON_INIT_3     6
`define STATE_POWERON_INIT_4_A   7
`define STATE_POWERON_INIT_4_B   8
`define STATE_POWERON_INIT_5     9
`define STATE_POWERON_INIT_6_A   10
`define STATE_POWERON_INIT_6_B   11
`define STATE_POWERON_INIT_7     12
`define STATE_POWERON_INIT_8_A   13
`define STATE_POWERON_INIT_8_B   14
`define STATE_CONFIGURATION_9    15
`define STATE_CONFIGURATION_10_A 16
`define STATE_CONFIGURATION_10_B 17
`define STATE_CONFIGURATION_11   18
`define STATE_CONFIGURATION_12_A 19
`define STATE_CONFIGURATION_12_B 20
`define STATE_CONFIGURATION_13   21
`define STATE_CONFIGURATION_14_A 22
`define STATE_CONFIGURATION_14_B 23
`define STATE_CONFIGURATION_15   24
`define STATE_WRITE_PHRASE       25
`define STATE_CONFIGURATION_16   26
`define STATE_CONFIGURATION_17_A 27
`define STATE_CONFIGURATION_17_B 28

module Module_LCD_Control
  (
   input wire       Clock,
   input wire       Reset,
   output wire      oLCD_Enabled,
   output reg       oLCD_RegisterSelect, //0=Command, 1=Data
   output wire      oLCD_StrataFlashControl,
   output wire      oLCD_ReadWrite,
   output wire [3:0] oLCD_Data
   );

   reg              rWrite_Enabled;
   reg [1:0]        rWrite_Phrase;
   reg [7:0]        rCurrentState,rNextState;
   reg [31:0]       rTimeCount;
   reg              rTimeCountReset;
   wire             wWriteDone;
//   wire [3:0]            wLCD_Data;
   reg [79:0]       rData;

   assign oLCD_ReadWrite = 0; //I only Write to the LCD display, never Read from it
   assign oLCD_StrataFlashControl = 1; //StrataFlash disabled. Full read/write access to LCD



     Module_LCD_Writer LCD_Writer
(
 .Reset(rWrite_Enabled),
 .iData_NIBBLE(rData[3:0]),
 .iData_BYTE(rData[7:0]),
 .iData_Phrase(rData),
 .wWrite_Phrase(rWrite_Phrase),
 .Clock(Clock),
 .oWrite_Phrase_Done(wWriteDone),
 .oSender(oLCD_Data),
 .oEnable(oLCD_Enabled)
);

  initial  rWrite_Phrase = 2'd0;

   //----------------------------------------------
   //Next State and delay logic
   always @ ( posedge Clock )
     begin
        if (Reset)
          begin
             rCurrentState <= `STATE_RESET;
             rTimeCount <= 32'b0;
          end
        else
          begin
             if (rTimeCountReset)
               rTimeCount <= 32'b0;
             else
               rTimeCount <= rTimeCount + 32'b1;
             rCurrentState <= rNextState;
          end
     end
   //----------------------------------------------
   //Current state and output logic
   always @ ( * )
     begin
        case (rCurrentState)
          //------------------------------------------
          `STATE_RESET:
            begin
               rWrite_Enabled = 1'b0;
               rData = 80'h0;
               oLCD_RegisterSelect = 1'b0;
               rTimeCountReset = 1'b0;
               rNextState = `STATE_POWERON_INIT_0_A;
            end
          //------------------------------------------
          /*
           Wait 15 ms or longer.
           The 15 ms interval is 750,000 clock cycles at 50 MHz.
           */
          `STATE_POWERON_INIT_0_A:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h0;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
               if (rTimeCount > 32'd750000 )
                 rNextState = `STATE_POWERON_INIT_0_B;
               else
                 rNextState = `STATE_POWERON_INIT_0_A;
            end
          //------------------------------------------
          `STATE_POWERON_INIT_0_B:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h0;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1; //Reset the counter here
               rNextState = `STATE_POWERON_INIT_1;
            end
          //------------------------------------------
          /*
           Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
           */
          `STATE_POWERON_INIT_1:
            begin
               rWrite_Enabled = 1'b1;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_POWERON_INIT_2_A;
               else
                 rNextState = `STATE_POWERON_INIT_1;
            end
          //------------------------------------------
          /*
           Wait 4.1 ms or longer, which is 205,000 clock cycles at 50 MHz.
           */
          `STATE_POWERON_INIT_2_A:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
               if (rTimeCount > 32'd205000 )
                 rNextState = `STATE_POWERON_INIT_2_B;
               else
                 rNextState = `STATE_POWERON_INIT_2_A;
            end
          //------------------------------------------
          `STATE_POWERON_INIT_2_B:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_POWERON_INIT_3;
            end
          //------------------------------------------
           /*
           Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
           */
          `STATE_POWERON_INIT_3:
            begin
               rWrite_Enabled = 1'b1;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_POWERON_INIT_4_A;
               else
                 rNextState = `STATE_POWERON_INIT_3;
            end
          //------------------------------------------
          /*
           Wait 100 us or longer, which is 5,000 clock cycles at 50 MHz.
           */
          `STATE_POWERON_INIT_4_A:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
               if (rTimeCount > 32'd5000 )
                 rNextState = `STATE_POWERON_INIT_4_B;
               else
                 rNextState = `STATE_POWERON_INIT_4_A;
            end
          //------------------------------------------
          `STATE_POWERON_INIT_4_B:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_POWERON_INIT_5;
            end
          //------------------------------------------
           /*
           Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
           */
          `STATE_POWERON_INIT_5:
            begin
               rWrite_Enabled = 1'b1;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_POWERON_INIT_6_A;
               else
                 rNextState = `STATE_POWERON_INIT_5;
            end
          //------------------------------------------
          /*
           Wait 40 us or longer, which is 2,000 clock cycles at 50 MHz.
           */
          `STATE_POWERON_INIT_6_A:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
              if (rTimeCount > 32'd2000 )
                 rNextState = `STATE_POWERON_INIT_6_B;
               else
                 rNextState = `STATE_POWERON_INIT_6_A;
            end
          //------------------------------------------
          `STATE_POWERON_INIT_6_B:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h3;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_POWERON_INIT_7;
            end
          //------------------------------------------
           /*
           Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
           */
          `STATE_POWERON_INIT_7:
            begin
               rWrite_Enabled = 1'b1;

               rData = 80'h2;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_POWERON_INIT_8_A;
               else
                 rNextState = `STATE_POWERON_INIT_7;
            end
          //------------------------------------------
          /*
           Wait 40 us or longer, which is 2,000 clock cycles at 50 MHz.
           */
          `STATE_POWERON_INIT_8_A:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h2;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
              if (rTimeCount > 32'd2000 )
                 rNextState = `STATE_POWERON_INIT_8_B;
               else
                 rNextState = `STATE_POWERON_INIT_8_A;
            end
          //------------------------------------------
          `STATE_POWERON_INIT_8_B:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h2;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_CONFIGURATION_9;
            end
          //------------------------------------------
          /*
           Write SF_D<11:8> = 0x28, pulse LCD_E High for 12 clock cycles
           */
          `STATE_CONFIGURATION_9:
            begin
               rWrite_Enabled = 1'b1;

               rData = 80'h28;
               rWrite_Phrase = 2'b1;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_CONFIGURATION_11;
               else
                 rNextState = `STATE_CONFIGURATION_9;
            end
          //------------------------------------------
          /*
           Wait 40 us or longer, which is 2,000 clock cycles at 50 MHz.

          `STATE_CONFIGURATION_10_A:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h28;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
              if (rTimeCount > 32'd2000 )
                 rNextState = `STATE_POWERON_INIT_10_B;
               else
                 rNextState = `STATE_POWERON_INIT_10_A;
            end
          //------------------------------------------
          `STATE_CONFIGURATION_10_B:
            begin
               rWrite_Enabled = 1'b0;

               rData = 80'h28;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_RESET;
            end          //------------------------------------------
                     *//*
           Write SF_D<11:8> = 0x06, pulse LCD_E High for 12 clock cycles
           */
          `STATE_CONFIGURATION_11:
            begin
               rWrite_Enabled = 1'b1;
               rWrite_Phrase = 2'd1;
               rData = 80'h06;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 //rNextState = `STATE_CONFIGURATION_12_A;
                 rNextState = `STATE_CONFIGURATION_13;
               else
                 rNextState = `STATE_CONFIGURATION_11;
            end
          //------------------------------------------
          /*
           Wait 40 us or longer, which is 2,000 clock cycles at 50 MHz.
          `STATE_CONFIGURATION_12_A:
            begin
               rWrite_Enabled = 1'b0;

               rWrite_Phrase = 2'd0;
               rData = 80'h06;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
              if (rTimeCount > 32'd2000 )
                 rNextState = `STATE_CONFIGURATION_12_B;
               else
                 rNextState = `STATE_CONFIGURATION_12_A;
            end
          //------------------------------------------
          `STATE_CONFIGURATION_12_B:
            begin
               rWrite_Enabled = 1'b0;

               rWrite_Phrase = 2'd0;
               rData = 80'h06;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_CONFIGURATION_13;
            end
           */
          //------------------------------------------
          /*
           Write SF_D<11:8> = 0x0C, pulse LCD_E High for 12 clock cycles
           */
          `STATE_CONFIGURATION_13:
            begin
               rWrite_Enabled = 1'b1;
               rWrite_Phrase = 2'd1;
               rData = 80'h0C;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
               //  rNextState = `STATE_CONFIGURATION_14_A;
               rNextState = `STATE_CONFIGURATION_16;
               else
                 rNextState = `STATE_CONFIGURATION_13;
            end
          //------------------------------------------
          /*
           Wait 40 us or longer, which is 2,000 clock cycles at 50 MHz.
          `STATE_CONFIGURATION_14_A:
            begin
               rWrite_Enabled = 1'b0;
               rWrite_Phrase = 2'd0;
               rData = 80'h0C;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
              if (rTimeCount > 32'd2000 )
                 rNextState = `STATE_CONFIGURATION_14_B;
               else
                 rNextState = `STATE_CONFIGURATION_14_A;
            end
          //------------------------------------------
          `STATE_CONFIGURATION_14_B:
            begin
               rWrite_Enabled = 1'b0;
               rWrite_Phrase = 2'd0;
               rData = 80'h0C;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               rNextState = `STATE_CONFIGURATION_16;
                // rNextState = `STATE_RESET;
            end
           */
     //------------------------------------------
          /*
           Write SF_D<11:8> = 0x00, pulse LCD_E High for 12 clock cycles
           */
          `STATE_CONFIGURATION_15:
            begin
               rWrite_Enabled = 1'b1;
               rWrite_Phrase = 2'd1;
               rData = 80'h00;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 //rNextState = `STATE_WRITE_PHRASE;
                 rNextState = `STATE_RESET;
               else
                 rNextState = `STATE_CONFIGURATION_15;
            end
          //------------------------------------------
          /*
           Write phrase "Hola Mundo"
           */
          `STATE_WRITE_PHRASE:
            begin
               rWrite_Enabled = 1'b1;
               rWrite_Phrase = 2'd2;
               rData = {`H , `o , `l , `a , `Space , `M , `u , `n , `d , `o};
               oLCD_RegisterSelect = 1'b1; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_RESET;
               else
                 rNextState = `STATE_WRITE_PHRASE;
            end
          //------------------------------------------
          /*
           Write SF_D<11:8> = 0x01, pulse LCD_E High for 12 clock cycles
           */
          `STATE_CONFIGURATION_16:
            begin
               rWrite_Enabled = 1'b1;
               rWrite_Phrase = 2'd1;
               rData = 80'h01;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               if ( wWriteDone )
                 rNextState = `STATE_CONFIGURATION_17_A;
               else
                 rNextState = `STATE_CONFIGURATION_16;
            end
          //------------------------------------------
          /*
           Wait 1,64 ms or longer, which is 82,000 clock cycles at 50 MHz.
           */
          `STATE_CONFIGURATION_17_A:
            begin
               rWrite_Enabled = 1'b0;
               rWrite_Phrase = 2'd0;
               rData = 80'h01;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b0;
              if (rTimeCount > 32'd80004 )
                 rNextState = `STATE_CONFIGURATION_17_B;
               else
                 rNextState = `STATE_CONFIGURATION_17_A;
            end
          //------------------------------------------
          `STATE_CONFIGURATION_17_B:
            begin
               rWrite_Enabled = 1'b0;
               rWrite_Phrase = 2'd0;
               rData = 80'h01;
               oLCD_RegisterSelect = 1'b0; //these are commands
               rTimeCountReset = 1'b1;
               //rNextState = `STATE_CONFIGURATION_15;
                 rNextState = `STATE_RESET;
            end
          //------------------------------------------
          default:
            begin
               rWrite_Enabled = 1'b0;
               rData = 80'h0;
               rWrite_Phrase = 2'd0;
               oLCD_RegisterSelect = 1'b0;
               rTimeCountReset = 1'b0;
               rNextState = `STATE_RESET;
            end
          //------------------------------------------
        endcase
     end
endmodule
