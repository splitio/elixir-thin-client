# TODO

**General:**
- [] Put modules into split context except `split.ex`
- [] Write moduledocs and docs for ExDoc
- [] Write README docs
- [] Figure out integration tests
- [] Setup CI (GHA)
- [] Setup versioning/releases

**Pool `Split.Sockets.Pool`:**
- [] L59 Check if we have to error here to not start a disconnected worker to the pool
- [] Check for socket reconnections
- [] Pass opts to the worker with pool size.
- [] Pool should be async and not block trying to establish a connection

**RPC `Split.RPC`:**

- [] Maybe refactor to a with statement and handle errors
- [] Should we really use the process dictionary for caching? This is ok for HTTP requests where we have a process per request
