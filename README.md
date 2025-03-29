# PSServer
Easy and lightweight server made using powershell to serve static files or dynamic webpages.

## Usage
Copy `server.ps1` file to your project directory. then open your terminal and type `powershell server.ps1` then press `Enter`.

You may need to type `powershell -ExecutionPolicy Bypass -File server.ps1` if your device do not allow running `.ps1` files by default.

## How it works
To add a dynamic webpage create a new file with `.pshtml` extension, this will tell the server that this file includes a powershell 
code embeded into the HTML.
You can also use the `routes.ps1` file to create friendly URLs and using `TemplateHtml` function to render HTML templates with an embeded powershell code.

## Warning
For security reasons this script should not be used in any production.

## Disclaimer
The author of this program can not be held any responsibility for loss or damage, use at your own risk.
