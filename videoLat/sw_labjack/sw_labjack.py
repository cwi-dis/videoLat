import u3
import time

class MyLabJack:
    OUTPUT_PORT=4   # Led attached to FIO4
    INPUT_PORT=5    # Phototransistor attached to FIO5
    
    def __init__(self):
        self.d = u3.U3()
        # Configure all ports as digital
        self.d.configIO(0)
        # Configure the output port as output, input as input
        self.d.getFeedback([
            u3.BitDirWrite(self.INPUT_PORT, 0),
            u3.BitDirWrite(self.OUTPUT_PORT, 1)
            ])
        # Store commands, for easy reference
        self.out_cmd = [
            u3.BitStateWrite(self.OUTPUT_PORT, 0),
            u3.BitStateWrite(self.OUTPUT_PORT, 1)
            ]
        self.in_cmd = u3.BitStateRead(self.INPUT_PORT)
         
    def output(self, value):
        self.d.getFeedback(self.out_cmd[value])
        
    def input(self):
        return self.d.getFeedback(self.in_cmd)[0]
        
def _test():
    """Output lowest bit of system time (in seconds) to the LED,
    and print the value read from the photodiode"""
    lj = MyLabJack()
    while True:
        lj.output(int(time.time()) & 1)
        print lj.input()
