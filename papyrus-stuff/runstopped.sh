#!/bin/bash
echo "Running '$@' in a stopped state."
echo "To continue it: kill -CONT $$"
kill -STOP $$
exec "$@"
