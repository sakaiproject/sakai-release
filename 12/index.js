#!/usr/bin/env node
var program = require('commander');
var exec = require('child_process').exec;
var chalk = require('chalk');

var querystring = require('querystring');
var https = require('https');

function performRequest(host, endpoint, method, data, success) {
  var dataString = JSON.stringify(data);
  var headers = {};
  
  if (method == 'GET') {
    endpoint += '?' + querystring.stringify(data);
  } else {
    headers = {
      'Content-Type': 'application/json',
      'Content-Length': dataString.length
    };
  }
  var options = {
    host: host,
    path: endpoint,
    method: method,
    headers: headers
  };
  
  var req = https.request(options, function(res) {
    res.setEncoding('utf-8');
    var responseString = '';
    res.on('data', function(data) {
      responseString += data;
    });
    res.on('end', function() {
		var responseObject = JSON.parse(responseString);
       	success(responseObject);
	});
  });
  
  req.write(dataString);
  req.end();
}

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

var extractJiraKeys = function(t) {
	var jira_matcher = /\d+-[A-Z]+(?!-?[a-zA-Z]{1,10})/g	 
	var s = t.split("").reverse().join("");
	var m = s.match(jira_matcher);
	if (!m) return [];
	// Also need to reverse all the results!
	for (var i = 0; i < m.length; i++) {
		m[i] = m[i].split("").reverse().join("");
	}
	m.reverse();
	return m;
}

var isJiraRelated = function(t) {
	return extractJiraKeys(t).length > 0;
}

