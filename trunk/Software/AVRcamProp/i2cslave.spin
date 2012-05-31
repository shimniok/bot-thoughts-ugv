CON
           
' *******************************************************************************************************
' *                                                                                                     *
' *     I2C Slave Interface                                                                             *
' *                                                                                                     *
' *******************************************************************************************************
' *                                                                                                     *
' *     Object Name    : I2C Slave Interface                                                            *
' *     Version        : 001                                                                            *
' *     Updated        : 2009-05-06                                                                     *
' *                                                                                                     *
' *     Author         : Tim Moore                                                                      *
' *                      Based on AiChip, with minor modifications                                      *
' *                                                                                                     *
' *     Copyright      : 2009, Tim Moore                                                                *
' *     Copyright      : 2008, AiChip Industries                                                        *
' *                                                                                                     *
' *     Target Chip    : Parallax Propeller Chip P8X32A ( "Propeller Mk I" )                            *
' *     Compiler Used  : Parallax Propeller Tool 1.1                                                    *
' *                                                                                                     *
' *     License        : MIT License. Please see end of this file for Terms of Use.                     *
' *                                                                                                     *
' *******************************************************************************************************
' *                                                                                                     *
' *******************************************************************************************************
' *                                                                                                     *
' *     DESCRIPTION                                                                                     *
' *                                                                                                     *
' *     This code allows a Propeller to operate as an I2C Slave device.                                 *
' *     Used to expose info to a I2C master, info is in Hub memory                                      *
' *                                                                                                     *
' *     The I2C Ram can be given a 7-bit Device Id $10 to $EE or a 10-bit Dvice Id $10_000 to $10_7FE.  *
' *     The lsb of the Device Id is ignored. 7-Bit Device Id's $00 to $0E and $F0 to $FE are reserved   *
' *     for special purposes by the I2C Bus Specification and should not be used.                       *
' *                                                                                                     *
' *     Modifications                                                                                   *
' *       Only support 256byte data from hub, no COG RAM                                                *
' *       8bit memory address only                                                                      *
' *       7bit device address only                                                                      *
' *       Handle master releasing bus and SDA going high after last write bit                           *
' *                                                                                                     *
' *******************************************************************************************************

' *******************************************************************************************************
' *                                                                                                     *
' *     HISTORY                                                                                         *
' *                                                                                                     *
' *******************************************************************************************************

VAR

  byte CogNumber

PUB Start( argSclPinNumber, argSdaPinNumber, argDeviceId, argHubPtr, argHubSize)
'' Max argHubSize is 256
'
  Stop

  argDeviceId &= $FE
  if argDeviceId =< $0F or argDeviceId => $F0
    return 0
      
  if argHubSize == 0 OR argHubSize > 256
    abort

  argHubSize := DetermineBitMask( argHubSize )
  
  if ( result := cogNumber := CogNew( @I2cSlave, @argSclPinNumber ) + 1 )

    repeat until argSclPinNumber < 0
  
PUB Stop

  if cogNumber
    CogStop( cogNumber~ - 1 )

PRI DetermineBitMask( size ) : mask

    mask := 1
    repeat while mask =< size
      mask := mask << 1 | 1
    mask >>= 1

CON

' *******************************************************************************************************
' *                                                                                                     *
' *     PASM Handler                                                                                    *
' *                                                                                                     *
' *******************************************************************************************************
                        
DAT                     org     $000

'                       .-------------------------------------------------------------------------------.
'                       |       initialise the parameters                                               |
'                       `-------------------------------------------------------------------------------'

I2cSlave                mov     parPtr,PAR

GetParam                rdlong  parArg,parPtr
                        add     parPtr,#4
GetParam_Ret            jmp     #FirstParam

parPtr                  long    0
parArg                  long    0

FirstParam              mov     sclMask,#1
                        shl     sclMask,parArg                                   

                        call    #GetParam                                       
                        mov     sdaMask,#1
                        shl     sdaMask,parArg                                   

                        mov     sxxMask,sclMask
                        or      sxxMask,sdaMask
                        
                        call    #GetParam                                       
                        andn    parArg,#1
                        mov     deviceWr,parArg
                        or      parArg,#1
                        mov     deviceRd,parArg

                        call    #GetParam                                       
                        mov     hubPtr,parArg                                   

                        call    #GetParam                                       
                        mov     hubMsk,parArg                                   

