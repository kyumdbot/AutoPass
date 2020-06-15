#include <Keyboard.h>
#include <ArduinoBLE.h>

#define  DEBUG  0

#define  SERVICE_UUID     "0000BE00-0000-1000-8000-00805F9B34FB"
#define  INPUT_TEXT_UUID  "0000BE01-0000-1000-8000-00805F9B34FB"
#define  SEND_ENTER_UUID  "0000BE02-0000-1000-8000-00805F9B34FB"

#define  MY_BLE_LOCAL_NAME  "AutoPass_wcling"
#define  MAX_TEXT_LENGTH    20

BLEService kbService(SERVICE_UUID);
BLEStringCharacteristic textCharacteristic(INPUT_TEXT_UUID, BLEWrite | BLENotify, MAX_TEXT_LENGTH);
BLEBoolCharacteristic enterCharacteristic(SEND_ENTER_UUID, BLEWrite | BLENotify);


//------ main ------

void setup() {

#if DEBUG
  Serial.begin(9600);
#endif
  
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  
  if (!BLE.begin()) {
    DLog("Starting BLE failed!");
    while (1);
  }
  
  // set the name peripheral advertises
  BLE.setDeviceName(MY_BLE_LOCAL_NAME);
  BLE.setLocalName(MY_BLE_LOCAL_NAME);
  
  // set the UUID for the service this peripheral advertises
  BLE.setAdvertisedService(kbService);

  // add the characteristic to the service
  kbService.addCharacteristic(textCharacteristic);
  kbService.addCharacteristic(enterCharacteristic);

  // add service
  BLE.addService(kbService);

  // assign event handlers for connected, disconnected to peripheral
  BLE.setEventHandler(BLEConnected, blePeripheralConnectHandler);
  BLE.setEventHandler(BLEDisconnected, blePeripheralDisconnectHandler);

  // assign event handlers for characteristic
  textCharacteristic.setEventHandler(BLEWritten, textCharacteristicWritten);
  enterCharacteristic.setEventHandler(BLEWritten, enterCharacteristicWritten);

  // set an initial value for the characteristic
  textCharacteristic.setValue("");
  enterCharacteristic.setValue(false);

  // start advertising
  BLE.advertise();

  DLog("Bluetooth device active, waiting for connections...");

  Keyboard.begin();
}

void loop() {
  // poll for BLE events
  BLE.poll();
}

void DLog(String str) {
#if DEBUG
  Serial.println(str);
#endif
}


//---- Callback : Connect & Disconnect ----

void blePeripheralConnectHandler(BLEDevice central) {
  // central connected event handler
  DLog("Connected event, central: ");
  DLog(central.address());
  
  digitalWrite(LED_BUILTIN, HIGH);  //LED ON
}

void blePeripheralDisconnectHandler(BLEDevice central) {
  // central disconnected event handler
  DLog("Disconnected event, central: ");
  DLog(central.address());
  
  digitalWrite(LED_BUILTIN, LOW);  //LED OFF
}


//---- Callback : Characteristic written ----

void textCharacteristicWritten(BLEDevice central, BLECharacteristic characteristic) {
  DLog("textCharacteristic event, written: ");
  
  if (textCharacteristic.valueLength() <= MAX_TEXT_LENGTH) {
    String text = textCharacteristic.value();
    DLog(text);
    Keyboard.print(text);
  }
}

void enterCharacteristicWritten(BLEDevice central, BLECharacteristic characteristic) {
  DLog("enterCharacteristic event, written: ");
  bool isSendEnter = enterCharacteristic.value();
  
  if (isSendEnter) {
    DLog("Send Enter Key.");
    Keyboard.press(KEY_RETURN);
    delay(20);
    Keyboard.releaseAll();
  }
}