var isGithubRelated = function(t) {
	return !isJiraRelated(t) && t.substring(12).match(/[^(]#*[0-9]{4,}[^)]/);
}

var isOnly = function(t) {
	return !program.only || t.indexOf(program.only) >= 0;
}

var jiralist = new Array();
var remainingJiras = 0;
var checkJiraApi = function(key,success) {
	if (!jiralist[key]) {
		jiralist[key] = { status:'', merge: '' }
		performRequest('jira.sakaiproject.org','/rest/api/2/issue/'+key,'GET',{fields:['status','customfield_12270']},function(data){
			var status = 'none', merge = 'none';
			if (!data.errorMessages) {
				if (data.fields.status) status = data.fields.status.name;
				if (data.fields.customfield_12270) merge = data.fields.customfield_12270.value;
				jiralist[key].status = status;
				jiralist[key].merge = merge;
			} else {
				jiralist[key].status = 'unknown';
				jiralist[key].merge = 'unknown';
			}
			remainingJiras++;
			if (remainingJiras==globalNum) {
				success(jiralist);
			}
		});
	}
}

var globalNum = 0;
var isJiraReady = function(t,f) {
	var keys = extractJiraKeys(t);
	for (var k=0; k<keys.length; k++) {
		//checkJiraApi(keys[k],f);			
		setTimeout(checkJiraApi,(500*globalNum)+(k*100),keys[k],f);
	}
	globalNum++;
	return true;
}

var checkJira = function(key,v) {
	return (v[1] == 'any' || jiralist[key].status.toLowerCase() == v[1]) && (v[2] == jiralist[key].merge.toLowerCase());
}

var areJirasReady = function(keys,v) {
	var ready = true;
	for (var k=0; k<keys.length; k++) {
		if (!jiralist[keys[k]] || !checkJira(keys[k],v)) {
			ready = false;
		}
	}
	return ready;
}

var showLine = function(line,ignore) {
	if (program.picks && !ignore) {
		console.log(chalk.red('git cherry-pick '+line.substring(2,12),chalk.green(' //'+line.substring(13))));
	} else {
		console.log(chalk.cyan(line));
	}
}

var showLines = function(message,lines,ignore) {
	console.log(message);
	for (var i=0; i<lines.length; i++) {
		showLine(lines[i],ignore);
	}
}

var processOptions = function(updated) {
	if (program.find) {
		console.log('Searching for commit \''+program.find+'\' in 12.x branch...')
		exec((!updated?"git checkout 12.x;":"")+"git log --pretty=oneline --since=\"2017-08-29\"", function (error, stdout, stderr) {
			var flines = processLines(stdout,function(t) { return t.indexOf(program.find) >= 0 });
			if (flines.length==0) { console.log('Commit \''+program.find+'\' not found in 12.x branch!'); }
			else {
				showLines('Found \''+program.find+'\' in 12.x branch',flines,true);
			}
		})
	} else {
		exec("git checkout 12.x",function (error, stdout, stderr) {
			if (error) {
				console.log(stderr);
				return;
			}
			if (program.missing) {
				console.log('Searching for missing commits...');
				exec("git cherry 12.x master -v --abbrev=10", function (error, stdout, stderr) {
					var flines = processLines(stdout,function(t) { 
						return t.indexOf('+') == 0 
							&& !isJiraRelated(t)
							&& !isGithubRelated(t)
							&& isOnly(t);
					});
					showLines('Found '+flines.length+' missed commits.',flines);
				});
			} else if (program.check) {
				console.log('Searching for missing \''+program.check+'\' commits...');
				exec("git cherry 12.x master -v --abbrev=10", function (error, stdout, stderr) {
					var flines = processLines(stdout,function(t) { 
						return t.indexOf('+') == 0 
							&& t.indexOf(program.check) >= 0;
					});
					showLines('Found '+flines.length+' missed commits.',flines);
				});
			} else if (program.jira) {
				var verify = 'verified:merge';
				var verifyRegExp = /(verified|resolved|closed|any):(merge|resolved|none)/;
				if (program.jira_verify) {
					if (program.jira_verify.toLowerCase().match(verifyRegExp)) {
						verify = program.jira_verify;
					} else {
						console.log('Invalid -j options \''+program.jira_verify+'\' using defaults.')
					}
				}
				console.log('Searching for missing jira ['+verify+'] commits...');
				exec("git cherry 12.x master -v --abbrev=10", function (error, stdout, stderr) {
					var flines = processLines(stdout,function(t) {
						return t.indexOf('+') == 0 
							&& isJiraRelated(t)
							&& isOnly(t)
							&& isJiraReady(t,function(){
								var v = verifyRegExp.exec(verify.toLowerCase());
								var total = 0;
								for (var i=0; i<flines.length; i++) {
									var keys = extractJiraKeys(flines[i])
									if (areJirasReady(keys,v)) {
										showLine(flines[i]);
										total++;
									}
								}
								console.log('Found '+total+' missing ready jira commits')
							});
					});
				});
			} else if (program.github) {
				console.log('Searching for missing github issues commits...');
				exec("git cherry 12.x master -v --abbrev=10", function (error, stdout, stderr) {
					var flines = processLines(stdout,function(t) {
						return t.indexOf('+') == 0 
							&& isGithubRelated(t)
							&& isOnly(t);
					});
					showLines('Found '+flines.length+' missed commits.',flines);
				});
			} else if (program.all) {
				console.log('Searching for global missing commits...');
				exec("git cherry 12.x master -v --abbrev=10", function (error, stdout, stderr) {
					var flines = processLines(stdout,function(t) {
						return t.indexOf('+') == 0 
							&& isOnly(t);
					});
					showLines('Found '+flines.length+' missed commits.',flines);
				});
			}
		});
	}
}


program
.version('1.0.0')
.description('Sakai cherry pick management script')
.option('-u, --update', 'Update local git working copies')
.option('-f, --find <find>', 'Find some commit in 12.x that matches pattern')
.option('-m, --missing','List missing commits in 12.x without jira or github issue reference')
.option('-c, --check <check>','Look for some missing commits in 12.x that matches pattern')
.option('-j, --jira [verified|resolved|closed|any:none|merge|resolved]','List missing commits of jiras with status and 11 status as the value specified (default verified:merge)',function(v,s){ program.jira_verify = v; })
.option('-o, --only <only>','Filter missing jiras that contains pattern, use in addition to other options')
.option('-g, --github', 'List missing commits of github issues without workflow checking')
.option('-a, --all', 'List all missing commits without any check')
.option('-p, --picks', 'Show cherry-pick commands, use in addition to other options')
.parse(process.argv);

if (program.update) {
	console.log('Updating local git working copies...');
	exec("git checkout master;git pull upstream master;git checkout 12.x;git pull upstream 12.x", function (error, stdout, stderr) {
		if (error) {
			console.log(stderr);
		} else {
			console.log('Success!');
			processOptions(true);
		}
	});	
} else {
	if (program.find || program.missing || program.check || program.jira || program.github || program.all) {
		processOptions(false);
	} else {
		console.log('You must choose one option, try --help')
	}
}

