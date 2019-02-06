#!/bin/bash

set -e

function catscript {
	echo -n '#!'
	which -- bash
	cat -- script.sh
}

exec install -v -- <(catscript) ~/.local/bin/git-gcs
