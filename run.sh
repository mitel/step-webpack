#!/bin/bash

# return true if local npm package is installed at ./node_modules, else false
# example
# echo "webpack : $(npm_package_is_installed webpack)"
npm_package_is_installed() {
  # set to true initially
  local return_=true
  # set to false if not found
  ls node_modules | grep "$1" >/dev/null 2>&1 || { local return_=false; }
  # return value
  echo "$return_"
}

# First make sure webpack is installed
if ! type webpack &> /dev/null ; then
    # Check if it is in the local node_modules repo
    if ! $(npm_package_is_installed webpack) ; then
        info "webpack is not installed, trying to install it through npm"

        if ! type npm &> /dev/null ; then
            fail "npm not found, make sure you have npm or webpack installed"
        else
            info "npm is available"
            debug "npm version: $(npm --version)"

            info "installing webpack"
            sudo npm install -g webpack
            webpack_command="webpack"
        fi
    else
        info "webpack is available locally"
        debug "webpack version: $(npm list webpack |grep webpack)"
        webpack_command="./node_modules/webpack/bin/webpack.js"
    fi
else
    info "webpack is available"
    debug "webpack version: $(npm list -g webpack |grep webpack)"
    webpack_command="webpack"
fi

# Parse some variable arguments
if [ "$WERCKER_WEBPACK_NODE_ENV" = "true" ] ; then
    webpack_command="NODE_ENV=$WERCKER_WEBPACK_NODE_ENV $webpack_command"
fi

if [ "$WERCKER_WEBPACK_VERBOSE" = "true" ] ; then
    webpack_command="$webpack_command --verbose"
fi

if [ "$WERCKER_COLORS" = "true" ] ; then
    webpack_command="$webpack_command --colors"
fi

if [ "$WERCKER_WEBPACK_DISPLAY_ERROR_DETAILS" = "true" ] ; then
    webpack_command="$webpack_command --display-error-details"
fi

if [ -n "$WERCKER_WEBPACK_CONFIG_FILE" ] ; then
    webpack_command="$webpack_command --config $WERCKER_WEBPACK_CONFIG_FILE"
fi

debug "$webpack_command"

set +e
$webpack_command
result="$?"
set -e

# TODO: fail on warning flag
if [[ $result -eq 0 ]]; then
  success "finished $webpack_command"
elif [[ $result -eq 6 && "$WERCKER_WEBPACK_FAIL_ON_WARNINGS" != 'true' ]]; then
  warn "webpack returned warnings, however fail-on-warnings is not true"
  success "finished $webpack_command"
else
    warn "webpack exited with exit code: $result"
    fail "webpack failed"
fi
