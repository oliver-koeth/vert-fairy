using Toybox.Math as Math;
using Toybox.Test as Test;

using RawStep;

module RawStepTests {
    (:test)
    function testStationaryNoise() {
        var detector = new RawStep.StepDetector({ :samplePeriodMs => 40 });
        var samples = _generateNoiseSamples(400, 40);
        detector.addSamples(samples);
        Test.assertEqual(0, detector.getStepCount());
    }

    (:test)
    function testSimpleSteps() {
        var detector = new RawStep.StepDetector({ :samplePeriodMs => 40 });
        var samples = _generateStepWave(10, 12, 1.6);
        detector.addSamples(samples);
        Test.assertEqual(10, detector.getStepCount());
    }

    (:test)
    function testRefractoryPreventsDoubleCount() {
        var detector = new RawStep.StepDetector({ :samplePeriodMs => 40 });
        var samples = [];
        var timestamp = 0;
        for (var i = 0; i < 2; i += 1) {
            var magnitude = (i == 0) ? 2.5 : 2.2;
            samples.add({ :x => 0, :y => 0, :z => 9.8 + magnitude, :timestamp => timestamp });
            timestamp += 60;
        }
        detector.addSamples(samples);
        Test.assertEqual(1, detector.getStepCount());
    }

    (:test)
    function testDistanceComputation() {
        var detector = new RawStep.StepDetector({ :samplePeriodMs => 40 });
        var samples = _generateStepWave(6, 12, 1.8);
        detector.addSamples(samples);
        var steps = detector.getStepCount();
        Test.assertEqual(6, steps);
        var stepLength = 1.0;
        var distance = steps * stepLength;
        Test.assertEqual(6.0, distance);
    }

    (:test)
    function _generateNoiseSamples(count, periodMs) {
        var samples = [];
        var timestamp = 0;
        for (var i = 0; i < count; i += 1) {
            var noise = ((Math.rand() % 200) - 100) / 500.0;
            samples.add({
                :x => noise,
                :y => -noise,
                :z => 9.8 + noise,
                :timestamp => timestamp
            });
            timestamp += periodMs;
        }
        return samples;
    }

    (:test)
    function _generateStepWave(stepCount, samplesPerStep, amplitude) {
        var samples = [];
        var timestamp = 0;
        for (var step = 0; step < stepCount; step += 1) {
            for (var i = 0; i < samplesPerStep; i += 1) {
                var phase = i / samplesPerStep;
                var wave = amplitude * Math.sin(Math.PI * phase);
                samples.add({
                    :x => 0,
                    :y => 0,
                    :z => 9.8 + wave,
                    :timestamp => timestamp
                });
                timestamp += 40;
            }
        }
        return samples;
    }
}
