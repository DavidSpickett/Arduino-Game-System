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
byte screenArray[7][10] = {{0,0,0,0,0,0,0,0,0,0},
                           {0,0,0,0,0,0,0,0,0,0},
                           {0,0,0,0,0,0,0,0,0,0},
                           {0,0,0,0,0,0,0,0,0,0},
                           {0,0,0,0,0,0,0,0,0,0},
                           {0,0,0,0,0,0,0,0,0,0},
                           {0,0,0,0,0,0,0,0,0,0}};

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

byte playerOneY;
byte playerTwoY;

byte playerOneScore = 0;
byte playerTwoScore = 0;

byte ballX;
byte ballY;

int ballXV;
int ballYV;

#define aiDelayRs 31
byte aiDelay = aiDelayRs;

#define ballDelayRs 30
byte ballDelay = ballDelayRs;

#define playerOnePaddleSize 2
#define playerTwoPaddleSize 2

int controlOption = 0;

unsigned long time;

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
  
  resetGame();
  
  readControllerOne();
  
  if (readControllerOneButton(1)) {
   
   controlOption = 1; //Control left side 
  } else if (readControllerOneButton(2)) {
   
   controlOption = 2; //Control right side 
  } else if (readControllerOneButton(3)) {
   
   controlOption = 3; //Control both 
  }
}

void loop() {
  
  //This limits the frame rate of your program
  //It will do one iteration every XmS
  readModeSwitch();
  
  if ((millis()-time) >= modeSwitch) { 
   
   doPong();
   time = millis();
  }

  updateScreen();
}

void testScreen() {
 
 clearScreen();
 
 unsigned long testTime = millis();
 boolean cont = true;
 byte i = 0;
 byte j = 0;
 
 setPixel(i,j);
 
 while (cont) {
   
   if ((millis()-testTime) > 40) {
     
     if (i != (screenWidth-1)) {
      
      playTone(i*100,10);
      i++; 
     } else {
      
      i = 0;
      j++; 
     }
     
     setPixel(i,j);
     
     if (j > (screenHeight-1)) {
      cont = false; 
     }
     
     testTime = millis();
   }
   
   updateScreen();
 }
 
 clearScreen();
}

void resetGame() {

  //Seed randomness
  randomSeed(analogRead(0));

  //Initial setup
  if (random(2) == 1) {

    ballXV = -1;
    ballX = 7;
  } 
  else {

    ballXV = 1;
    ballX = 2;
  }

  randomSeed(analogRead(0));

  if (random(2) == 1) {

    ballYV = 1;
  } 
  else {

    ballYV = -1;
  }

  ballY = 3;

  playerOneY = 3-((playerOnePaddleSize/2)-1); //The minus 1 takes care of the case 
  playerTwoY = 3-((playerTwoPaddleSize/2)-1); //where the size is six and it would draw over the scores.
}

