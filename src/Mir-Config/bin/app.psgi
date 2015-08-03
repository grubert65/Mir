#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mir::Config;
Mir::Config->to_app;
