using Toybox.Math as Math;
using Toybox.Lang;

module RawStep {
    /**
     * StepDetector implements a simple high-pass filtered peak detector that counts
     * steps from raw accelerometer samples.
     */
    class StepDetector {
        const DEFAULT_GRAVITY_WINDOW = 25; // samples (~1 s at 25 Hz)
        const DEFAULT_MIN_THRESHOLD = 0.9;
        const DEFAULT_SENSITIVITY = 1.2;
        const DEFAULT_ALPHA = 0.05;
        const DEFAULT_BETA = 0.05;
        const DEFAULT_REFRACTORY_MS = 280;
        const DEFAULT_SAMPLE_PERIOD_MS = 40; // 25 Hz

        var _gravityWindow;
        var _samplePeriodMs;
        var _minThreshold;
        var _sensitivity;
        var _alpha;
        var _beta;
        var _refractoryMs;

        var _buffer;
        var _sumX;
        var _sumY;
        var _sumZ;
        var _stepCount;
        var _avgMag;
        var _avgDeviation;
        var _lastAboveThreshold;
        var _lastStepTimestamp;
        var _lastSampleTimestamp;

        function initialize(options) {
            if (options == null) {
                options = {};
            }
            _gravityWindow = options[:gravityWindow] != null ? options[:gravityWindow] : DEFAULT_GRAVITY_WINDOW;
            _samplePeriodMs = options[:samplePeriodMs] != null ? options[:samplePeriodMs] : DEFAULT_SAMPLE_PERIOD_MS;
            _minThreshold = options[:minThreshold] != null ? options[:minThreshold] : DEFAULT_MIN_THRESHOLD;
            _sensitivity = options[:sensitivity] != null ? options[:sensitivity] : DEFAULT_SENSITIVITY;
            _alpha = options[:alpha] != null ? options[:alpha] : DEFAULT_ALPHA;
            _beta = options[:beta] != null ? options[:beta] : DEFAULT_BETA;
            _refractoryMs = options[:refractoryMs] != null ? options[:refractoryMs] : DEFAULT_REFRACTORY_MS;
            reset();
        }

        function reset() {
            _buffer = [];
            _sumX = 0;
            _sumY = 0;
            _sumZ = 0;
            _stepCount = 0;
            _avgMag = null;
            _avgDeviation = null;
            _lastAboveThreshold = false;
            _lastStepTimestamp = -1000000;
            _lastSampleTimestamp = null;
        }

        function getStepCount() {
            return _stepCount;
        }

        /**
         * Adds a batch of accelerometer samples. Returns the number of detected steps in the batch.
         */
        function addSamples(samples) {
            if (samples == null) {
                return 0;
            }
            var newSteps = 0;
            foreach (var sample in samples) {
                if (sample == null) {
                    continue;
                }
                var timestamp = sample[:timestamp];
                if (timestamp == null) {
                    if (_lastSampleTimestamp == null) {
                        timestamp = 0;
                    } else {
                        timestamp = _lastSampleTimestamp + _samplePeriodMs;
                    }
                }
                _lastSampleTimestamp = timestamp;

                var x = sample[:x];
                var y = sample[:y];
                var z = sample[:z];

                if (x == null || y == null || z == null) {
                    continue;
                }

                _buffer.add({ :x => x, :y => y, :z => z });
                _sumX += x;
                _sumY += y;
                _sumZ += z;

                if (_buffer.size() > _gravityWindow) {
                    var removed = _buffer.remove(0);
                    _sumX -= removed[:x];
                    _sumY -= removed[:y];
                    _sumZ -= removed[:z];
                }

                var currentWindowSize = _buffer.size();
                if (currentWindowSize == 0) {
                    continue;
                }
                var avgX = _sumX / currentWindowSize;
                var avgY = _sumY / currentWindowSize;
                var avgZ = _sumZ / currentWindowSize;

                var filteredX = x - avgX;
                var filteredY = y - avgY;
                var filteredZ = z - avgZ;

                var magnitude = Math.sqrt(filteredX * filteredX + filteredY * filteredY + filteredZ * filteredZ);

                if (_avgMag == null) {
                    _avgMag = magnitude;
                } else {
                    _avgMag += _alpha * (magnitude - _avgMag);
                }

                var deviation = Math.abs(magnitude - _avgMag);
                if (_avgDeviation == null) {
                    _avgDeviation = deviation;
                } else {
                    _avgDeviation += _beta * (deviation - _avgDeviation);
                }

                var dynamicThreshold = _avgMag + Math.max(_minThreshold, _sensitivity * (_avgDeviation != null ? _avgDeviation : 0));
                var above = magnitude > dynamicThreshold;
                if (above && !_lastAboveThreshold) {
                    if (_lastSampleTimestamp == null || (timestamp - _lastStepTimestamp) >= _refractoryMs) {
                        _stepCount += 1;
                        newSteps += 1;
                        _lastStepTimestamp = timestamp;
                    }
                }
                _lastAboveThreshold = above;
            }
            return newSteps;
        }
    }
}
