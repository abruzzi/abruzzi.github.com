#!/bin/bash

bundle exec rake gen_deploy && git push origin source
