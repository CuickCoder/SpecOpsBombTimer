"""Forward Arduino serial messages to Godot over UDP."""

from __future__ import annotations

from collections import deque
from datetime import datetime
import socket
import time

try:
    import serial
    from serial.tools import list_ports
except ImportError:
    print("GodotSerialBridge requires pyserial.")
    print("Install it with: py -m pip install pyserial")
    input("Press Enter to close...")
    raise SystemExit(1)

DEFAULT_BAUD_RATE = 9600
GODOT_ADDRESS = ("127.0.0.1", 4242)
STATUS_UPDATE_INTERVAL = 1.0
MAX_CONSOLE_MESSAGES = 10
recent_console_messages = deque(maxlen=MAX_CONSOLE_MESSAGES)


def update_console(message: str = "") -> None:
    """Keep the header visible and show only the newest console messages."""
    if message:
        recent_console_messages.append(message)

    #clear the terminal and move the cursor back to its top-left corner
    print("\033[2J\033[H", end="")
    print("GodotSerialBridge")
    print("=================")
    print(f"Godot UDP: {GODOT_ADDRESS[0]}:{GODOT_ADDRESS[1]}")
    print(f"Baud rate: {DEFAULT_BAUD_RATE}")
    print()

    for console_message in recent_console_messages:
        print(console_message)


def send_bridge_status(godot_socket: socket.socket, message: str) -> None:
    """Send the bridge's current connection status to Godot."""
    godot_socket.sendto(message.encode("utf-8"), GODOT_ADDRESS)


def wait_for_arduino_port(godot_socket: socket.socket) -> str:
    """Wait until an Arduino serial port is found, then return it."""
    update_console("Waiting for the Arduino to be plugged in...")

    #keep checking the computer's serial ports until we find an Arduino
    while True:
        #tell godot that the bridge is running, but no Arduino has been found yet
        send_bridge_status(godot_socket, "BRIDGE_NO_ARDUINO")

        #get a list of all serial ports currently connected to the computer
        ports = list(list_ports.comports())

        #check the identifying information for each serial port
        for port in ports:
            #some ports do not provide these values, so use an empty string instead
            #lowercase them so that capitalization does not affect the search
            description = (port.description or "").lower()
            manufacturer = (port.manufacturer or "").lower()

            #if either value identifies the device as an Arduino, return its port name
            #to main(), which will pass it to monitor_serial_port()
            if "arduino" in description or "arduino" in manufacturer:
                update_console(f"Arduino detected on {port.device} - {port.description}")
                return port.device

        #no Arduino was found, so wait before checking every serial port again
        time.sleep(STATUS_UPDATE_INTERVAL)


def monitor_serial_port(port_with_arduino: str, baud_rate: int, godot_socket: socket.socket) -> None:
    """Connect to a serial port and forward complete lines to Godot."""
    update_console(f"Connecting to {port_with_arduino} at {baud_rate} baud...")

    try:
        #create a Serial object that represents the connection between python and the Arduino
        with serial.Serial(port_with_arduino, baud_rate, timeout=1) as connection:
            #it was succesful, so print something that says that
            update_console(f"Connected to {port_with_arduino}. Waiting for Arduino messages.")
            last_bridge_status_time = 0.0

            while True:
                #tell godot that this program is still running
                current_time = time.monotonic()
                if current_time - last_bridge_status_time >= STATUS_UPDATE_INTERVAL:
                    send_bridge_status(godot_socket, "BRIDGE_CONNECTED")
                    last_bridge_status_time = current_time

                #wait for and record a message from the arduino port. 
                #blocks program while doing so but only for the length of time specified 
                #by"timeout" in the constructor above
                #if arduino is disconnected readline() will error & exit us from the loop
                raw_serial_line = connection.readline() 
                if not raw_serial_line:
                    continue #jumps us back to the top of this while loop

                #convert that message to something readable and send it to godot
                converted_message = raw_serial_line.decode("utf-8", errors="replace").rstrip("\r\n")
                timestamp = datetime.now().strftime("%H:%M:%S")
                #sendto() sends a message but also returns the number of bytes sent as an int
                sent_bytes = godot_socket.sendto(converted_message.encode("utf-8"), GODOT_ADDRESS)

                #show the message we just sent if it wasn't just the connection check
                if converted_message != "ARDUINO_CONNECTION_CHECK":
                    update_console(
                        f"[{timestamp}] {converted_message} — "
                        f"forwarded {sent_bytes} bytes to Godot"
                    )

    #this exception gets called if readline() times out before seeing any messages 
    #from the arduinon in the serial port
    except serial.SerialException as error:
        update_console(
            f"Serial connection error: {error}\n"
            "Arduino disconnected. Returning to connection wait."
        )


#Python reads files from top to bottom, so we define and run main() at the end of the
#script so that all functions it uses have already been defined
def main() -> None:
    update_console()

    #create a UDP socket called godot_socket
    #this is the socket class constructor, the args here tell it to 
    #make it use IPv4 addresses (AF_INET) 
    #and use the UDP protocol (SOCK_DGRAM)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as godot_socket:
        while True:
            try:
                #continiously look for a serial port with an arduino
                arduino_port_name = wait_for_arduino_port(godot_socket)
                #read and send to godot the messages arduino has sent to that serial port
                monitor_serial_port(arduino_port_name, DEFAULT_BAUD_RATE, godot_socket)
                time.sleep(1)

            except KeyboardInterrupt:
                #catch Ctrl+C so the socket closes cleanly before the program exits
                break


if __name__ == "__main__":
    main()
