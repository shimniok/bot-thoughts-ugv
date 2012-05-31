CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  SDA_PIN       = 9 
  SCL_PIN       = 10
  I2CID         = $A0

  RX_PIN        = 17
  TX_PIN        = 16
  BAUD          = 9600

  CAM_RX        = 26
  CAM_TX        = 25
  CAM_BAUD      = 115200

  CHR_TYPE      = 0
  STR_TYPE      = 1
  DEC_TYPE      = 2
  HEX_TYPE      = 3
  BIN_TYPE      = 4

  BUFSIZ        = 128

  BOXSIZ        = 5*8+1           ' 5 bytes per box, 8 boxes, 1st byte is the box count
  COLSIZ        = 48              ' 3 colors (rgb) times 16 values = 48 bytes
  DATSIZ        = BOXSIZ + COLSIZ ' box size = 20 boxes * 6 bytes, color size = 48
  
  
VAR
  long cog
  long cambuf[BUFSIZ]
  byte response[10]
  long in
  long out

  ' Camera I2C Registers
  byte box[BOXSIZ]     ' boxes from 0 to BOXSIZ-1
  byte color[COLSIZ]   ' color map from BOXSIZ to BOXSIZ+COLSIZ-1

  long stack1[BUFSIZ]
  long stack2[BUFSIZ]
  long camstack[BUFSIZ]

OBJ
  pc     : "FullDuplexSerial"
  cam    : "FullDuplexSerial"
  i2c    : "i2cslave"
' S      : "String"
    
PUB Main
  cognew(DataHandler, @stack1)
  cognew(CamRecvHandler, @camstack)
  i2c.Start( SCL_PIN, SDA_PIN, I2CID, @box, DATSIZ )

PUB CamRecvHandler | c
  in := out := 0
  box[0] := 9 ' bogus test init thingy
  cam.start(CAM_RX, CAM_TX, 0, CAM_BAUD)
  cam.rxflush
  repeat
    c := cam.rx
    cambuf[in] := c 
    in := (in+1)&(BUFSIZ-1)
    'fifoStat

PUB DataPrinter | i
  ' Print out data storage
  repeat  
    pc.str(String("ColorMap: "))
    repeat i from 0 to COLSIZ
      pc.space
      pc.hex(color[i], 2)
    pc.lf
    pc.str(String("Boxes:    "))
    repeat i from 0 to BOXSIZ
      pc.space
      pc.dec(box[i])
    pc.lf
    waitcnt(clkfreq*2+cnt)

PUB DataHandler | i
  pc.start(RX_PIN, TX_PIN, 0, BAUD)
  ' Initialize Color Map
  ' r=144:176, b=32:64, g=16:48
  ' r 0 0 0 0 0 0 0 0 0 128 128 128 0 0 0 0
  ' g 0 0 128 128 128 0 0 0 0 0 0 0 0 0 0 0
  ' b 0 128 128 128 0 0 0 0 0 0 0 0 0 0 0 0
  waitcnt(clkfreq*5+cnt) ' need to wait because stupid i2c routine zeros out the data
  repeat i from 0 to COLSIZ-1
    color[i] := 0
  color[9] := color[10] := color[11] := 128
  color[18] := color[19] := color[20] := 128
  color[33] := color[34] := color[35] := 128
  ' Ping camera
  pc.str(String("Pinging camera... "))
  cam.str(String("PG"))
  cam.cr
  waitcnt(clkfreq+cnt)
  if (gotAck)
    pc.str(String("ok"))
  else
    pc.str(String("FAIL"))
  pc.lf
  ' send color map
  cam.str(String("SM"))
  repeat i from 0 to COLSIZ-1
    cam.space
    cam.dec(color[i])  
  cam.cr
  pc.str(String("Sending color map..."))
  waitcnt(clkfreq*2+cnt)
  if (gotAck)
    pc.str(String("ok"))
  else
    pc.str(String("FAIL"))
  pc.lf
  cam.str(String("ET")) ' enable tracking
  cam.cr
  pc.str(String("Enabling tracking..."))
  waitcnt(clkfreq*2+cnt) ' wait a little extra for the big ol' color map to transmit
  if (gotAck)
    pc.str(String("ok"))
  else
    pc.str(String("FAIL"))
  pc.lf

  ' Start printing out data
  cognew(DataPrinter, @stack2)

  ' Get Tracking Data
  if (out <> in)
  ' Byte 0: 0x0A Indicating the start of a tracking packet
    repeat until (cambuf[out] == $0A)
      out := (out+1)&(BUFSIZ-1)
  ' Byte 1: Number of tracked objects (0x00...0x08 are valid)
    box[0] := cambuf[out]
    out := (out+1)&(BUFSIZ-1)
    repeat i from 1 to box[0]
    ' Byte 2: Color of object tracked in bounding box 1
    ' Byte 3: X upper left corner of bounding box 1
    ' Byte 4: Y upper left corner of bouding box 1
    ' Byte 5: X lower right corner of boudning box 1
    ' Byte 6: Y lower right corner of boudning box 1
    ' Byte 7: Color object tracked in bound box 2
    ' ...
    ' Byte x: 0xFF (indicates the end of line, and will be sent after all tracking info


PUB fifoStat
    ' print in and out fifo pointers
    pc.dec(in)
    pc.tx(" ")
    pc.dec(out)
    pc.lf

PUB gotAck : ackReceived | i
  repeat i from 0 to 9
    response[i] := cambuf[out]
    out := (out+1)&(BUFSIZ-1)
    if (response[i] == 0 or in == out) ' quit on \0
      quit
    pc.tx(response[i])
  ackReceived := (response[0] == "A" and response[1] == "C" and response[2] == "K")
          