void doPong() {
  
  //Clear the screenArray
    for (int i = 0; i<screenWidth; i++) {
      for (int j = 0; j<screenHeight; j++) {

        clearPixel(i,j);
      }
    }

    byte oldPlayerOneY = playerOneY;
    byte oldPlayerTwoY = playerTwoY;

    //Apply movement to paddles

    if (aiDelay == 0) {
      
      if ((ballXV == -1) && (controlOption != 1) && (controlOption != 3)) {
        
        //Player One
        if ((ballY > (playerOneY+1)) && (playerOneY != (screenHeight-playerOnePaddleSize))) {

          playerOneY++; 
        }

        if ((ballY < playerOneY) && (playerOneY != 1)) {

          playerOneY--;
        }
      }

      if ((ballXV == 1) && (controlOption != 2) && (controlOption != 3)) {
        
        //Player Two
        if ((ballY > (playerTwoY+1)) && (playerTwoY != (screenHeight-playerTwoPaddleSize))) {

          playerTwoY++; 
        }

        if ((ballY < playerTwoY) && (playerTwoY != 1)) {

          playerTwoY--;
        } 
      }
      
      readControllerOne();
      
      //Controls for the player
      if (controlOption == 1) {
        
        //Move left paddle
        if (readControllerOneButton(1) && (playerOneY != 1)) {
         
         playerOneY--; 
        }
        
        if (readControllerOneButton(8) && (playerOneY != (screenHeight-playerOnePaddleSize))) {
          
          playerOneY++;
        }
        
      } else if (controlOption == 2) {
        
        //Move right paddle
        if (readControllerOneButton(1) && (playerTwoY != 1)) {
         
         playerTwoY--; 
        }
        
        if (readControllerOneButton(8) && (playerTwoY != (screenHeight-playerTwoPaddleSize))) {
          
          playerTwoY++;
        }
        
      } else if (controlOption == 3) {
        
        //Control both paddles
        
        //Move left paddle
        if (readControllerOneButton(1) && (playerOneY != 1)) {
         
         playerOneY--; 
        }
        
        if (readControllerOneButton(3) && (playerOneY != (screenHeight-playerOnePaddleSize))) {
          
          playerOneY++;
        }
        
        //Move right paddle
        if (readControllerOneButton(6) && (playerTwoY != 1)) {
         
         playerTwoY--; 
        }
        
        if (readControllerOneButton(8) && (playerTwoY != (screenHeight-playerTwoPaddleSize))) {
          
          playerTwoY++;
        }
      }

      aiDelay = aiDelayRs;
    }

    aiDelay--;

    //Draw paddles
    for (int i = 0; i<playerOnePaddleSize; i++) {
      
      setPixel(0,playerOneY+i);
    }
    
    for (int i = 0; i<playerTwoPaddleSize; i++) {
      
      setPixel(screenWidth-1,playerTwoY+i);
    }

    if (ballDelay == 0) {

      if ((ballX == 0) || (ballX == (screenWidth-1))) {
        
        boolean gameOver = false;

        //Ball hit side
        if (ballX == 0) {

          //Left side
          if (playerTwoScore != 5) {

            playerTwoScore++;
          } 
          else {

            playerOneScore = 0;
            playerTwoScore = 0;
            
            gameOver = true;
            
            testScreen();
          }
        }

        //Right side
        if (ballX == (screenWidth-1)) {

          if (playerOneScore != 5) {

            playerOneScore++;
          } 
          else {

            playerOneScore = 0;
            playerTwoScore = 0;
            
            gameOver = true;
            
            testScreen();
          }
        }
        
        if (gameOver) {
          
          noTone(speakerPin);
          playTone(500, 500);
        } else {
          
          noTone(speakerPin);
          playTone(2000, 300);
        }
        
        resetGame();
      }

      if (((ballX == 1) && (((ballY >= oldPlayerOneY) && (ballY <= (oldPlayerOneY+(playerOnePaddleSize-1)))) || (((oldPlayerOneY+playerOnePaddleSize) == ballY) && (ballYV == -1)) || (((oldPlayerOneY-1) == ballY) && (ballYV == 1)))) 
        || ((ballX == (screenWidth-2)) && (((ballY >= oldPlayerTwoY) && (ballY <= (oldPlayerTwoY+(playerTwoPaddleSize-1)))) || (((oldPlayerTwoY+playerTwoPaddleSize) == ballY) && (ballYV == -1)) || (((oldPlayerTwoY-1) == ballY) && (ballYV == 1))))) { 

        ballXV *= -1;
        noTone(speakerPin);
        playTone(1000,100);
      }
      
      //(oldPlayerOneY == ballY) || ((oldPlayerOneY+1) == ballY)

      //Apply movement to ball
      if ((ballY == 1) || (ballY == (screenHeight-1)) || ((ballX == 1) && (((ballY == (playerOneY+playerOnePaddleSize)) && (ballYV == -1)) || ((ballY == (playerOneY-1)) && (ballYV == 1))))
         || ((ballX == (screenWidth-2)) && (((ballY == (playerTwoY+playerTwoPaddleSize)) && (ballYV == -1)) || ((ballY == (playerTwoY-1)) && (ballYV == 1))))) {

        ballYV *= -1;
        noTone(speakerPin);
        playTone(1000,100);
      }

      if ((((ballX + ballXV) >=  0)) && ((ballX + ballXV) <= (screenWidth-1))) {
        
        ballX += ballXV;
      }
      
      if (((ballY + ballYV) > 0) && ((ballY + ballYV) <= (screenHeight-1))) {
        
        ballY += ballYV;
      }

      ballDelay = ballDelayRs;
    }

    ballDelay--;

    //Draw the ball
    setPixel(ballX,ballY);

    //Draw on scores
    for (int i = 0; i<playerOneScore; i++) {

      setPixel(i,0);
    }

    for (int i = 0; i<playerTwoScore; i++) {

      setPixel(screenWidth-i-1,0); 
    }
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
