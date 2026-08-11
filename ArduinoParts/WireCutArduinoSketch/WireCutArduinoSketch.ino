const byte BAD_WIRE_PIN = 2;
const byte GOOD_WIRE_PIN = 3;

bool previousBadWireState = HIGH;
bool previousGoodWireState = HIGH;
unsigned long previousConnectionCheckTime = 0;
const unsigned long ARDUINO_CONNECTION_CHECK_INTERVAL = 1000;

void setup()
{
    Serial.begin(9600);

    // INPUT_PULLUP means the input is active when connected to GND,
    //so to read a pressed button you instead see if the pin is reading LOW
    pinMode(BAD_WIRE_PIN, INPUT_PULLUP);
    pinMode(GOOD_WIRE_PIN, INPUT_PULLUP);
}

void loop()
{
    bool badWireState = digitalRead(BAD_WIRE_PIN);
    bool goodWireState = digitalRead(GOOD_WIRE_PIN);

    if (badWireState == LOW && previousBadWireState == HIGH)
    {
        Serial.println("BAD_WIRE");
    }

    if (goodWireState == LOW && previousGoodWireState == HIGH)
    {
        Serial.println("GOOD_WIRE");
    }

    previousBadWireState = badWireState;
    previousGoodWireState = goodWireState;

    unsigned long currentTime = millis();
    if (currentTime - previousConnectionCheckTime >= ARDUINO_CONNECTION_CHECK_INTERVAL)
    {
        Serial.println("ARDUINO_CONNECTION_CHECK");
        previousConnectionCheckTime = currentTime;
    }
}
