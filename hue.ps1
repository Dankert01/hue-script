$hueBridgeIP = "192.168.1.134"
$allowedHash = "71a6b6f094346a8832df801c8428ea06"

# CREATE FUNCTION TO ABSTRACT WEB REQUESTS
# see http://msdn.microsoft.com/en-us/library/system.net.webrequest.aspx
Function Send-Web-Request($url, $method = "GET", $content = "") {
  Write-Host "url = $url"
  Write-Host "method = $method"
  Write-Host "content = $content"

  $request = [System.Net.WebRequest]::Create($url)
  $request.Method = $method

  switch -regex ($method) {
    "GET" {
      Write-Host "switched to GET"
      break
    }
    "POST|PUT" {
      Write-Host "switched to POST|PUT"
      $byteArray = [System.Text.Encoding]::ASCII.GetBytes($content)
      $request.ContentType = "application/x-www-form-urlencoded"
      $request.ContentLength = $byteArray.Length
      $newStream = $request.GetRequestStream()
      $newStream.Write($byteArray, 0, $byteArray.Length)
      $newStream.Close()
      break
    }
    "DELETE" {
      Write-Host "switched to DELETE"
      break
    }
    default {
      Write-Host "switched to default"
      Write-Host "Not a valid method!"
    }
  }

  $response = $request.GetResponse()
  Write-Host "response.StatusDescription = $($response.StatusDescription.toString())"
  $dataStream = $response.GetResponseStream()
  $reader = New-Object IO.StreamReader($dataStream)
  $responseFromServer = $reader.ReadToEnd()
  Write-Host "$responseFromServer"
  $reader.Close()
  $dataStream.Close()
  $response.Close()

  return $responseFromServer
}


# CREATE FUNCTION TO ADD SCHEDULE TO PHILIPS HUE
Function Add-Schedule($scheduleName, $scheduleTime, $lightAddress, $commands) {
  $content = "{`"name`":`"$scheduleName`", `"time`":`"$scheduleTime`", `"description`":`" `", `"command`":{`"method`":`"PUT`", `"address`":`"/api/$allowedHash/lights/$lightAddress/state`", `"body`":$commands}}"
  Write-Host $content
  Send-Web-Request "http://$hueBridgeIP/api/$allowedHash/schedules" "POST" $content
}

# GET TIMES FOR TODAY'S SUNRISE, SUNSET, ETC
# see http://www.earthtools.org/webservices.htm#sun
$today = Get-Date
$timezone = "-7"
$latitude = "40.655234"
$longitude = "-111.882368"
$daylightSavings = "0"

$url = "http://www.earthtools.org/sun/$latitude/$longitude/$($today.Day)/$($today.Month)/$timezone/$daylightSavings"
$response = Send-Web-Request $url
$xmlResponse = [xml]$response

#$maTwilight = Get-Date $xmlResponse.sun.morning.twilight.astronomical
$mcTwilight = Get-Date $xmlResponse.sun.morning.twilight.civil
$sunrise = Get-Date $xmlResponse.sun.morning.sunrise
$sunset = Get-Date $xmlResponse.sun.evening.sunset
$ecTwilight = Get-Date $xmlResponse.sun.evening.twilight.civil
#$eaTwilight = Get-Date $xmlResponse.sun.evening.twilight.astronomical


# GET TIMESPANS BETWEEN TWILIGHT AND SUNRISE/SUNSET
$morningTimeSpan = $sunrise.Subtract($mcTwilight)
Write-Host "sunrise = $sunrise"
Write-Host "mcTwilight = $mcTwilight"
Write-Host "sunrise - mcTwilight = $($morningTimeSpan.Days):$($morningTimeSpan.Hours):$($morningTimeSpan.Minutes):$($morningTimeSpan.Seconds)"
$eveningTimeSpan = $ecTwilight.Subtract($sunset)
Write-Host "ecTwilight = $ecTwilight"
Write-Host "sunset = $sunset"
Write-Host "ecTwilight - sunset = $($eveningTimeSpan):$($eveningTimeSpan.Hours):$($eveningTimeSpan.Minutes):$($eveningTimeSpan.Seconds)"


# CONVERT TIMESPANS TO 1/10s
$morningTransitionTime = ($morningTimeSpan.Days * 24 * 60 * 60 * 10) + ($morningTimeSpan.Hours * 60 * 60 * 10) + ($morningTimeSpan.Minutes * 60 * 10) + ($morningTimeSpan.Seconds * 10)
$eveningTransitionTime = ($eveningTimeSpan.Days * 24 * 60 * 60 * 10) + ($eveningTimeSpan.Hours * 60 * 60 * 10) + ($eveningTimeSpan.Minutes * 60 * 10) + ($eveningTimeSpan.Seconds * 10)


# SET MORNING LIGHT SCHEDULE
$morningCommands = "{`"bri`": 255, `"ct`": 182, `"transitiontime`": $morningTransitionTime, `"on`": true}"
Add-Schedule "Sunrise Living Room" $mcTwilight.AddHours(7).toString("s") 1 $morningCommands
Add-Schedule "Sunrise Bedroom" $mcTwilight.AddHours(7).toString("s") 3 $morningCommands


# SET EVENING LIGHT SCHEDULE
$eveningCommands = "{`"bri`": 158, `"ct`": 400, `"transitiontime`": $eveningTransitionTime, `"on`": true}"
Add-Schedule "Sunset Living Room" $sunset.AddHours(7).toString("s") 1 $morningCommands
Add-Schedule "Sunset Bedroom" $sunset.AddHours(7).toString("s") 3 $morningCommands


# SET SLEEP LIGHT SCHEDULE
$midnight = Get-Date "23:59:59"
$midnight = $midnight.AddSeconds(1)
$sleepCommands = "{`"transitiontime`": 3000, `"on`": false}"
Add-Schedule "Sleep Living Room" $midnight.AddHours(7).toString("s") 1 $sleepCommands
Add-Schedule "Sleep Bedroom" $midnight.AddHours(7).toString("s") 3 $sleepCommands


# OUTPUT SCHEDULES TO FILE
$log = Send-Web-Request "http://$hueBridgeIP/api/$allowedHash"
$log > "hueschedules.log"
