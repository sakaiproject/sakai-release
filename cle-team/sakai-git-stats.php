#!/usr/bin/php
<?php

$time = time() - (86400*7);
$isodate = date('c', $time);
$year = date('Y', $time);
$month = date('m', $time);
$day = date('d', $time);


$options = array(
  'http'=>array(
    'method'=>"GET",
    'header'=>"Accept-language: en\r\n" .
              "User-Agent: Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.102011-10-16 20:23:10\r\n" // i.e. An iPad
  )
);

$context = stream_context_create($options);

$str = file_get_contents('https://api.github.com/repos/sakaiproject/sakai/commits?since=' . $isodate, false, $context);
$json = json_decode($str);

$authors = $info = $out = array();
foreach ($json AS $commit) {
  if (strpos($commit->commit->message, "Merge pull request") !== FALSE) continue;

  $authors[$commit->author->login] = isset($authors[$commit->author->login]) ? $authors[$commit->author->login] + 1 : 1;
  $info[$commit->author->login] = "<a href=\"{$commit->author->html_url}\"><img style=\"width:24px;height:24px\" src=\"{$commit->author->avatar_url}\" /></a> {$commit->author->login}";
}

arsort($authors);

foreach ($authors AS $login => $cnt) {
  $out[] = "<tr><td>{$info[$login]}</td><td>{$cnt}</td></tr>\n";
}

if (count($out) < 1) exit(1);

file_put_contents('git.html', $out);

