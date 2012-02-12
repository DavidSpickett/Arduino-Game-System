//Make this TRUE to see debug output on the serial line
#define debug false

///////////// SYSTEM PIN NUMBERS //////////////////////

//GRID CONTROL PINS

//Column serial data in
#define colSerialDataIn 2

//Row serial data in
#define rowSerialDataIn 3

//Common latch clock
#define commonLatchClock 5

//Common shift clock
#define commonShiftClock 4

//CONTROLLER CONTROL PINS

//Controller port clock pin
#define controllerClock 7

//Controller Latch Pin
#define controllerLatch 6

//Controller One Serial Out
#define controllerOneSerialOut 8

//Controller Two Serial Out
#define controllerTwoSerialOut 9

//AUDIO PINS

//Speaker pin
#define speakerPin 10

//MODE SWITCH PINS

#define modeSwitchBitOne 14
#define modeSwitchLength 4

//////////////// SYSTEM VARIABLES ///////////////////////

//MODE SWITCH VARIABLES

byte modeSwitch;

//CONTROLLER VARIABLES

byte controllerOne;
byte controllerTwo;

//SCREEN VARIABLES

//Array to hold all the screen data
byte screenArray[7][10] = {{1,0,0,0,1,0,1,1,1,1},
                           {1,0,0,0,1,0,1,0,0,0},
                           {1,0,0,0,1,0,1,0,0,0},
                           {1,1,1,1,0,0,1,1,1,1},
                           {1,0,0,0,1,0,1,0,0,0},
                           {1,0,0,0,1,0,1,0,0,0},
                           {1,0,0,0,1,0,1,1,1,1}};

//Values used to get the bytes to send to the registers.
//Pre computed for speed
const byte dataValues[8] = {1,2,4,8,16,32,64,128};

/////////// HELPER MACROS /////////////////

//SCREEN MACROS

#define setPixel(x,y) screenArray[y][x]=1
#define clearPixel(x,y) screenArray[y][x]=0
#define readPixel(x,y) screenArray[y][x]
#define clearScreen(); for(byte y=0;y<screenHeight;y++){for (byte x=0;x<screenWidth;x++){screenArray[y][x]=0;}}

//Screen size, for game code use   
#define screenHeight 7
#define screenWidth 10

//CONTROLLER MACROS

#define readControllerOne() controllerOne=shiftIn(controllerOneSerialOut)
#define readControllerTwo() controllerTwo=shiftIn(controllerTwoSerialOut)
#define readControllerOneButton(x) ((controllerOne&(1<<(x-1)))==(1<<(x-1)))
#define readControllerTwoButton(x) ((controllerTwo&(1<<(x-1)))==(1<<(x-1)))

//SPEAKER MACROS

#define playTone(x,y) tone(speakerPin,x,y)

////////// GAME VARIABLES /////////////////

unsigned long time;

byte text[7][30] = 
{
{1,0,0,0,1,0,1,1,1,1,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,1,1,1,1,0},
{1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0},
{1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0},
{1,1,1,1,1,0,1,1,1,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0},
{1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0},
{1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0},
{1,0,0,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0}
};

byte position = 0;

void setup() {

  if (debug) {
    
    //Open serial port
    Serial.begin(9600);
  }

  //Setup outputs
  pinMode(commonLatchClock, OUTPUT);
  pinMode(commonShiftClock, OUTPUT);
  pinMode(rowSerialDataIn, OUTPUT);
  pinMode(colSerialDataIn, OUTPUT);

  pinMode(controllerClock,OUTPUT);
  pinMode(controllerLatch, OUTPUT);
  pinMode(controllerOneSerialOut, INPUT);
  pinMode(controllerTwoSerialOut, INPUT);
  
  for (byte i = 0; i<modeSwitchLength; i++) {
   
   pinMode(modeSwitchBitOne+i,INPUT); 
  }

  pinMode(speakerPin, OUTPUT);

  time = millis();
  
  //Copy initial data to screen
  for (byte i = 0; i<10; i++) {
   
   byte newPos = position+i;
  
   for (byte j = 0; j<7; j++) {
    
     screenArray[j][i] = text[j][i];
   } 
  }
}

