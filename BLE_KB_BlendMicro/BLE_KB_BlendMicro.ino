#include <SPI.h>
#include <BLEPeripheral.h>
#include <Keyboard.h>

#define  DEBUG  0

#define  SERVICE_UUID     "0000BE00-0000-1000-8000-00805F9B34FB"
#define  INPUT_TEXT_UUID  "0000BE01-0000-1000-8000-00805F9B34FB"
#define  SEND_ENTER_UUID  "0000BE02-0000-1000-8000-00805F9B34FB"

#define  MY_BLE_LOCAL_NAME  "AutoPass_blend"
#define  MAX_TEXT_LENGTH    20

#define PIN_REQ   6
#define PIN_RDY   7
#define PIN_RST   4

BLEPeripheral blePeripheral = BLEPeripheral(PIN_REQ, PIN_RDY, PIN_RST);
BLEService kbService = BLEService(SERVICE_UUID);

BLECharacteristic    textCharacteristic  = BLECharacteristic(INPUT_TEXT_UUID, BLEWrite | BLENotify, MAX_TEXT_LENGTH);
BLEIntCharacteristic enterCharacteristic = BLEIntCharacteristic(SEND_ENTER_UUID, BLEWrite | BLENotify);

BLEDescriptor textDescriptor  = BLEDescriptor("2901", "Keyin text");
BLEDescriptor enterDescriptor = BLEDescriptor("2901", "Keyin ENTER key");


//------ main ------

void setup() {
#if DEBUG
  Serial.begin(9600);
#endif

DLog("init!");
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  blePeripheral.setLocalName(MY_BLE_LOCAL_NAME);
  blePeripheral.setDeviceName(MY_BLE_LOCAL_NAME);
  blePeripheral.setAdvertisedServiceUuid(kbService.uuid());
  
  // add attributes (services, characteristics, descriptors) to peripheral
  blePeripheral.addAttribute(kbService);
  blePeripheral.addAttribute(textCharacteristic);
  blePeripheral.addAttribute(textDescriptor);
  blePeripheral.addAttribute(enterCharacteristic);
  blePeripheral.addAttribute(enterDescriptor);


  // assign event handlers for connected, disconnected to peripheral
  blePeripheral.setEventHandler(BLEConnected, blePeripheralConnectHandler);
  blePeripheral.setEventHandler(BLEDisconnected, blePeripheralDisconnectHandler);

  // assign event handlers for characteristic
  textCharacteristic.setEventHandler(BLEWritten, textCharacteristicWritten);
  enterCharacteristic.setEventHandler(BLEWritten, enterCharacteristicWritten);

  resetTextValue();
  enterCharacteristic.setValue(0);

  blePeripheral.begin();
  
  delay(1000);
  Keyboard.begin();
  
  ledFlashing();
  DLog("Start!");
}

void loop() {
  blePeripheral.poll();
}


//---- functions ----

void DLog(String str) {
#if DEBUG
  Serial.println(str);
#endif
}

void ledFlashing() {
  for (int i = 1; i <= 10; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(50);
    digitalWrite(LED_BUILTIN, LOW);
    delay(50);
  }
}

void resetTextValue() {
  textCharacteristic.setValue("                    ");  //=> 20 x Blank Char
}


//---- Callback : Connect & Disconnect ----

void blePeripheralConnectHandler(BLECentral& central) {
  DLog("Connected event, central: ");
  DLog(central.address());
}

void blePeripheralDisconnectHandler(BLECentral& central) {
  DLog("Disconnected event, central: ");
  DLog(central.address());
}


//---- Callback : Characteristic written ----

void textCharacteristicWritten(BLECentral& central, BLECharacteristic& characteristic) {
  DLog("textCharacteristic event, writen: ");
    
  int textLength = textCharacteristic.valueLength();
  String string = textCharacteristic.value();
  String text = string.substring(0, textLength);

  DLog("---------------");
  DLog(string);
  DLog("text length:");
  DLog(String(textLength));
  DLog("text:");
  DLog(text);

  Keyboard.print(text);
  resetTextValue();
}

void enterCharacteristicWritten(BLECentral& central, BLECharacteristic& characteristic) {
  DLog("enterCharacteristic event, writen: ");

  int sendEnter = enterCharacteristic.value();
  if (sendEnter > 0) {
    DLog("Send Enter Key.");
    Keyboard.press(KEY_RETURN);
    delay(20);
    Keyboard.releaseAll();
    enterCharacteristic.setValue(0);
  }
}
