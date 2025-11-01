# Raw Step Activity Watch App

Raw Step Activity is a Connect IQ watch app that tracks steps and distance from raw accelerometer data and records them in a FIT activity when the user stops the session.

## Requirements

- Garmin Connect IQ SDK 4.1 or newer
- `monkeyc`, `monkeydo`, and the Connect IQ simulator included with the SDK
- A fenix 7 family device profile (e.g., `fenix7xpro`) installed in the simulator

## Project Structure

```
manifest.xml             # Application manifest and permissions
monkey.jungle            # Build configuration
resources/               # Shared resources, strings, and settings schema
source/                  # Monkey-C implementation
    App.mc
    MainView.mc
    SessionService.mc
    StepDetector.mc
tests/                   # Unit tests for the step detector
    test_step_detector.mc
```

## Building

1. Ensure the Connect IQ SDK `bin` directory is on your `PATH`.
2. From the project root, build the PRG for a fenix 7 target:

   ```sh
   monkeyc -f monkey.jungle -d fenix7xpro -o bin/RawStepActivity.prg
   ```

3. To run in the simulator:

   ```sh
   monkeydo bin/RawStepActivity.prg fenix7xpro
   ```

   The app displays step count, distance, and current status. Press the **START** key to toggle between running and stopped states.

## Unit Tests

Run the unit tests with:

```sh
monkeyc -f monkey.jungle -d fenix7xpro -t
```

This executes the synthetic accelerometer scenarios defined in `tests/test_step_detector.mc` and verifies the step-detection pipeline.

## Settings

The app exposes a single numeric setting `Step Length (m)` (default 1.0). You can change it via Garmin Express, Garmin Connect Mobile, or the simulator settings dialog. The in-app default remains 1.0 m if the setting is not configured.

## Step-Detection Algorithm

1. Samples the accelerometer at 25 Hz (`period = 40 ms`).
2. Maintains a short moving average window (~1 s) to remove gravity and obtain high-pass filtered motion.
3. Computes the magnitude of the filtered acceleration vector.
4. Tracks an adaptive baseline (exponential moving average) and deviation to derive a dynamic threshold with a minimum amplitude clamp.
5. Detects peaks when the magnitude crosses the threshold and enforces a 280 ms refractory window to prevent double counting.
6. Step count is multiplied by the configured step length to estimate distance in meters.

## Activity Recording

When activity recording is supported on the target device, the app creates a session tagged as running, updates step count and distance metrics during sampling, and finalizes the FIT file on stop. If the API is unavailable, the watch UI continues to operate, and an informational status message is shown on screen.

## Notes

- The app requests the `Sensor` and `ActivityRecording` permissions required for accelerometer access and FIT activity generation.
- Accelerometer listeners are released while the app is stopped or when it transitions to the background to preserve battery life.
- The UI refresh rate is throttled to approximately 1 Hz while running to limit draw calls.
