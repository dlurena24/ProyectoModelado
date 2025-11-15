const int pinX = A0;  // Eje X del joystick
const int pinY = A1;  // Eje Y del joystick
const int pinSW = 8;  // Botón del joystick

const int btnA = 2;
const int btnB = 3;
const int btnC = 4;
const int btnD = 5;
const int btnE = 6;
const int btnF = 7;
const int ledPinG = 13;
const int ledPinR = 12;

void setup() {
  Serial.begin(9600);
  pinMode(pinSW, INPUT_PULLUP);
  pinMode(btnA, INPUT_PULLUP);
  pinMode(btnB, INPUT_PULLUP);
  pinMode(btnC, INPUT_PULLUP);
  pinMode(btnD, INPUT_PULLUP);
  pinMode(btnE, INPUT_PULLUP);
  pinMode(btnF, INPUT_PULLUP);
  pinMode(ledPinG, OUTPUT);
  pinMode(ledPinR, OUTPUT);
}

void loop() {
  int ejeX = analogRead(pinX);
  int ejeY = analogRead(pinY);
  int boton = digitalRead(pinSW);

  bool deadX = ejeX < 330 || ejeX > 360;
  bool deadY = ejeY > 380 || ejeY <335;

  int a = !digitalRead(btnA);
  int b = !digitalRead(btnB);
  int c = !digitalRead(btnC);
  int d = !digitalRead(btnD);
  int e = !digitalRead(btnE);
  int f = !digitalRead(btnF);

  if (a || b || c || d || e || f ) {
    digitalWrite(ledPinG, HIGH);
  }else {
    digitalWrite(ledPinG, LOW);
  }

  if (deadX || deadY){
    digitalWrite(ledPinR, HIGH);
  }else {
    digitalWrite(ledPinR, LOW);
  }

  Serial.print("Eje X: "); Serial.print(ejeX);
  Serial.print(" - Eje Y: "); Serial.print(ejeY);
  Serial.print(" - JoyBtn: "); Serial.print(!boton);

  Serial.print(" - A: "); Serial.print(a);
  Serial.print(" B: "); Serial.print(b);
  Serial.print(" C: "); Serial.print(c);
  Serial.print(" D: "); Serial.print(d);
  Serial.print(" E: "); Serial.print(e);
  Serial.print(" F: "); Serial.println(f);

  delay(200);
}
