#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bundle exec pry -I $DIR/../lib -r "$DIR/focus-repl"
