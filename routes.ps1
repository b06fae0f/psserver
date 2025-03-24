switch -RegEx ($request.Url.AbsolutePath.TrimEnd("/")) {
	{$_ -eq "/hello"} {
		$response.ContentType = "text/plain; charset=UTF-8"
		"Hello, World!"
	}
	"^/sayhi/([^/]+)$" {
		$name = $Matches[1]
		$response.ContentType =  "text/plain; charset=UTF-8"
		"Hi, $name!"
	}
	default {
		$RouteNotFound = $true
	}
}
