#!/bin/sh

if output="$("$@")"; then
  echo "$output"
else
  exit_code="$?"
  echo "$output" >&2
  exit "$exit_code"
fi
