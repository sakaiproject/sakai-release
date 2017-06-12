#!/usr/bin/ruby 
#
# Script to get old etherpad archives from etherpad.ctools.org
require 'date'

firstThursday = Date.new(2011,5,19)
lastThursday = Date.new(2015,9,17)

firstTuesday = Date.new(2015,9,22)

now = Date.today

tuesdays = (firstTuesday .. now).step(7).map{ |day| day.strftime("%Y-%m-%d").squeeze(' ') }
thursdays = (firstThursday .. lastThursday).step(7).map{ |day| day.strftime("%Y-%m-%d").squeeze(' ') }

tuesdays.each do |item|
    url = "http://etherpad.ctools.org/p/rmmt-#{item}/export/html"
    system ("curl -JLO #{url}")
end

thursdays.each do |item|
    url = "http://etherpad.ctools.org/p/rmmt-#{item}/export/html"
    system ("curl -JLO #{url}")
end
