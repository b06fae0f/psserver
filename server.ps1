# Simple HTTP Server in PowerShell
Param(
	[int] $port = 8080, 
	[string] $root = (Get-Location)
)

Add-Type -AssemblyName System.Web

$MimeTypes = @{
	".bz2" = "application/x-bzip2"
	".doc" = "application/msword"
	".ics" = "text/calendar"
	".oga" = "audio/ogg"
	".3gp" = "video/3gpp"
	".mjs" = "text/javascript"
	".3g2" = "video/3gpp2"
	".azw" = "application/vnd.amazon.ebook"
	".woff2" = "font/woff2"
	".docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	".htm" = "text/html"
	".avi" = "video/x-msvideo"
	".avif" = "image/avif"
	".jar" = "application/java-archive"
	".json" = "application/json"
	".webp" = "image/webp"
	".ts" = "video/mp2t"
	".bin" = "application/octet-stream"
	".weba" = "audio/webm"
	".tif" = "image/tiff"
	".js" = "text/javascript"
	".html" = "text/html"
	".pshtml" = "text/html"
	".txt" = "text/plain"
	".tar" = "application/x-tar"
	".ogx" = "application/ogg"
	".gz" = "application/gzip"
	".mp4" = "video/mp4"
	".m4a" = "audio/mp4"
	".ico" = "image/vnd.microsoft.icon"
	".pptx" = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
	".bmp" = "image/bmp"
	".php" = "application/x-httpd-php"
	".arc" = "application/x-freearc"
	".ppt" = "application/vnd.ms-powerpoint"
	".cda" = "application/x-cdf"
	".epub" = "application/epub+zip"
	".ods" = "application/vnd.oasis.opendocument.spreadsheet"
	".aac" = "audio/aac"
	".png" = "image/png"
	".webm" = "video/webm"
	".midi" = "audio/midi"
	".abw" = "application/x-abiword"
	".rar" = "application/vnd.rar"
	".csh" = "application/x-csh"
	".tiff" = "image/tiff"
	".pdf" = "application/pdf"
	".mp3" = "audio/mpeg"
	".bz" = "application/x-bzip"
	".opus" = "audio/ogg"
	".woff" = "font/woff"
	".xml" = "application/xml"
	".odt" = "application/vnd.oasis.opendocument.text"
	".vsd" = "application/vnd.visio"
	".rtf" = "application/rtf"
	".eot" = "application/vnd.ms-fontobject"
	".xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
	".sh" = "application/x-sh"
	".mpeg" = "video/mpeg"
	".css" = "text/css"
	".csv" = "text/csv"
	".otf" = "font/otf"
	".ogv" = "video/ogg"
	".jsonld" = "application/ld+json"
	".7z" = "application/x-7z-compressed"
	".xul" = "application/vnd.mozilla.xul+xml"
	".jpeg" = "image/jpeg"
	".svg" = "image/svg+xml"
	".mid" = "audio/midi"
	".odp" = "application/vnd.oasis.opendocument.presentation"
	".xhtml" = "application/xhtml+xml"
	".mpkg" = "application/vnd.apple.installer+xml"
	".jpg" = "image/jpeg"
	".gif" = "image/gif"
	".apng" = "image/apng"
	".ttf" = "font/ttf"
	".wav" = "audio/wav"
	".xls" = "application/vnd.ms-excel"
	".zip" = "application/zip"
}

function GetShortFilesize {
	Param([int] $filesize)

	$suffix = @("", "K", "M", "G", "T", "P", "E", "Z", "Y")

	$i = 0;
	while ($filesize -gt 1kb) {
		$filesize /= 1kb
		$i++		
	}

	"{0:N1}{1}" -f $filesize, $suffix[$i]
}

