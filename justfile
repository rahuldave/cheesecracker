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