void loop() {
  
  //This limits the frame rate of your program
  //It will do one iteration every XmS
  if ((millis()-time) >= 100) { 
   
   //Move along one in the data
   if (position != 29) {
     
     position++;
   } else {
     
     position = 0;
   }
    
   //Copy new data to the screen  
   for (byte i = 0; i<10; i++) {
   
   byte newPos = position+i;
   
   if (newPos > 29) {
     
     newPos = newPos-30;
   }
  
   for (byte j = 0; j<7; j++) {
    
     screenArray[j][i] = text[j][newPos];
   } 
  }
   
   time = millis();
  }

  updateScreen();
}

void updateScreen() {

  //This function uses the data in screenArray to setup the registers

  //This main for loop iterates over the 5 pairs of columns
  for (byte i = 0; i<5; i++) {

    //Calculate the bytes we need to shift out

    //Rows
    //Setting a row LOW will turn it on
    //These are done in reverse order because the first will be shifted over
    //to the second register once the second byte is sent.

    //Byte 2, second grid rows
    byte rowValueTwo = 0;

    //Byte 1, first grid rows 
    byte rowValueOne = 0;

    //Iterate over the rows to make up the value
    for (byte j = 0; j<screenHeight; j++) {

      //Second set of rows
      if (screenArray[j][i] == 0) {

        //This means the row is meant to be off, so we want to set it HIGH
        rowValueTwo += dataValues[6-j];
      }

      //First set of rows
      if (screenArray[j][i+5] == 0) {

        //Set that row HIGH
        rowValueOne += dataValues[6-j];
      }
    } //END row for loop

    
    if (debug) {
     
     Serial.print("Rows one value: ");
     Serial.println(rowValueOne);
     Serial.print("Rows two value: ");
     Serial.println(rowValueTwo);
    }
     
    //Columns
    //Setting a column HIGH will turn it on
    //We already know what sequence we want to use so we can just grab a value based 
    //on where we are in the refresh.
    
    if (debug) {
     
     Serial.print("Column value: ");
     Serial.println(dataValues[i],BIN);
     Serial.println(""); 
    }
     
    //Now we can do the actual sending of the data

    //Set the common latch pin low to allow data to be shifted in
    digitalWrite(commonLatchClock, LOW);

    //First column byte and first row byte
    for (byte j = 0; j < 8; j++)  {

      digitalWrite(colSerialDataIn, !!(dataValues[4-i] & (1 << (7 - j))));
      digitalWrite(rowSerialDataIn, !!(rowValueOne & (1 << (7-j))));

      digitalWrite(commonShiftClock, HIGH);
      digitalWrite(commonShiftClock, LOW);
    }
    
    //Second column byte and second row byte
    //Taken from the shiftOut() source code. (using MSBF)
    for (byte j = 0; j < 8; j++)  {

      digitalWrite(colSerialDataIn, !!(dataValues[4-i] & (1 << (7 - j))));
      digitalWrite(rowSerialDataIn, !!(rowValueTwo & (1 << (7 - j))));

      digitalWrite(commonShiftClock, HIGH);
      digitalWrite(commonShiftClock, LOW);
    }

    //Set latch clock HIGH to tell the registers sending has ended
    digitalWrite(commonLatchClock,HIGH);

  } // END column for loop
}  

byte shiftIn(byte dataPin) { 

  byte pinState;
  byte dataIn = 0;

  digitalWrite(controllerLatch, HIGH);
  delayMicroseconds(20);
  digitalWrite(controllerLatch, LOW);

  for (byte i = 0; i <= 7; i++) {

    //Set low to tigger the next bit to be put onto the serial line
    digitalWrite(controllerClock, LOW);
    //delayMicroseconds(0.2); //This delay appears to not be needed

    if (digitalRead(dataPin)) {

      //set the bit to 0 no matter what
      dataIn |= dataValues[(7-i)];
    }

    //Set clock HIGH so we can read the next bit the next time the loop comes around
    digitalWrite(controllerClock, HIGH);
  }

  if (debug) {

    if (dataPin == controllerOneSerialOut) {

      Serial.print("Controller One: ");
    } 
    else if (dataPin == controllerTwoSerialOut) {

      Serial.print("Controller Two: ");
    }

    Serial.println(dataIn,BIN);
  }

  return dataIn;
}

void readModeSwitch() {
  
 modeSwitch = 0;
 
 for (byte i = 0; i<modeSwitchLength; i++) {
  
  if (digitalRead(modeSwitchBitOne+i)) {
   
   modeSwitch += (1 << i);
  }
 }

 if (debug) {
  
  Serial.print("Mode Switch: ");
  Serial.println(modeSwitch,BIN);
 } 
}
