using Toybox.ActivityRecording as ActivityRecording;

module RawStep {
    class SessionService {
        var _session;
        var _supported;
        var _errorMessage;

        function initialize() {
            _session = null;
            _errorMessage = null;
            _supported = ActivityRecording != null && ActivityRecording.respondsTo(:createSession);
        }

        function getErrorMessage() {
            return _errorMessage;
        }

        function isSupported() {
            return _supported;
        }

        function startSession() {
            _errorMessage = null;
            if (!_supported) {
                _errorMessage = @Strings.ErrorActivityRecording;
                return false;
            }
            if (_session != null) {
                return true;
            }
            var options = {
                :name => "Raw Step Activity",
                :sport => ActivityRecording.SPORT_RUNNING
            };
            _session = ActivityRecording.createSession(options);
            if (_session == null) {
                _errorMessage = @Strings.ErrorActivityRecording;
                return false;
            }
            if (_session.respondsTo(:start)) {
                _session.start();
            }
            return true;
        }

        function updateMetrics(steps, distance) {
            if (_session == null) {
                return;
            }
            if (_session.respondsTo(:setSteps)) {
                _session.setSteps(steps);
            } else if (_session.respondsTo(:setStepCount)) {
                _session.setStepCount(steps);
            }
            if (_session.respondsTo(:setDistance)) {
                _session.setDistance(distance);
            } else if (_session.respondsTo(:setTotalDistance)) {
                _session.setTotalDistance(distance);
            }
        }

        function stopSession(save) {
            if (_session == null) {
                return;
            }
            if (_session.respondsTo(:stop)) {
                _session.stop();
            }
            if (save) {
                if (_session.respondsTo(:save)) {
                    _session.save();
                }
            } else {
                if (_session.respondsTo(:discard)) {
                    _session.discard();
                }
            }
            _session = null;
        }
    }
}
