CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  SDA_PIN       = 9 
  SCL_PIN       = 10
  I2CID         = $A0

  RX_PIN        = 17
  TX_PIN        = 16
  BAUD          = 9600

  CAM_RX        = 17
  CAM_TX        = 16
  CAM_BAUD      = 115200

  CHR_TYPE      = 0
  STR_TYPE      = 1
  DEC_TYPE      = 2
  HEX_TYPE      = 3
  BIN_TYPE      = 4

  LED_RED       = 13
  LED_GREEN     = 14

  BUFSIZ        = 128

  BOXMAX        = 8
  BOXSIZ        = 5*BOXMAX        ' 5 bytes per box, 8 boxes 
  COLSIZ        = 48              ' 3 colors (rgb) times 16 values = 48 bytes
  DATSIZ        = BOXSIZ+COLSIZ+1 ' box size = 20 boxes * 6 bytes, color size = 48, plus boxes count

  ERR_FF        = $01
  ERR_PG        = $02
  ERR_SM        = $04
  ERR_ET        = $08
  ERR_TO        = $10

VAR
  long box_sem
  long cog
  long cambuf[BUFSIZ]
  byte response[BUFSIZ]
  long in
  long out

  ' Camera I2C Registers
  byte boxes
  byte box[BOXSIZ]     ' boxes from 0 to BOXSIZ-1
  byte color[COLSIZ]   ' color map from BOXSIZ to BOXSIZ+COLSIZ-1
  byte status
  
  long stack1[BUFSIZ]
  long stack2[BUFSIZ]
  long camstack[BUFSIZ]

OBJ
  pc     : "FullDuplexSerial"
  cam    : "FullDuplexSerial"
  i2c    : "i2cslave"
    
PUB Main
  box_sem := locknew
  cognew(DataHandler, @stack1)
  'cognew(CamRecvHandler, @camstack)
  i2c.Start( SCL_PIN, SDA_PIN, I2CID, @boxes, DATSIZ )

PUB CamRecvHandler | c
  in := out := 0
  repeat
    c := cam.rx
    cambuf[in] := c 
    in := (in+1)&(BUFSIZ-1)
    'fifoStat

PUB DataPrinter | i, j
  ' Print out data storage
  repeat  
    pc.str(String("ColorMap: "))
    repeat i from 0 to COLSIZ
      pc.space
      pc.hex(color[i], 2)
    pc.lf
    pc.str(String("Boxes:    "))
    repeat until not lockset(box_sem)
    pc.dec(boxes)
    pc.lf
    i := 0
    repeat while (i < boxes)
      j := i*5
      pc.space
      pc.dec(box[j]) ' color
      pc.space
      pc.tx("(")
      pc.dec(box[j+1]) ' x1
      pc.tx(",")
      pc.dec(box[j+2]) ' y1
      pc.str(String(") to ("))
      pc.dec(box[j+3]) ' x2
      pc.tx(",")
      pc.dec(box[j+4]) ' y2
      pc.tx(")")
      pc.lf
      i := i + 1
    lockclr(box_sem)
    pc.str(String("Status:   "))
    pc.bin(status, 8)
    pc.lf
    pc.lf
    waitcnt(clkfreq*2+cnt)