function TemplateHtml {
	Param(
		[string] $template,
		[HashTable] $data
	)

	foreach ($key in $data.Keys) {
		New-Variable -Name "$key" -Value $data[$key]
	}
	
	$tpl = [System.IO.File]::ReadAllText("$root\$template", [System.Text.Encoding]::UTF8)
	$tpl = $tpl.Replace('"', '`"')
	Invoke-Expression "`"$tpl`""
}

function ErrorResponse {
	Param(
		[int] $statusCode,
		[string] $message,
		[System.Net.HttpListenerRequest] $request,
		[System.Net.HttpListenerResponse][ref] $response
	)
	
	if ($message -eq "") {
		switch ($statusCode) {
			500 { $message = "Internal server error."; break }
			404 { $message = "Requested URL {0} not found." -f $request.RawUrl; break }
			403 { $message = "You don't have permission to access this resource."; break }
			401 { $message = "This server could not verify that you are authorized to access the document requested."; break }
			400 { $message = "Your browser sent a request that this server could not understand."; break }
			default { $message = "Unkown error occured."; break }
		}
	}

	$response.StatusCode = $statusCode
	$response.ContentType = "text/plain; charset=UTF-8"
	$message
}

function DirectoryIndex {
	Param([System.Net.HttpListenerRequest] $request)

	$directory = $request.RawUrl.Split("?")[0].TrimEnd("/")
	$directory = $directory.Replace("+", "%20")
	$directory = if ($directory -ne "") { 
		[URI]::UnescapeDataString($directory) 
	} else { 
		"/" 
	}

	$parentDirectory = $directory.Substring(0, $directory.LastIndexOf("/") + 1)

	if (-not ($C = $request.QueryString["C"])) { $C = "N" }
	if (-not ($O = $request.QueryString["O"])) { $O = "A" }

	$tableHead = @{
		"N" = "Name"
		"M" = "LastWriteTime"
		"S" = "Length"
		"D" = "VersionInfo.FileDescription"
	}

	$properties = @{}
	$properties.Expression = $tableHead[$C]

	if ($O -eq "A") { 
		$properties.Ascending = $true 
	} else { 
		$properties.Descending = $true 
	}

	[System.Text.StringBuilder] $sb = New-Object System.Text.StringBuilder
	[void]$sb.AppendLine("<!DOCTYPE html>")
	[void]$sb.AppendLine("<html lang=`"en-US`">")
	[void]$sb.AppendLine("`t<head>")
	[void]$sb.AppendLine("`t`t<meta charset=`"utf-8`" />")
	[void]$sb.AppendLine($("`t`t<title>Index of {0}</title>" -f [System.Net.WebUtility]::HtmlEncode($directory)))
	[void]$sb.AppendLine("`t</head>")
	[void]$sb.AppendLine("`t<body>")
	[void]$sb.AppendLine($("`t`t<h1>Index of {0}</h1>" -f [System.Net.WebUtility]::HtmlEncode($directory)))
	[void]$sb.AppendLine("`t`t<pre><table>")
	[void]$sb.AppendLine("`t`t`t<thead>")
	[void]$sb.AppendLine("`t`t`t`t<tr>")
	[void]$sb.AppendLine($("`t`t`t`t`t<th><a href=`"?C=N&O={0}`">Name</a></th>" -f $(if ($C -eq "N" -and $O -eq "A") { "D" } else { "A" })))
	[void]$sb.AppendLine($("`t`t`t`t`t<th><a href=`"?C=M&O={0}`">Last Modified</a></th>" -f $(if ($C -eq "M" -and $O -eq "A") { "D" } else { "A" })))
	[void]$sb.AppendLine($("`t`t`t`t`t<th><a href=`"?C=S&O={0}`">Size</a></th>" -f $(if ($C -eq "S" -and $O -eq "A") { "D" } else { "A" })))
	[void]$sb.AppendLine($("`t`t`t`t`t<th><a href=`"?C=D&O={0}`">Description</a></th>" -f $(if ($C -eq "D" -and $O -eq "A") { "D" } else { "A" })))
	[void]$sb.AppendLine("`t`t`t`t</tr>")
	[void]$sb.AppendLine("`t`t`t`t<tr>")
	[void]$sb.AppendLine("`t`t`t`t`t<th colspan=`"4`"><hr /></th>")
	[void]$sb.AppendLine("`t`t`t`t</tr>")
	[void]$sb.AppendLine("`t`t`t</thead>")
	[void]$sb.AppendLine("`t`t`t<tbody>")
	[void]$sb.AppendLine("`t`t`t`t<tr>")
	[void]$sb.AppendLine($("`t`t`t`t`t<td><a href=`"{0}`">Parent Directory</a></td>" -f [System.Net.WebUtility]::HtmlEncode($parentDirectory)))
	[void]$sb.AppendLine("`t`t`t`t`t<td>&nbsp;</td>")
	[void]$sb.AppendLine("`t`t`t`t`t<td align=`"right`">-</td>")
	[void]$sb.AppendLine("`t`t`t`t`t<td>&nbsp;</td>")
	[void]$sb.AppendLine("`t`t`t`t</tr>")
	Get-ChildItem -Path ($root + $directory.Replace("/", "\")) | Sort-Object -Property $properties | ForEach-Object -Process {
		[void]$sb.AppendLine("`t`t`t`t<tr>")
		[void]$sb.AppendLine($("`t`t`t`t`t<td><a href=`"{0}`">{1}</a></td>" -f 
			$([URI]::EscapeDataString($_.Name) + $(if ($_.PSIsContainer) {'/'})), 
			[System.Net.WebUtility]::HtmlEncode($_.Name)))
		[void]$sb.AppendLine($("`t`t`t`t`t<td>{0}</td>" -f $_.LastWriteTime))
		[void]$sb.AppendLine($("`t`t`t`t`t<td align=`"right`">{0}</td>" -f $(
			if (-not $_.PSIsContainer) { 
				if ($_.Length -gt 1kb) { 
					GetShortFilesize -Filesize $_.Length 
				} else { 
					$_.Length 
				}
			} else { 
				'-' 
			}
		)))
		[void]$sb.AppendLine($("`t`t`t`t`t<td>{0}</td>" -f $_.VersionInfo.FileDescription))
		[void]$sb.AppendLine("`t`t`t`t</tr>")
	}
	[void]$sb.AppendLine("`t`t`t`t<tr>")
	[void]$sb.AppendLine("`t`t`t`t`t<td colspan=`"4`"><hr /></td>")
	[void]$sb.AppendLine("`t`t`t`t</tr>")
	[void]$sb.AppendLine("`t`t`t</tbody>")
	[void]$sb.AppendLine("`t`t</table></pre>")
	[void]$sb.AppendLine($("`t`t<address>Powershell/{0} ({1}) Server at {2} Port {3}</address>" -f 
		$PSVersionTable.PSVersion,
		[System.Environment]::OSVersion.Platform,
		$request.Url.Host,
		$request.Url.Port))
	[void]$sb.AppendLine("`t</body>")
	[void]$sb.Append("</html>")
	
	return $sb.ToString()
}

function HandleRequest {
	Param(
		[System.Net.HttpListenerRequest] $request,
		[System.Net.HttpListenerResponse][ref] $response
	)

	$response.StatusCode = 200
	$response.ContentType = "text/html; charset=UTF-8"

	if (Test-Path ".\routes.ps1") {
		. ".\routes.ps1"
	} else {
		$RouteNotFound = $true
	}

	if ($RouteNotFound) {
		try {
			$path = $request.RawUrl.Split("?")[0].TrimEnd("/")
			$path = $path.Replace("+", "%20")
			$path = [URI]::UnescapeDataString($path)
			$path = $root + $path.Replace("/", "\") 
			$item = Get-Item $path -ErrorAction Stop
			if ($item.PSIsContainer) {
				if (Test-Path "$path\index.pshtml" -Type Leaf) {
					$item = Get-Item "$path\index.pshtml" -ErrorAction Stop						
				} elseif (Test-Path "$path\index.html" -Type Leaf) {
					$item = Get-Item "$path\index.html" -ErrorAction Stop						
				} else {
					if (-not $request.Url.AbsolutePath.EndsWith("/")) {
						$response.Redirect($request.Url.AbsolutePath + '/')
						return
					}
					return DirectoryIndex -Request $request
				}
			}
			if (-not ($response.ContentType = $MimeTypes[$item.Extension])) {
				if (-not ($response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($item.Name))) {
					$response.ContentType = "application/octet-stream"
				}
			}
			if ($response.ContentType -match "^(text\/.+)|(application\/(.+?\+)?(json|xml))$") {
				$response.ContentType += "; charset=UTF-8"
			}
			if ($item.Extension -eq ".pshtml") {
				$tpl = [System.IO.File]::ReadAllText($item, [System.Text.Encoding]::UTF8)
				$tpl = $tpl.Replace('"', '`"')
				Invoke-Expression "`"$tpl`""
			} else {
				[System.IO.File]::ReadAllBytes($item)
			}
		} catch [System.Management.Automation.ItemNotFoundException] {
			ErrorResponse -StatusCode 404 -Request $request -Response ([ref]$response)
		}
	}
}

try {
	$listener = New-Object System.Net.HttpListener
	$listener.Prefixes.Add("http://localhost:$port/")
	$listener.Start()

	if (-not $listener.IsListening) {
		throw "HTTP Server failed to listen on http://localhost:$port/"	
	}

	Write-Host "[*] HTTP Server is listening on http://localhost:$port/."
	Write-Host "[*] Press CTRL-C to stop."

	while ($listener.IsListening) {
		$task = $listener.GetContextAsync()
		while (-not $task.AsyncWaitHandle.WaitOne(200)) {}
		$context = $task.GetAwaiter().GetResult()
		$request = $context.Request
		$response = $context.Response
		
		try {
			$buffer = HandleRequest -Request $request -Response ([ref]$response)
		} catch {
			Write-Host "[!] Error occured: $_"
			$buffer = ErrorResponse -StatusCode 500 -Request $request -Response ([ref]$response)
		}
		
		if ($buffer) {
			if ($buffer -is [string]) {
				$buffer = [System.Text.Encoding]::UTF8.GetBytes($buffer) 
			}
			$response.ContentLength64 = $buffer.Length
			$response.OutputStream.Write($buffer, 0, $buffer.Length)
			$response.OutputStream.Close()
		}
		
		$logColor = switch($response.StatusCode) {
			200 { "Green" }
			302 { "Yellow" } 
			default { "Red" } 
		}

		Write-Host $("[+] [{0}] {1} [{2}]: {3} {4} HTTP/{5} - {6}" -f 
			$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), 
			$request.UserHostAddress,
			$response.StatusCode,
			$request.HttpMethod,
			$request.RawUrl,
			$request.ProtocolVersion,
			$response.StatusDescription) -ForegroundColor $logColor
	
		$response.Close()
		$response.Dispose()
	}
} catch {
	Write-Host "[!] Error: $_"
} finally {
	Write-Host "[*] Stopping the server..."
	$listener.Stop()
	$listener.Close()
	Write-Host "[*] Server stopped."
}
