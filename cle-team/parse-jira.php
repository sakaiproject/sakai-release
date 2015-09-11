<?php
  $year = (int) date('Y');
  $month = (int) date('m');
  $day = (int) date('d');
  $thursday = date('Y-m-d', time() + 86400);

  $thanksgiving = date('Y-m-d', strtotime("fourth thursday of Nov $year"));
  $julyfour = "$year-07-04";

  $zone = date('T');
  $gmt = "14:00GMT";
  if ($zone == 'EST') {
    $gmt = "15:00GMT";
  }

  $to = 'sakai-core@apereo.org';
  $subject = 'Sakai Core Team Call, Thursday, ' . $thursday . ', 10:00' . $zone . ' (' . $gmt . ')';

  $output = <<<EOF
<p>Quick PIN: 8600146</p>

<p>Call numbers:  http://www.calliflower.com/dial-in-numbers/</p>

<p>Etherpad notes:</p>

<p>&nbsp;&nbsp; http://etherpad.ctools.org/rmmt-$thursday </p>


EOF;

  if ($thursday == $thanksgiving || $thursday == $julyfour || ($month == 12 && $day > 22)) {
    $output = "<p><strong>There will be no call this week because of holidays.</strong></p>";
    $subject = 'No Sakai Core Team call this week';
  }


  #Changed this to use a defined filter
  #$uri = "https://jira.sakaiproject.org/sr/jira.issueviews:searchrequest-xml/temp/SearchRequest.xml?jqlQuery=project+in+%28SAK%2C+KNL%29+AND+created+%3E%3D+-7d+ORDER+BY+status+DESC%2C+priority+DESC&tempMax=1000";
  $uri = "https://jira.sakaiproject.org/sr/jira.issueviews:searchrequest-xml/14870/SearchRequest-14870.xml?tempMax=1000";

  $str = file_get_contents ($uri);
  $xml = new SimpleXMLElement ($str);

  $out = array();
  if ($title = $xml->channel->title) {
          $output .= "<br/><h3>$title</h3>";
          foreach ($xml->channel->item AS $jira) {
                  // skip fixed issues
                  if ((string) $jira->status[0] != "Open" && (string) $jira->status[0] != "Awaiting Review") continue;

                  if (strpos((string)$jira->title[0], "translation")) continue;

                  $version = array();
                  foreach ($jira->version AS $f) {
                          $version[] = str_ireplace(" [tentative]", "", (string)$f);
                  }

                  $out[(string) $jira->key[0]] = '<tr><td><a href="' . (string) $jira->link[0] . '">' . htmlentities($jira->title[0]) . '</a></td><td>' .
                          (string) $jira->reporter[0] . '</td><td>' . implode(", ", $version) . '</td></tr>';
          }
  }

  // sort by the jira key
  ksort($out);
  $output .= '<table rules="all" style="border-color: #666;" cellpadding="6"><tr style="background: #eee;"><th>JIRA</th><th>Reporter</th><th>Version</th></tr>' .  implode("\n", $out) . '</table>';

  #$output .= '<br/><br/><h3>Fixed SAK/KNL in past week</h3>';

  sleep(2);

  $fix_uri = "https://jira.sakaiproject.org/sr/jira.issueviews:searchrequest-xml/14871/SearchRequest-14871.xml?tempMax=1000";

  $str = file_get_contents ($fix_uri);
  $xml = new SimpleXMLElement ($str);

  $out = array();
  if ($title = $xml->channel->title) {
          $output .= "<br/><br/><h3>$title</h3>";
          foreach ($xml->channel->item AS $jira) {
                  if (strpos((string)$jira->title[0], "translation")) continue;

                  $fix = array();
                  foreach ($jira->fixVersion AS $f) {
                          $fix[] = str_ireplace(" [tentative]", "", (string)$f);
                  }

                  $out[(string) $jira->key[0]] = '<tr><td><a href="' . (string) $jira->link[0] . '">' . (string) htmlentities($jira->title[0]) . '</a></td><td>' .
                          (string) $jira->assignee[0] . '</td><td>' . implode(", ", $fix) . '</td></tr>';
          }
  }

  // sort by the jira key
  ksort($out);
  $output .= '<table rules="all" style="border-color: #666;" cellpadding="6"><tr style="background: #eee;"><th>JIRA</th><th>Assignee</th><th>Fix</th></tr>' .  implode("\n", $out) . '</table>';



  $output .= '<br/><br/><h3>Active committers to master in past week</h3>';

  $output .= '<p><em>Count is not a metric of quality! This is a simple look at community activity.</em></p><table rules="all" style="border-color: #6
66;" cellpadding="6"><tr style="background: #eee;"><th>Person</th><th>Commits</th></tr>';
  $output .= file_get_contents('git.html');
  $output .= '</table>';


  // mail it
#  $headers = "From: sakai-core@apereo.org\r\n";
  $headers = "From: matthew@longsight.com\r\n";
  $headers .= "Reply-To: sakai-core@apereo.org\r\n";
  $headers .= "CC: sakai-qa@apereo.org,sakai-dev@apereo.org\r\n";
  $headers .= "MIME-Version: 1.0\r\n";
  $headers .= "Content-Type: text/html; charset=UTF-8\r\n";

  //print $output;

  mail($to, $subject, $output, $headers);
