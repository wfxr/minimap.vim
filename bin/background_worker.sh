#!/usr/bin/env bash

echo "$1"
gwc -L "$1" | choose 0
