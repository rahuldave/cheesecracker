# cheesecracker: every task is a recipe here. `just` lists them.

# Each word after a recipe's name reaches its commands whole, as "$1", "$2" and so on; "$@" is all of them
set positional-arguments

[private]
default:
    @just --list --unsorted

# Install Python and every dependency into .venv, exactly as the lockfile says
setup:
    uv sync --locked

# Run the tests. Extra arguments go to pytest: just test tests/unit
test *args:
    uv run pytest "$@"

# Start the server on this machine, in the background, at http://localhost:9000. It restarts when a file of the code changes. just stop stops it
serve:
    #!/usr/bin/env sh
    if curl -sf localhost:9000/health > /dev/null; then echo "serve: a server already answers at http://localhost:9000" >&2; exit 1; fi
    uv run uvicorn api.service:app --app-dir src/api-service --host 0.0.0.0 --port 9000 --reload > .serve.log 2>&1 &
    echo $! > .serve.pid
    for i in $(seq 1 30); do
        if curl -sf localhost:9000/health > /dev/null; then echo "serve: http://localhost:9000, its log in .serve.log"; exit 0; fi
        sleep 1
    done
    echo "serve: no answer after 30 seconds; read .serve.log" >&2
    exit 1

# Stop the server of just serve
stop:
    #!/usr/bin/env sh
    if [ ! -f .serve.pid ]; then echo "stop: no server of just serve runs here" >&2; exit 1; fi
    kill "$(cat .serve.pid)" && rm .serve.pid
    # Wait until the server no longer answers, so that the port is free for the next one
    for i in $(seq 1 30); do
        if ! curl -s localhost:9000/health > /dev/null; then echo "stop: stopped"; exit 0; fi
        sleep 1
    done
    echo "stop: the server still answers after 30 seconds" >&2
    exit 1
