using Toybox.Graphics as Graphics;
using Toybox.Lang;
using Toybox.Sensor as Sensor;
using Toybox.System as System;
using Toybox.WatchUi as WatchUi;

module RawStep {
    class MainView extends WatchUi.View {
        const SAMPLE_PERIOD_MS = 40;

        var _state;
        var _detector;
        var _sessionService;
        var _hasAccelerometer;
        var _accelActive;
        var _lastUiUpdate;

        function initialize(state, detector, sessionService) {
            WatchUi.View.initialize();
            _state = state;
            _detector = detector;
            _sessionService = sessionService;
            _accelActive = false;
            _lastUiUpdate = 0;
        }

        function onShow() {
            if (_state[:running]) {
                _registerAccelerometer();
            }
        }

        function onHide() {
            _unregisterAccelerometer();
        }

        function onLayout(dc) {
        }

        function onUpdate(dc) {
            var width = dc.getWidth();
            var height = dc.getHeight();
            dc.clear();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.2, Graphics.FONT_LARGE, "Steps", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, height * 0.35, Graphics.FONT_NUMBER_HOT, _formatInt(_state[:steps]), Graphics.TEXT_JUSTIFY_CENTER);

            dc.drawText(width / 2, height * 0.55, Graphics.FONT_LARGE, "Distance (m)", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, height * 0.7, Graphics.FONT_NUMBER_MEDIUM, _formatDistance(_state[:distance]), Graphics.TEXT_JUSTIFY_CENTER);

            var statusString = _state[:running] ? Application.loadResource(Rez.Strings.StatusRunning) : Application.loadResource(Rez.Strings.StatusStopped);
            dc.drawText(width / 2, height * 0.85, Graphics.FONT_LARGE, statusString, Graphics.TEXT_JUSTIFY_CENTER);

            if (!_hasAccelerometer) {
                dc.drawText(width / 2, height * 0.92, Graphics.FONT_SMALL, Application.loadResource(Rez.Strings.ErrorNoAccelerometer), Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                var error = _state[:sessionError];
                if (error != null) {
                    dc.drawText(width / 2, height * 0.92, Graphics.FONT_SMALL, error, Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
            _lastUiUpdate = System.getTimer();
        }

        function _formatInt(value) {
            return Lang.format("%d", [value]);
        }

        function _formatDistance(distance) {
            return Lang.format("%.1f", [distance]);
        }

        function onKey(key, state) {
            if (state != WatchUi.KEY_DOWN) {
                return false;
            }
            if (key == WatchUi.KEY_START || key == WatchUi.KEY_ENTER) {
                if (_state[:running]) {
                    stopActivity(true);
                } else {
                    startActivity();
                }
                WatchUi.requestUpdate();
                return true;
            }
            return false;
        }

        function startActivity() {
            if (_state[:running]) {
                return;
            }
            _state[:steps] = 0;
            _state[:distance] = 0.0;
            _state[:sessionError] = null;
            _detector.reset();
            _state[:running] = true;
            var started = _sessionService != null ? _sessionService.startSession() : true;
            if (!started && _sessionService != null) {
                _state[:sessionError] = _sessionService.getErrorMessage();
            }
            _registerAccelerometer();
        }

        function stopActivity(save) {
            if (!_state[:running]) {
                return;
            }
            _state[:running] = false;
            _unregisterAccelerometer();
            if (_sessionService != null) {
                _sessionService.updateMetrics(_state[:steps], _state[:distance]);
                _sessionService.stopSession(save);
                _state[:sessionError] = _sessionService.getErrorMessage();
            }
        }

        function _registerAccelerometer() {
            if (_accelActive) {
                return;
            }
            var options = { 
                :period => SAMPLE_PERIOD_MS,
                :accelerometer => {
                    :enabled => true,       // Enable the accelerometer
                    :sampleRate => 25       // 25 samples
                }
            };
            Sensor.registerSensorDataListener(method(:onAccelData), options);
            _accelActive = true;
        }

        function _unregisterAccelerometer() {
            if (!_accelActive) {
                return;
            }
            Sensor.unregisterSensorDataListener();
            _accelActive = false;
        }

        function onAccelData(data as Sensor.SensorData)as Void {
            var newSteps = _detector.addSamples(data);
            if (newSteps > 0) {
                _state[:steps] += newSteps;
                _state[:distance] = _state[:steps] * _state[:stepLength];
                if (_sessionService != null) {
                    //_sessionService.updateMetrics(_state[:steps], _state[:distance]);
                }
            }
            var now = System.getTimer();
            if (now - _lastUiUpdate >= 900) {
                WatchUi.requestUpdate();
            }
        }

        function onAppBackground() {
            _unregisterAccelerometer();
        }

        function onAppResume() {
            if (_state[:running]) {
                _registerAccelerometer();
            }
        }
    }
}