'                       .-------------------------------------------------------------------------------.
'                       |       Tell caller the cog is running                                          |
'                       `-------------------------------------------------------------------------------'

                        neg     byt,#1                  ' Set the argSclPin parameter to -1
                        wrlong  byt,PAR

'                       .-------------------------------------------------------------------------------.
'                       |       Clear Virtual Ram held in Hub                                           |
'                       `-------------------------------------------------------------------------------'

                        rdlong  count,#0                ' Delay ~2ms - Gives time for Spin to CogStop
                        shr     count,#9
                        add     count,CNT
                        waitcnt count,#0
                        
                        mov     count,hubMsk            ' Get Size of Hub array ( in bytes )
                        add     count,#1

                        mov     idx,#0                  ' Clear from first byte of array

:Loop                   mov     parPtr,hubPtr           ' Point to byte in hub
                        add     parPtr,idx
                        wrbyte  k_0,parPtr
                        add     idx,#1
                        djnz    count,#:Loop

'                       .-------------------------------------------------------------------------------.
'                       |       Wait for a start bit                                                    |
'                       `-------------------------------------------------------------------------------'
                        
Idle                    call    #GetBit
                        jmp     #Idle

'                       .-------------------------------------------------------------------------------.
'                       |       Determine if command is for us or not                                   |
'                       `-------------------------------------------------------------------------------'

StartBit                call    #GetByte                ' Read the Device Id 

                        cmp     byt,deviceRd WZ         ' Is it a read from us ?
                  IF_Z  jmp     #Read                   ' Yes - Handle the read
                  
                        cmp     byt,deviceWr WZ         ' Is it a write to us ?
                  IF_Z  jmp     #Write                  ' Yes - Handle the write

                        jmp     #Idle                   ' Not for us

'                       .-------------------------------------------------------------------------------.
'                       |       Handle a Read command                                                   |
'                       `-------------------------------------------------------------------------------'

Read                    call    #Ack                    ' Acknowledge the read command

:Loop                   call    #LoadByte               ' Get the byte to replay with
                        call    #SendByte               ' And send it
                        
                        call    #GetBit                 ' Does the master want more bytes ?
                        tjz     bit,#:Loop              ' Yes - Get the next and send it
                        
                        jmp     #Idle                   ' No - Wait for next command

'                       .-------------------------------------------------------------------------------.
'                       |       Handle a Write command                                                  |
'                       `-------------------------------------------------------------------------------'

Write                   call    #Ack                    ' Acknowledge the write command

                        call    #GetByte                ' Get address byte
                        mov     adr,byt
                        call    #Ack                    ' ACknowledge we got the byte
                        
:Loop                   call    #GetByte                ' Get the data byte ( aborts on stop bit )
                        Call    #SaveByte               ' Save it
                        call    #Ack                    ' Acknowledge we saved it
                                                   
                        jmp     #:Loop                  ' Get next byte ( will abort on a stop bit )

'                       .-------------------------------------------------------------------------------.
'                       |       Handle save byte to I2C Ram                                             |
'                       `-------------------------------------------------------------------------------'

SaveByte                mov     idx,adr                 ' Address to write to

                        and     idx,hubMsk
                        add     idx,hubPtr
                        wrbyte  byt,idx
                                                        
                        add     adr,#1

SaveByte_Ret            ret

'                       .-------------------------------------------------------------------------------.
'                       |       Handle load byte from I2C Ram                                           |
'                       `-------------------------------------------------------------------------------'

LoadByte                mov     idx,adr                 ' Address to write to

                        and     idx,hubMsk
                        add     idx,hubPtr
                        rdbyte  byt,idx
                        add     adr,#1
                        
LoadByte_Ret            ret

'                       .-------------------------------------------------------------------------------.
'                       |       Send Ack or Nak                                                         |
'                       `-------------------------------------------------------------------------------'
                                                
Ack                     mov     byt,#0
                        call    #SendBit
Ack_Ret                 ret

Nak                     mov     byt,#$80
                        call    #SendBit
Nak_Ret                 ret

'                       .-------------------------------------------------------------------------------.
'                       |       Send a byte                                                             |
'                       `-------------------------------------------------------------------------------'

SendByte                mov     count,#8

:Loop                   call    #SendBit
                        shl     byt,#1
                        djnz    count,#:Loop

