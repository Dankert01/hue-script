$today = Get-Date
$url = "http://aa.usno.navy.mil/cgi-bin/aa_pap.pl"
$postData = [System.Text.Encoding]::ASCII.GetBytes("xxy=$($today.Year)&xxm=$($today.Month)&xxd=$($today.Day)&st=UT&place=provo")
$webRequest = [System.Net.WebRequest]::Create($url)
$webRequest.Method = "POST"
$webRequest.ContentLength = $postData.Length
$webRequest.ContentType = "application/x-www-form-urlencoded"
$requestStream = $webRequest.GetRequestStream()
$requestStream.Write($postData, 0, $postData.Length)
$requestStream.Close()
$streamReader = New-Object System.IO.Streamreader -ArgumentList $webRequest.GetResponse().GetResponseStream()
$response = $streamReader.ReadToEnd()
$response > "times.txt"
$streamReader.Close()

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
