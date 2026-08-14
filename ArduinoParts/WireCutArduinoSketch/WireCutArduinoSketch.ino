const unsigned long WIRE_CONFIRMATION_TIME = 500;

struct PinInfo
{
    byte pinNumber;
    byte inputMode;
    byte stateThatsConsideredActive; //what pin state to accept as active, could be HIGH or LOW etc
    unsigned long validationTimeLengthMS; //how long pin needs to be active for valid input
    const char *pinMessage; //what message gets sent to serial if the pin is activated
    bool beingValidated; //if the pin is currently being checked for validation
    bool alreadyReported; 
    unsigned long validationStartTime; //when the pin started being validated
};

PinInfo pinList[] = {
    {2, INPUT_PULLUP, LOW, WIRE_CONFIRMATION_TIME, "BAD_WIRE", false, false, 0},
    {3, INPUT_PULLUP, LOW, WIRE_CONFIRMATION_TIME, "GOOD_WIRE", false, false, 0}
};

unsigned long previousConnectionCheckTime = 0;
const unsigned long ARDUINO_CONNECTION_CHECK_INTERVAL = 1000;

bool isPinInputValid(PinInfo &currentPin, unsigned long currentTime)
{
    bool currentState = digitalRead(currentPin.pinNumber);

    if (currentState == currentPin.stateThatsConsideredActive)
    {
        //we only want to start timing a pin if it hasn't already 
        //started being timed and if it hasn't already been reported as valid
        if (!currentPin.beingValidated && !currentPin.alreadyReported)
        {
            currentPin.beingValidated = true;
            currentPin.validationStartTime = currentTime;
        }

        //if we're tining this pin already, and we've hit the time required...
        if (currentPin.beingValidated &&
            currentTime - currentPin.validationStartTime 
            >= currentPin.validationTimeLengthMS)
        {
            //...end the validation timing process and then report that 
            //the pin's input is good
            currentPin.beingValidated = false;
            currentPin.alreadyReported = true;
            return true;
        }
    }
    else
    {
        // Cancel a pin that did not remain continuously active
        currentPin.beingValidated = false;
        currentPin.alreadyReported = false;
    }

    return false;
}

void setup()
{
    Serial.begin(9600);

    for (PinInfo &currentPin : pinList)
    {
        pinMode(currentPin.pinNumber, currentPin.inputMode);
    }
}

void loop()
{
    unsigned long currentTime = millis();
    
    for (PinInfo &currentPin : pinList)
    {
        if (isPinInputValid(currentPin, currentTime))
        {
            Serial.println(currentPin.pinMessage);
        }
    }

    if (currentTime - previousConnectionCheckTime >= ARDUINO_CONNECTION_CHECK_INTERVAL)
    {
        Serial.println("ARDUINO_CONNECTION_CHECK");
        previousConnectionCheckTime = currentTime;
    }
}
