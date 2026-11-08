#!/bin/bash
# unit output dir from extra.cfg (-FUlib/$FPCTARGET/); fpc does not create it
mkdir -p "lib/$(fpc -iTP)-$(fpc -iTO)"
fpc echo.lpr @extra.cfg
