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