SendByte_Ret            ret

'                       .-------------------------------------------------------------------------------.
'                       |       Send a bit                                                              |
'                       `-------------------------------------------------------------------------------'

SendBit                 test    sclMask,INA WC
                  IF_C  jmp     #$-1

                        test    byt,#$80 WC
                  IF_NC mov     DIRA,sdaMask
                  
                        test    sclMask,INA WC
                  IF_NC jmp     #$-1
                  
                        test    sclMask,INA WC
                  IF_C  jmp     #$-1
                  
                        mov     DIRA,#0

SendBit_Ret             ret

'                       .-------------------------------------------------------------------------------.
'                       |       Read a byte                                                             |
'                       `-------------------------------------------------------------------------------'

GetByte                 mov     byt,#0
                        mov     count,#8
                        
:Loop                   call    #GetBit
                        shl     byt,#1
                        or      byt,bit
                        
                        djnz    count,#:Loop

GetByte_Ret             ret

'                       .-------------------------------------------------------------------------------.
'                       |       Determine bit or event from the incoming bit stream                     |
'                       `-------------------------------------------------------------------------------'
'
'                       Impossible                      Should never have got here with this setting
'                       DoubleFlip                      Two bits changed state at the same time
'                       FatalError                      Non-valid bit sequence
                        
GetBit                  call    #GetBitStream           ' Match the bit stream

                        mov     idx,bitStream
                        add     idx,#JumpTable
                        jmp     idx
                        
JumpTable               jmp     #Impossible             ' 00_00_00
                        jmp     #Impossible             ' 00_00_01
                        jmp     #Impossible             ' 00_00_10
                        jmp     #Impossible             ' 00_00_11
                        jmp     #GetBit                 ' 00_01_00              Pre Ack Rx
                        jmp     #Impossible             ' 00_01_01
                        jmp     #DoubleFlip             ' 00_01_10
                        jmp     #GetBit                 ' 00_01_11              Pre Bit 1
                        jmp     #Bit0                   ' 00_10_00              Bit 0
                        jmp     #Bit0 'DoubleFlip       ' 00_10_01              End of a write when master releases SDA which goes high 
                        jmp     #Impossible             ' 00_10_10
                        jmp     #StopBit                ' 00_10_11              Stop Bit
                        jmp     #DoubleFlip             ' 00_11_00
                        jmp     #DoubleFlip             ' 00_11_01
                        jmp     #DoubleFlip             ' 00_11_10
                        jmp     #Impossible             ' 00_11_11
                        
                        jmp     #Impossible             ' 01_00_00
                        jmp     #GetBit                 ' 01_00_01              Post Bit 1 / Pre Bit 1
                        jmp     #GetBit                 ' 01_00_10              Post Bit 1 / Pre Bit 0
                        jmp     #DoubleFlip             ' 01_00_11
                        jmp     #Impossible             ' 01_01_00
                        jmp     #Impossible             ' 01_01_01
                        jmp     #Impossible             ' 01_01_10
                        jmp     #Impossible             ' 01_01_11
                        jmp     #DoubleFlip             ' 01_10_00
                        jmp     #DoubleFlip             ' 01_10_01
                        jmp     #Impossible             ' 01_10_10
                        jmp     #DoubleFlip             ' 01_10_11
                        jmp     #DoubleFlip             ' 01_11_00
                        jmp     #Bit1                   ' 01_11_01              Bit 1
                        jmp     #GetBit                 ' 01_11_10              Pre Repeated Start
                        jmp     #Impossible             ' 01_11_11
                        
                        jmp     #Impossible             ' 10_00_00
                        jmp     #GetBit                 ' 10_00_01              Post Bit 0 / Pre Bit 1
                        jmp     #GetBit                 ' 10_00_10              Post Bit 0 / Pre Bit 0
                        jmp     #DoubleFlip             ' 10_00_11
                        jmp     #GetBit 'DoubleFlip     ' 10_01_00              After ack sent when master releases SDA which goes high
                        jmp     #Impossible             ' 10_01_01
                        jmp     #DoubleFlip             ' 10_01_10
                        jmp     #DoubleFlip             ' 10_01_11
                        jmp     #Impossible             ' 10_10_00
                        jmp     #Impossible             ' 10_10_01
                        jmp     #Impossible             ' 10_10_10
                        jmp     #Impossible             ' 10_10_11
                        jmp     #DoubleFlip             ' 10_11_00
                        jmp     #FatalError             ' 10_11_01
                        jmp     #GetBit                 ' 10_11_10              Pre Start Bit
                        jmp     #Impossible             ' 10_11_11
                        
                        jmp     #Impossible             ' 11_00_00
                        jmp     #DoubleFlip             ' 11_00_01
                        jmp     #DoubleFlip             ' 11_00_10
                        jmp     #DoubleFlip             ' 11_00_11
                        jmp     #GetBit                 ' 11_01_00              Post Bit1 Rx / Post Nak Rx
                        jmp     #Impossible             ' 11_01_01
                        jmp     #DoubleFlip             ' 11_01_10
                        jmp     #GetBit                 ' 11_01_11              Post Bit 1
                        jmp     #StartBit               ' 11_10_00              Start Bit
                        jmp     #DoubleFlip             ' 11_10_01
                        jmp     #Impossible             ' 11_10_10
                        jmp     #FatalError             ' 11_10_11              
                        jmp     #Impossible             ' 11_11_00
                        jmp     #Impossible             ' 11_11_01
                        jmp     #Impossible             ' 11_11_10
