using Toybox.ActivityRecording as ActivityRecording;

module RawStep {
    class SessionService {
        var _session;
        var _supported;
        var _errorMessage;

        function initialize() {
            _session = null;
            _errorMessage = null;
            _supported = ActivityRecording != null; // && ActivityRecording.respondsTo(:createSession);
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
                _errorMessage = Application.loadResource(Rez.Strings.ErrorActivityRecording);
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
                _errorMessage = Application.loadResource(Rez.Strings.ErrorActivityRecording);
                return false;
            }
            _session.start();
            return true;
        }

        function updateMetrics(steps, distance) {
            if (_session == null) {
                return;
            }
        }

        function stopSession(save) {
            if (_session == null) {
                return;
            }
            _session.stop();
            _session.save();
            _session.discard();
            _session = null;
        }
    }
}
