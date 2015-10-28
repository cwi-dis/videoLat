Lightphone - what it does
=========================

The lightphone allows you to measure light levels with the microphone input of
your iPhone, MacBook or other device, and it allows you to control the brightness
of an LED through the headphone output.

Response time for the device itself is very fast: LED control has a reaction 
time far below a millisecond, light sensing depends on level but can also below a
millisecond for bright light. You do need to add audio input and output processing
delay of your iPhone or computer, but these tend to be low, and moreover they
are constant, and can be measured with this device.

Theory of operation
===================

Input and output are completely separate. Output (audio signal to light) is
easiest to explain: if the Left and Right channel of the audio signal are the
same voltage the LED is off, if they are a different voltage the LED is on.
In other words, if you play a mono sound the LED will be off, if you play a
stereo sound the LED will be on most of the time. By carefully constructing
the audio signal in software you can control the LED down to the sample frequency,
which is usually 44Khz.

Light measurement is done with a phototransistor, which detects light and outputs
a tiny voltage that is higher when the light is brighter. This voltage is used
to drive a VCO (Voltage Controlled Oscillator). VCOs are primarily known from
music synthesizers: they produce a tone that depends on the input voltage. High
voltage means high-pitched tone, low voltage means low pitched tone. Most people
think that the tone sounds rather horrible, whether high or low, but that is not
the point as we will not hear it, usually. The tone is fed to the software on
the iPhone or computer, which will determine the tone by measuring how long it
takes until the phase changes. This, in turn, reflects the light level. Measuring
the lowest light level means that it takes long before a phase change occurs, but
if the device is adjusted that the lowest frequency is 1000Hz it will take 1 millisecond
at most.

The VCO circuitry is based on a circuit that you find everywhere when you
google for images with "vco op amp", for example at http://i.stack.imgur.com/9lWYE.png,
with the capacitor value lowered to give a more usable frequency range for our application.

Schematic
=========

The schematic is in lightphone-schematic.pdf. The MCP6004 is a quad opamp that
has reel-to-reel inputs and outputs and operates at voltages between 1.8V and
6V. Both the "reel-to-reel" and low-voltage aspects are important, if you decide
to use a different opamp.

Phototransistor Q2 detects the light, and the R2 trimpot sets the base point. It
can be adjusted to control lowest output level (hence darkness output frequency).

Having the collector at V+ and using the emitter as output is not standard but
with emitter at V- and collector as output I didn't get things to work. I think
this setup results in non-linear light-to-frequency, but I'm not sure the
transistor is linear in the first place.

Opamp C is a triangular wave generator, driven by Q2/R9 for the upward flank and R10/R11/C3
for the downward flank. Opamp D is a schmitt trigger that charges/discharges C3 through
Q3 and reverses the flank of the sawtooth. To change the base frequency play with C3,
but R10/R11/R9 can also be used. Keep the ratios of those three resistors as they are, though.

The opamp C output (the triangular wave) is the output signal. Level is controlled
with R3 (set at something like 10 mV). C2 and R4 are for decoupling and attempt
to mimick and Apple headset microphone (more on that later).

The R1 trimpot is set at the halfway point, and creates a virtual analog ground between
V+ and V- (with C1 for AC-decoupling). Values for R1 and C1 are pretty random.

On the light output side, the L and R signals are fed straight into IN+ and IN-
of opamp A, and the output drives LED1 through current limiting resistor R3.
The value of R3 depends on the LED and on the opamp used. The MCP6004 can drive
6mA at 1.8V to 23mA at 6V, so that gives a lower bound on the resistor. The LED
I used was pretty bright with 1Kohm (which should be about 6mA), and needed a
forward voltage of 3V before lighting at all.

LED2 and R14 are simply to show you that the device is on (so you don't forget
to turn it off to save batteries).

S1, the TRRS socket, R4 and C2 deserve special mention. 
Apple devices attempt to auto-detect what you plug into their 3.5mm jack plug
socket: a normal stereo headset, and apple headset with microphone, or even
all sorts of other things like optical toslink plugs and such. R4, a 2.2Kohm
resistor between tip and ring 2, should tell the device that a headset is
attached. This seems to work with iPhones and with older MacBooks, but newer
macbooks (I tried a MacBook Pro late 2014) are not fooled, for some reason.

Luckily, it seems that the auto-detection is only done the moment you insert
the audio plug. Therefore, S1 not only switches power on but also toggles
the microphone input on the TRRS plug (the sleeve) between being connected
to our circuit (when power is on) or to the TRRS socket (when power is off).

So if the iPhone or mac does not recognize the lightphone and continues
getting audio from the builtin microphone the trick is to do the following:
- turn off and unplug lightphone
- plug Apple headset into the TRRS socket
- plug lightphone TRRS plug into phone or computer
- (optionally use Audio Preferences or something to check the external input is used)
- turn on the lightphone.

To make matters worse I have also come across devices wher this does _not_
work, but simply plugging in the lightphone while it is on does work. Go
figure.....

Construction
============

If you're not using identical components as I used look at Fritzing file
lightphone.fzz, which has a breadboard layout. If you build this first you can
experiment more easily with different resistor values and such. You may need to
import MCP6004.fzpz.

If you want to dive right in look at the stripboard layout in lightphone-stripboard.pdf
(or the Fritzing sourcefile, lightphone-stripboard.fzz). Construction is
straightforward, with one exception: TRRS plugs are absolutely horrendous to solder.
Eventually it turned out that by far the easiest was to buy an iPhone headset
extension cable, cut it into two, and work with the (still tiny) wires in
the cable.

lightphone-assembly.jpg is a picture of the device before it was put into a case
(and before the LED2/R14 power indicator were added).
 