Impossible                                              ' 11_11_11
DoubleFlip
FatalError

StopBit                 call    #GetBitStream           ' Stop Bit - Wait until start bit
                        cmp     bitStream,#%11_10_00 WZ
                  IF_Z  jmp     #StartBit
                        jmp     #StopBit

Bit0                    mov     bit,#0                  ' Got a 0 bit
                        jmp     #GetBit_Ret
                        
Bit1                    mov     bit,#1                  ' Got a 1 bit
                        
GetBit_Ret              ret

'                       .-------------------------------------------------------------------------------.
'                       |       Read a bit pair into the bit stream                                     |
'                       `-------------------------------------------------------------------------------'

GetBitStream            mov     thisInput,INA           ' Read SCLK/SDA
                        and     thisInput,sxxMask
                        cmp     thisInput,lastInput WZ  ' Same as last time ?
                  IF_Z  jmp     #GetBitStream           ' Yes - Wait for change

                        mov     lastInput,ThisInput                             
                        
                        test    thisInput,sclMask WC    ' Update bit stream
                        rcl     bitStream,#1
                        test    thisInput,sdaMask WC
                        rcl     bitStream,#1
                        and     bitStream,#%11_11_11    ' Keep three samples - CD_CD_CD
                        
GetBitStream_Ret        ret

'                       .-------------------------------------------------------------------------------.
'                       |       Constants                                                               |
'                       `-------------------------------------------------------------------------------'

k_0                     long    $0

'                       .-------------------------------------------------------------------------------.
'                       |       Pre-Initialised Variables                                               |
'                       `-------------------------------------------------------------------------------'

lastInput               long    0                       ' Last input bits read

'                       .-------------------------------------------------------------------------------.
'                       |       Run-Time Variables                                                      |
'                       `-------------------------------------------------------------------------------'

sclMask                 res     1                       ' SCLK pin mask
sdaMask                 res     1                       ' SDA pin mask
sxxMask                 res     1                       ' Combined SCLK and SDA pin masks

deviceRd                res     1                       ' Device Id when reading 
deviceWr                res     1                       ' Device Id when writing

thisInput               res     1                       ' Current input bits
bitStream               res     1                       ' Incomming bit stream, three samples

count                   res     1                       ' General purpose counter
bit                     res     1                       ' General purpose bit variable ( 0 or 1 )
byt                     res     1                       ' General purpose byte variable

adr                     res     1                       ' Current read/write address
idx                     res     1                       ' General purpose index variable

hubPtr                  res     1                       ' Pointer to byte array in Hub
hubMsk                  res     1                       ' Mask of address for byte array in Hub
                        fit     $1F0

CON

' *******************************************************************************************************
' *                                                                                                     *
' *     Terms of Use : MIT License                                                                      *
' *                                                                                                     *
' *******************************************************************************************************
'
' Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
' associated documentation files (the "Software"), to deal in the Software without restriction, including
' without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
' the following conditions:                                                                   
'
' The above copyright notice and this permission notice shall be included in all copies or substantial
' portions of the Software.                                                                                             
'                                                                                                                  
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
' LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
' NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
' WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
' SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  