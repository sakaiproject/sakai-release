#!/usr/bin/env node
var program = require('commander');
var exec = require('child_process').exec;
var chalk = require('chalk');

var processLines = function(stdout,filter) {
	var outLines = stdout.split(/\r?\n/);
	var filterLines = [];
	for (var i=0; i<outLines.length; i++) {
		if (filter(outLines[i])) {
			filterLines.push(outLines[i]);
		}
	}
	return filterLines;
}

var findCommit = function(updated,text) {
	console.log('Searching for commit \''+text+'\' in 11.x branch...')
	exec((!updated?"git checkout 11.x;":"")+"git log --pretty=oneline --abbrev-commit --since=\"2016-02-17\"", function (error, stdout, stderr) {
		var flines = processLines(stdout,function(t) { return t.indexOf(text) >= 0 });
		if (flines.length==0) { console.log('Commit \''+text+'\' not found!'); }
		else {
			console.log(flines);
		}
	})
}

var processOptions = function(updated) {
	if (program.find) {
		findCommit(updated,program.find);
	}
	if (program.missing) {
		console.log('Searching for missing commits...');
		exec("git cherry 11.x master -v --abbrev=10", function (error, stdout, stderr) {
			var flines = processLines(stdout,function(t) { 
				return t.indexOf('+') == 0 
					&& t.indexOf('SAK-') < 0
					&& t.indexOf('LSNBLDR-') < 0
					&& t.indexOf('LNSBLDR-') < 0
					&& t.indexOf('LSNBDLR-') < 0
					&& t.indexOf('KNL-') < 0
					&& t.indexOf('SAM-') < 0
					&& t.indexOf('DASH-') < 0
					&& t.indexOf('RSF-') < 0
					&& t.indexOf('Sak-') < 0
					&& !t.match('.*#[0-9]+.*')
			});
			console.log('Found '+flines.length+' missed commits.');
			for (var i=0; i<flines.length; i++) {
				console.log(chalk.cyan(flines[i].substring(2)));
			}
		});
	}
}


program
.version('1.0.0')
.description('Sakai cherry pick management script')
.option('-u, --update', 'Update local git working copies')
.option('-f, --find <find>', 'Find some commit in 11.x')
.option('-m, --missing','List missing commits in 11.x')
.parse(process.argv);

if (program.update) {
	console.log('Updating local git working copies...');
	exec("git checkout master;git pull upstream master;git checkout 11.x;git pull upstream 11.x", function (error, stdout, stderr) {
		if (error) {
			console.log(stderr);
		} else {
			console.log('Success!');
			processOptions(true);
		}
	});	
} else {
	processOptions(false);
}

