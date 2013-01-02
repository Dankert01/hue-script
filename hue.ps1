#http://www.earthtools.org/sun/<latitude>/<longitude>/<day>/<month>/<timezone>/<dst>
$today = Get-Date
$todayDay = $today.Day
$todayMonth = $today.Month
$timezone = "-7"
$lat = "40.655234" 
$long = "-111.882368"
$daylightSavings = "0"
$url = "http://www.earthtools.org/sun/$lat/$long/$todayDay/$todayMonth/$timezone/$daylightSavings"

# form the web request
# see http://www.earthtools.org/webservices.htm#sun
$postData = [System.Text.Encoding]::ASCII.GetBytes($url)
$webRequest = [System.Net.WebRequest]::Create($url)
$webRequest.Method = "POST"
$webRequest.ContentLength = $postData.Length
$webRequest.ContentType = "application/x-www-form-urlencoded"
$requestStream = $webRequest.GetRequestStream()
$requestStream.Write($postData, 0, $postData.Length)
$requestStream.Close()
$streamReader = New-Object System.IO.Streamreader -ArgumentList $webRequest.GetResponse().GetResponseStream()
$response = [xml]$streamReader.ReadToEnd()

# obtain the data
$prepend = $today.ToString("yyyy-MM-dd") + "T"
$sunrise = $prepend + $response.sun.morning.sunrise
$mcTwilight = $prepend + $response.sun.morning.twilight.civil
$maTwilight = $prepend + $response.sun.morning.twilight.astronomical
$sunset = $prepend + $response.sun.evening.sunset
$ecTwilight = $prepend + $response.sun.evening.twilight.civil
$eaTwilight = $prepend + $response.sun.evening.twilight.astronomical



$hueBridgeIP = "192.168.1.134"
$allowedHash = "71a6b6f094346a8832df801c8428ea06"
$lightAPI = "lights/3/state"
$lightCommand = '{"on":true, "bri": 255, "ct":182, "transitiontime":90}'
$url = "http://$hueBridgeIP/api/$allowedHash/$lightAPI"
$putData = [System.Text.Encoding]::ASCII.GetBytes($lightCommand)
$webRequest = [System.Net.WebRequest]::Create($url)
$webRequest.Method = "PUT"
$webRequest.ContentLength = $putData.Length
$webRequest.ContentType = "application/x-www-form-urlencoded"
$requestStream = $webRequest.GetRequestStream()
$requestStream.Write($putData, 0, $putData.Length)
$requestStream.Close()
$streamReader = New-Object System.IO.Streamreader -ArgumentList $webRequest.GetResponse().GetResponseStream()
$streamReader.ReadToEnd()
$streamReader.Close()
