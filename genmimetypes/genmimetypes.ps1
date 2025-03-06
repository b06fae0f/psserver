# Get the most common MIME Types according to Mozilla website and save them in a JSON file.

# Output JSON file
$Outfile = ".\mimetypes.json"

# Hash table for the Mime Types
$MimeTypes = @{}

# Mime types URI
$MimeTypesURI = "https://developer.mozilla.org/en-US/docs/Web/HTTP/MIME_types/Common_types"

try {
    # Get the HTML content
    $Response = Invoke-WebRequest -Uri $MimeTypesURI

    # Get the HTML table with the Mime types
    $MimeTypesTable = $Response.ParsedHtml.body.getElementsByClassName("table-container")[0].nextSibling
    
    # Get table body
    $TBODY = $MimeTypesTable.getElementsByTagName("tbody")[0] 
    
    # Get Mime types from each row
    $TBODY.getElementsByTagName("tr") | ForEach-Object -Process {
        $TD = $_.getElementsByTagName("td")
        $Extensions = $TD[0].getElementsByTagName("code")
        $MimeType = $TD[2].getElementsByTagName("code")[0].innerText
        $Extensions | ForEach-Object -Process {
            $MimeTypes[$_.innerText] = $MimeType
        }
    }
    
    # Save Mime types as a JSON file
    [System.IO.File]::WriteAllLines($Outfile, ($MimeTypes | ConvertTo-JSON), [System.Text.UTF8Encoding]::new($false))
    
    Write-Host "Mime types file was created successfuly."
} catch {
    Write-Host "Error: $_";
}
