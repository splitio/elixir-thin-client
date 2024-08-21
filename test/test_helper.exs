ExUnit.start()

# supress logging output in  the console while testing
# we can still capture the log output in tests using `capture_log`
Logger.configure_backend(:console, level: :error)
