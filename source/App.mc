using Toybox.Application as Application;

module RawStep {
    class App extends Application.AppBase {
        var _state;
        var _view;
        var _detector;
        var _sessionService;

        function initialize() {
            Application.AppBase.initialize();
            _state = {
                :running => false,
                :steps => 0,
                :distance => 0.0,
                :stepLength => 1.0,
                :sessionError => null
            };
            _detector = new StepDetector({ :samplePeriodMs => 40 });
            _sessionService = new SessionService();
            _sessionService.initialize();
        }

        function onStart(state) {
            _sessionService.initialize();
            _loadSettings();
            if (state != null) {
                foreach (var key, var value in state) {
                    _state[key] = value;
                }
            }
            if (_view == null) {
                _view = new MainView(_state, _detector, _sessionService);
            }
            return [_view];
        }

        function onStop(state) {
            return _state;
        }

        function onPause() {
            if (_view != null) {
                _view.onAppBackground();
            }
        }

        function onResume() {
            _loadSettings();
            if (_view != null) {
                _view.onAppResume();
            }
        }

        function onSettingsChanged() {
            _loadSettings();
        }

        function _loadSettings() {
            var value = getProperty("step_length");
            if (value == null) {
                _state[:stepLength] = 1.0;
            } else {
                _state[:stepLength] = value;
            }
        }
    }
}
