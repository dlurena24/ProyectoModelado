import serial
from pynput.mouse import Controller
from pynput.mouse import Button
import time

SERIAL_PORT = '/dev/ttyACM1'
BAUD_RATE = 115200
CENTER_X = 329
CENTER_Y = 337
DEAD_ZONE = 10
SPEED_MULTIPLIER = 5

mouse = Controller()

def main():
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    time.sleep(0.0001)

    while True:
        try:
            line = ser.readline().decode('utf-8').strip()
            if line:
                parts = line.split(' - ')
                print(parts)
                ejeX = int(parts[0].split(':')[1].strip())
                ejeY = int(parts[1].split(':')[1].strip())
                Buttons_str = parts[3]
                botones = Buttons_str.split()

                b_index = botones.index('B:')
                b_val = int(botones[b_index + 1])
                c_index = botones.index('C:')
                c_val = int(botones[c_index + 1])

                offsetX = ejeX - CENTER_X
                offsetY = ejeY - CENTER_Y

                if abs(offsetX) < DEAD_ZONE:
                        offsetX = 0
                if abs(offsetY) < DEAD_ZONE:
                    offsetY = 0

                move_x = int(offsetX / (512/10)) * SPEED_MULTIPLIER
                move_y = int(offsetY / (512/10)) * SPEED_MULTIPLIER

                move_y = -move_y
                mouse.move(move_x, move_y)
                if b_val == 1:
                    mouse.press(Button.left)
                else:
                    mouse.release(Button.left)
                if c_val == 1:
                    mouse.press(Button.right)
                else:
                    mouse.release(Button.right)



        except Exception as e:
            print(f"Error: {e}")


if __name__ == "__main__":
    main()