PUB DataHandler | i, j, myBoxes, tmp[BOXSIZ], timeout
  status := 0
  cam.start(CAM_RX, CAM_TX, 0, CAM_BAUD)
  pc.start(RX_PIN, TX_PIN, 0, BAUD)
  ' Initialize Color Map
  ' r=144:176, b=32:64, g=16:48
  ' r 0 0 0 0 0 0 0 0 0 128 128 128 0 0 0 0
  ' g 0 0 128 128 128 0 0 0 0 0 0 0 0 0 0 0
  ' b 0 128 128 128 0 0 0 0 0 0 0 0 0 0 0 0
  waitcnt(clkfreq*2+cnt) ' need to wait because stupid i2c routine zeros out the data
  repeat i from 0 to COLSIZ-1
    color[i] := 0
  color[9] := color[10] := color[11] := 128
  color[18] := color[19] := color[20] := 128
  color[33] := color[34] := color[35] := 128

  ' Attempt to initialize camera

  dira[LED_RED] := 1
  dira[LED_GREEN] := 1
  outa[LED_RED] := 1
  outa[LED_GREEN] := 0

  ' Ping camera
  repeat
    waitcnt(clkfreq/4+cnt)
    pc.str(String("Disabling tracking..."))
    outa[LED_RED] := outa[LED_GREEN] := 1
    cam.str(String("DT"))
    cam.cr
    gotAck
    pc.str(String("Pinging camera..."))
    cam.str(String("PG"))
    cam.cr
    if (gotAck == false)
      status |= ERR_PG
      outa[LED_GREEN] := 0
    else
      outa[LED_RED] := 0
      status := 0
      quit

     
  ' send color map
  waitcnt(clkfreq/4+cnt)
  pc.str(String("Sending color map..."))
  outa[LED_RED] := outa[LED_GREEN] := 1
  cam.str(String("SM"))
  repeat i from 0 to COLSIZ-1
    cam.space
    cam.dec(color[i])
    waitcnt(clkfreq/1000+cnt)
  cam.cr
  if (gotAck == false)
    outa[LED_GREEN] := 0
    status |= ERR_SM
  else
    outa[LED_RED] := 0

  ' enable tracking
  waitcnt(clkfreq/4+cnt)
  pc.str(String("Enabling tracking..."))
  outa[LED_GREEN] := outa[LED_GREEN] := 1
  cam.str(String("ET"))
  cam.cr
  if (gotAck == false)
    outa[LED_GREEN] := 0
    status |= ERR_ET
  else
    outa[LED_RED] := 0
  
  pc.lf

  waitcnt(clkfreq/2+cnt)

  outa[LED_RED]   := (status <> 0)
  outa[LED_GREEN] := (status == 0)
     
  ' Start printing out data
  cognew(DataPrinter, @stack2)

  ' Start reading in tracking data
  repeat
  ' re-initialize box count
  ' Get Tracking Data
  ' Byte 0: 0x0A Indicating the start of a tracking packet
  ' AVRcam sends no data until boxes are detected, so we timeout
  ' and reset the number of boxes to 0 at some point
    timeout := 80 ' timeout is 80ms
    repeat until (cam.rxcheck == $0A)
      if (timeout == 0)
        repeat until not lockset(box_sem)
        boxes := 0
        lockclr(box_sem)
        timeout := -1 ' no need to keep zeroing the box count
      elseif (timeout > 0)
        timeout := timeout - 1
      waitcnt(clkfreq/1000+cnt) ' delay 1ms (17fps means ~59ms period)
  ' Byte 1: Number of tracked objects (0x00...0x08 are valid)
    myBoxes := cam.rx
    i := 0
    repeat while (i < myBoxes)
      ' Byte 2: Color of object tracked in bounding box 1
      ' Byte 3: X upper left corner of bounding box 1
      ' Byte 4: Y upper left corner of bouding box 1
      ' Byte 5: X lower right corner of boudning box 1
      ' Byte 6: Y lower right corner of boudning box 1
      repeat j from 0 to 4
        tmp[i*5+j] := cam.rx
      i := i + 1
    ' Byte x: 0xFF (indicates the end of line, and will be sent after all tracking info
    if (cam.rx <> $ff)
      status |= ERR_FF
  ' copy temporary data into central box data store
    repeat until not lockset(box_sem)
    boxes := myBoxes
    repeat i from 0 to BOXSIZ-1
      box[i] := tmp[i]
    lockclr(box_sem)
     
PUB fifoStat
    ' print in and out fifo pointers
    pc.dec(in)
    pc.tx(" ")
    pc.dec(out)
    pc.lf

PUB gotAck : ackReceived | i, c, timeout
  timeout := 5 'seconds
  ' read in data into the buffer
  repeat i from 0 to BUFSIZ-1
    ' keep checking until we get the next character
    repeat
      c := cam.rxcheck
      if (c == -1)
        waitcnt(clkfreq+cnt) ' wait 1 second
        timeout := timeout - 1
    until (c <> -1 or timeout == 0)

    if (timeout == 0)
      status |= ERR_TO
      quit

    if (c > 32 and c < 126)
      pc.tx(c)
    'pc.space
    'pc.hex(c,2)
    'pc.lf
    response[i] := c
      
    if (c == $0A or c == $0D) ' quit on \r or \n
      response[i] := 0
      quit

  pc.lf

  ackReceived := (response[0] == "A" and response[1] == "C" and response[2] == "K")
    