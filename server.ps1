# Simple HTTP Server in PowerShell

$port = 8080

$listener = [System.Net.HttpListener]::new()

$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
} catch {
    Write-Host "[!] Error: $_"
}

if ($listener.IsListening) {
    Write-Host "[*] Server is running on http://localhost:$port/. Press CTRL-C to stop."
}

$httphandler = {
    param($listener, [ref]$serverRunning)

    # List of icons for the indexing directories
    $ICONS = @{
        "back" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAElBMVEX////M//+ZmZlmZmYzMzMAAACei5rnAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAYElEQVQIW0XP0QnAMAhFUVew4ACFLpARUl4XKHH/VdqXRPUjHC5+GNEc4dOQvICelY4KVEWviqo2qVz1Re3HQxq33UnXP02a7xENDcn4Sshb1lv37jh5pC3Me70+ZMWYD08uJsBsi+cYAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "folder" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAElBMVEX/////zJnM//+ZZjMzMzMAAADCEvqoAAAAA3RSTlP//wDXyg1BAAAAAWJLR0QAiAUdSAAAAFJJREFUCFtjUIIDBsLMUCCAMFUFgSAIzAwEMUVDQ4OUGIJBTEMgDyhqDARAnnAQRAEQGLvCmcKuVBYVhgJXBlVjCDBxZVAKcYGAEAYl1VAIcAIAfgAgxXnPTZkAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
        "blank" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWAQMAAAD6jy5FAAAABlBMVEX////M//9zUa6lAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAD0lEQVQIHWP8z/CRkQYYAFlpKreJcPlsAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "unknown" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAYklEQVQIW23O0Q2AIBAD0AZcgA0IYQAJDGCw+8/k3SFoov16FEKKaikhBOyQeP8QxZjIE17pqJR6kK014cZuJ+MBMuXxg1vUewxmst+UMi5GLGLS8mn/+Xo7WdOIjAw60EZeVZkZLhf9K5EAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
        "text" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAT0lEQVQIW5XIsQ3AIAwF0VNgAa+AGABkD0Dx958pRRy55qrTw93dfZsZC6C1WnZtq2Ubq0unR0Rql5TKM2YqjPmpdCjlVuFG//XxFYYpsxfEkhYAImC9XwAAAFZ0RVh0Y29tbWVudABUaGlzIGFydCBpcyBpbiB0aGUgcHVibGljIGRvbWFpbi4gS2V2aW4gSHVnaGVzLCBrZXZpbmhAZWl0LmNvbSwgU2VwdGVtYmVyIDE5OTV29u+cAAAAAElFTkSuQmCC"
        "image" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAJFBMVEX/////MzPM///MzMyZmZlmZmZmAAAzMzMAmcwAmTMAM2YAAADMt1kEAAAAA3RSTlP//wDXyg1BAAAAAWJLR0QAiAUdSAAAAIxJREFUCFtFzjsKwkAUheEDVxjEaggIae8KtPFVp3MBrsEuxGIis4FgFRCLu4VsYTbnnUeSv/o41YFLdcyMFpoxK9GtNJHW2spA58T9zns/M4RQiE1zT6zli8KR5IDIY00iLUWenlflLRJbEXl9Eo3Ir8+ktzyGTJxdPxM0LLwspEkra0zpmpye5FDiP+BZOkuqcu7kAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "sound" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAFVBMVEX////M///MzMyZmZlmZmYzMzMAAAC3QbbwAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAZElEQVQIW03PMQrAMAgF0EBO4FCPkgOU0t3BzumQf/8jxKQqdfEhH8VCWcU73iAwnMDtBC6n6fTAUtD0RACaVGGnCgWFfswNwr0l654yjF8AdWfV2JvxsH1l3RL/gjGCpErBqAnAJym/VjbeUgAAAFZ0RVh0Y29tbWVudABUaGlzIGFydCBpcyBpbiB0aGUgcHVibGljIGRvbWFpbi4gS2V2aW4gSHVnaGVzLCBrZXZpbmhAZWl0LmNvbSwgU2VwdGVtYmVyIDE5OTV29u+cAAAAAElFTkSuQmCC"
        "video" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAFVBMVEX////M///MzMyZmZlmZmYzMzMAAAC3QbbwAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAOUlEQVQIW2NIg4JEQYYkNTBLKRXEdAECNhAzLc3Z2NiYLQ0sCmYqoTKJUMAABFAF9LUCzhQNhQJBAGWZNOmfH9xVAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "binary" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAElBMVEX////M///MzMyZmZkzMzMAAACRtcsMAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAYklEQVQIW3WOsQnAMAwEn0QeQBukyQQmfQx2Hwy//ypRZIGL4K8OcRxC9RVVxQ2biCM3dkFxTA8FMtHOA1NrLdxEMgrY82V48iDg+Ll2X+NwHb0QgnX/7gKnOws1j9mTypi+rnwhdh62ydYAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
        "binhex" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAElBMVEX////M//+ZmZlmZmYzMzMAAACei5rnAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAa0lEQVQIW2WO0QnAIAxEjxIHyAZFcIT+K+i/FLL/Kk2i1UIPAo/HcQTVU5gZGRoiR9EQykbyQuggqB42tNZe1JsLOGJSTCI34GgF9YYdCBPbtnJZ1/H0iWEzrcLu2g9/++liLdQ4ok+yzPADA4IhHGhjMRQAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
        "tar" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX///+/v7+7u7tWVlU3Nzcf2aFAAAAAWUlEQVQIW22MwQ3AIAzEToEFskGFWIAV0uw/U68kCKnUL3MyQZsMVcUFImUrRqi4oLzqRMA51ezOAHzG2iCtZwBM5X8q9oq62lAE9QiW5oVvYG7nhV9VT/QB4a8Wamy7ibUAAABMdEVYdGNvbW1lbnQAVGhpcyBpY29uIGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiAxOTk1IEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb215JxgUAAAAAElFTkSuQmCC"
        "world" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAFVBMVEX////M///MzMyZmZkAmTMAZjMAAAC9g7uQAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAlElEQVQIW13Pyw3EIAwEUFrIhQIcd4CcAibebQCZO0k2/ZewQ/ZziCWkJ4TGQ5r+k3jyefYP8+H+7IN5g0DoNB1Qd9dGbnBxB5nhOsZ6yg4FVGpPhxDQORrpwus1lovMeBipTODTwYEvIVwxV2sM41qPCOaKQ9ZSuWLaFKWWurDDbha1xKiTX8UiWr+q71aWfv/Qb97YYSyMujSRbAAAAFZ0RVh0Y29tbWVudABUaGlzIGFydCBpcyBpbiB0aGUgcHVibGljIGRvbWFpbi4gS2V2aW4gSHVnaGVzLCBrZXZpbmhAZWl0LmNvbSwgU2VwdGVtYmVyIDE5OTV29u+cAAAAAElFTkSuQmCC"
        "compressed" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWCAMAAAD3n0w0AAADAFBMVEX//////8z//5n//2b//zP//wD/zP//zMz/zJn/zGb/zDP/zAD/mf//mcz/mZn/mWb/mTP/mQD/Zv//Zsz/Zpn/Zmb/ZjP/ZgD/M///M8z/M5n/M2b/MzP/MwD/AP//AMz/AJn/AGb/ADP/AADM///M/8zM/5nM/2bM/zPM/wDMzP/MzMzMzJnMzGbMzDPMzADMmf/MmczMmZnMmWbMmTPMmQDMZv/MZszMZpnMZmbMZjPMZgDMM//MM8zMM5nMM2bMMzPMMwDMAP/MAMzMAJnMAGbMADPMAACZ//+Z/8yZ/5mZ/2aZ/zOZ/wCZzP+ZzMyZzJmZzGaZzDOZzACZmf+ZmcyZmZmZmWaZmTOZmQCZZv+ZZsyZZpmZZmaZZjOZZgCZM/+ZM8yZM5mZM2aZMzOZMwCZAP+ZAMyZAJmZAGaZADOZAABm//9m/8xm/5lm/2Zm/zNm/wBmzP9mzMxmzJlmzGZmzDNmzABmmf9mmcxmmZlmmWZmmTNmmQBmZv9mZsxmZplmZmZmZjNmZgBmM/9mM8xmM5lmM2ZmMzNmMwBmAP9mAMxmAJlmAGZmADNmAAAz//8z/8wz/5kz/2Yz/zMz/wAzzP8zzMwzzJkzzGYzzDMzzAAzmf8zmcwzmZkzmWYzmTMzmQAzZv8zZswzZpkzZmYzZjMzZgAzM/8zM8wzM5kzM2YzMzMzMwAzAP8zAMwzAJkzAGYzADMzAAAA//8A/8wA/5kA/2YA/zMA/wAAzP8AzMwAzJkAzGYAzDMAzAAAmf8AmcwAmZkAmWYAmTMAmQAAZv8AZswAZpkAZmYAZjMAZgAAM/8AM8wAM5kAM2YAMzMAMwAAAP8AAMwAAJkAAGYAADPuAADdAAC7AACqAACIAAB3AABVAABEAAAiAAARAAAA7gAA3QAAuwAAqgAAiAAAdwAAVQAARAAAIgAAEQAAAO4AAN0AALsAAKoAAIgAAHcAAFUAAEQAACIAABHu7u7d3d27u7uqqqqIiIh3d3dVVVVEREQiIiIREREAAAD7CIKZAAAAJXRSTlP///////////////////////////////////////////////8AP89CTwAAAAFiS0dEAIgFHUgAAABvSURBVBjTbdDBEcAgCERRCtkjNdnWNkKPxqAESPI9+WYcFdGV3WkmjiIm9odFC6ZWfDRwmq8X7jqKjFUgcVA2go44uHgqApGIRASi4lE05EZWZBxnIvMiBrI+iRupFfXe5zcP9r9/0IbXRqc62+guxA1pHhM1OxMAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
        "layout" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAG1BMVEX/////zDP/MzPM//+ZmZmZZjNmzP8zMzMAAACXXwbjAAAABHRSTlP///8AQCqp9AAAAAFiS0dEAIgFHUgAAABkSURBVAhbYygHg2JjY2OGAgYgYGdHMBmKQUz28vICdgZ2MFMwLYGdASgMZIqlJXBUVFSAmGlAZkdHB4gZGhrAwOLiAWMygJkMEIDGBGnpaCBOlIGJg3hROLPcBQKAjjTugAJjAHcsL5NBLayrAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "a" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAYUlEQVQIW0XL0QkFIQxE0Uu0gXTwWFLAk1jAItN/TfsR0ft1GBgyMzOHu/MHaO2ScdkuGZtdc26GpKJpPVGMeDdt9ZdiHMZSFLt+pqIJ9orBudF1aJeYDrFLCCefajqunX9GYBUGKXV+fgAAAFZ0RVh0Y29tbWVudABUaGlzIGFydCBpcyBpbiB0aGUgcHVibGljIGRvbWFpbi4gS2V2aW4gSHVnaGVzLCBrZXZpbmhAZWl0LmNvbSwgU2VwdGVtYmVyIDE5OTV29u+cAAAAAElFTkSuQmCC"
        "c" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAWklEQVQIW6XOwQ3AIAwDQKuwQFZADFBEBuDh/WeqS1Ol//p1ssCAuTPMDCeUUpIYm1xiuVlJUbW4iOruL0lu6t7RerTAh+ixENRu1XSP1/IA/7XJ2Z7ok8aIXZrJF1zSKF8XAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "p" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAWUlEQVQIW6XOwQ3AIAwDQKuwQFZADFAEA/Dw/jPVKUE8+qxfJyskoL9pZoYbSkqHaM7MKaZFiqrFSeQxxibJGMBVajwDFl3Alz5T49putehfe9jLij5pjNgDZSkW3Bf9BUEAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
        "f" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAV0lEQVQIW6XOsQ3AIAwEwFfMAl4BMUAQDJDC+8+UNwa5SJmvjpdljLHSVRU3GJEkelKcxYxkHSxzTucD8Gmrpa/aDhF0AV/6TNtfnJaL/rXJUSM8Um1HX8qSFhCXoClNAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "dvi" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAYElEQVQIW4XO0QnAIAwE0KNxgawgDqDoAKVk/5l6JtKWUuh9PY9TRPc0VUUFI+I0RtBuihMgWUebxhhkMTsSj+sFbLlMsgacFIlJ233yamMbxDWwxzX7Gvyx5wg/qbaiJ3c5GNbDitJEAAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "uuencoded" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAV0lEQVQIW6XOgQkAIQwDwPB1ga4gHUDREbr/TF9jnw7wAeEIoYjFTFXFQESENHcXzEMnhTwDRH3btvfObYuXF/B0yxYgnYTlhY/VWhE1+M3Vb+KT6hl9AccsFtxw1Z74AAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "script" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAUUlEQVQIW62OwQkAMQgEl5gGbCFcAQmxAB/2X9N5URDunXmNAwtiHxYzY8IhKsUqpaOqrp4xuxm6iGT107KijScrEBr89JuY3q+lewT+JFvCL93uFjw90q48AAAAVnRFWHRjb21tZW50AFRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtldmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NXb275wAAAAASUVORK5CYII="
        "tex" = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAWBAMAAAAyb6E1AAAAD1BMVEX////M//+ZmZkzMzMAAABVsTOVAAAAAnRSTlP/AOW3MEoAAAABYktHRACIBR1IAAAAZUlEQVQIW22OwQ3AIAzETg0LZIOqYgAQDMAj+8/UCzQtj/plHQaBNqmqigIiEmqC6mpEIJ9yXkHqvVOznUg8mcEAjitTx6Biqa+AK9iGLlytiIWSCNJ7bVu3dnvhV9u14CfVHvQGpoAYDqEpl2MAAABWdEVYdGNvbW1lbnQAVGhpcyBhcnQgaXMgaW4gdGhlIHB1YmxpYyBkb21haW4uIEtldmluIEh1Z2hlcywga2V2aW5oQGVpdC5jb20sIFNlcHRlbWJlciAxOTk1dvbvnAAAAABJRU5ErkJggg=="
    }

    # List of common MIME Types 
    $MIMETYPES = @{
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
        ".htm" = "text/html; charset=UTF-8"
        ".avi" = "video/x-msvideo"
        ".avif" = "image/avif"
        ".jar" = "application/java-archive"
        ".json" = "application/json; charset=UTF-8"
        ".webp" = "image/webp"
        ".ts" = "video/mp2t"
        ".bin" = "application/octet-stream"
        ".weba" = "audio/webm"
        ".tif" = "image/tiff"
        ".js" = "text/javascript; charset=UTF-8"
        ".html" = "text/html; charset=UTF-8"
        ".txt" = "text/plain; charset=UTF-8"
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
        ".xml" = "application/xml; charset=UTF-8"
        ".odt" = "application/vnd.oasis.opendocument.text"
        ".vsd" = "application/vnd.visio"
        ".rtf" = "application/rtf"
        ".eot" = "application/vnd.ms-fontobject"
        ".xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        ".sh" = "application/x-sh"
        ".mpeg" = "video/mpeg"
        ".css" = "text/css; charset=UTF-8"
        ".csv" = "text/csv; charset=UTF-8"
        ".otf" = "font/otf"
        ".ogv" = "video/ogg"
        ".jsonld" = "application/ld+json; charset=UTF-8"
        ".7z" = "application/x-7z-compressed"
        ".xul" = "application/vnd.mozilla.xul+xml"
        ".jpeg" = "image/jpeg"
        ".svg" = "image/svg+xml"
        ".mid" = "audio/midi"
        ".odp" = "application/vnd.oasis.opendocument.presentation"
        ".xhtml" = "application/xhtml+xml; charset=UTF-8"
        ".mpkg" = "application/vnd.apple.installer+xml"
        ".jpg" = "image/jpeg"
        ".gif" = "image/gif"
        ".apng" = "image/apng"
        ".ttf" = "font/ttf"
        ".wav" = "audio/wav"
        ".xls" = "application/vnd.ms-excel"
        ".zip" = "application/zip"
    }

    # Get icon for file extension 
    function GetItemIcon {
        param($Extension)
        
        $Mimetype = $MIMETYPES[$Extension]

        if ($Extension -in ".html", ".shtml", ".htm", ".pdf") {
            return $ICONS["layout"]
        }

        switch -Wildcard ($Mimetype) {
            "text/*" { return $ICONS["text"] }
            "image/*" { return $ICONS["image"] }
            "audio/*" { return $ICONS["sound"] }
            "video/*" { return $ICONS["video"] }
        }

        if ($Extension -in "") {
            return $ICONS["blank"]
        } elseif ($Extension -in ".tex") {
            return $ICONS["tex"]
        } elseif ($Extension -in ".md") {
            return $ICONS["hand.right"]
        } elseif ($Extension -in ".hqx") {
            return $ICONS["binhex"]
        } elseif ($Extension -in ".tar") {
            return $ICONS["tar"]
        } elseif ($Extension -in ".txt") {
            return $ICONS["text"]
        } elseif ($Extension -in ".c") {
            return $ICONS["c"]
        } elseif ($Extension -in ".for") {
            return $ICONS["f"]
        } elseif ($Extension -in ".dvi") {
            return $ICONS["dvi"]
        } elseif ($Extension -in ".uu") {
            return $ICONS["uuencoded"]
        } elseif ($Extension -in ".pl", "py") {
            return $ICONS["p"]
        } elseif ($Extension -in ".bin", ".exe") {
            return $ICONS["binary"]
        } elseif ($Extension -in ".ps", ".ai", ".eps") {
            return $ICONS["a"]
        } elseif ($Extension -in ".wrl", ".wrl.gz", ".vrml", ".vrm", ".iv") {
            return $ICONS["world"]
        } elseif ($Extension -in ".conf", ".sh", ".shar", ".csh", ".ksh", ".tcl") {
            return $ICONS["script"]
        } elseif ($Extension -in ".Z", ".z", ".zip", ".7z", ".bz", "bz2", ".rar", ".gz", ".tgz", ".epub") {
            return $ICONS["compressed"]
        }

        return $ICONS["unknown"]
    }

    # Get the short file size 
    function GetShortFilesize {
        param($Filesize)

        $suffix = @("", "K", "M", "G", "T", "P", "E", "Z", "Y")

        $i = 0;
        while ($Filesize -gt 1kb) {
            $Filesize /= 1kb
            $i++
        }

        "{0:N1}{1}" -f $Filesize, $suffix[$i]
    }

    function GetServerInformation {
        "Powershell/$($PSVersionTable.PSVersion) ($([System.Environment]::OSVersion.Platform)) Server at $($request.Url.Host) Port $($request.Url.Port)"
    }
    
    # Display the files and folder in the current directory
    function ViewDirectoryContent {
        $Directory = $request.RawUrl.Split('?')[0].TrimEnd('/')
        $Directory = if ($Directory -ne "") { [URI]::UnescapeDataString($Directory) } else { "/" }

        $ParentDirectory = $Directory.Substring(0, $Directory.LastIndexOf('/') + 1)

        $C = $request.QueryString['C']
        $O = $request.QueryString['O']

        if (!$C) { $C = 'N' }
        if (!$O) { $O = 'A' }

        $TableHead = @{
            'N' = "Name"
            'M' = "LastWriteTime"
            'S' = "Length"
            'D' = "VersionInfo.FileDescription"
        }

        $Properties = @{}
        $Properties.Expression = $TableHead[$C]

        if ($O -eq 'A') { 
            $Properties.Ascending = $true 
        } else { 
            $Properties.Descending = $true 
        } 

        "<!DOCTYPE html>
<html>
    <head>
        <title>Index of $Directory</title>
    </head>
    <body>
        <h1>Index of $Directory</h1>
        <pre><table>
            <thead>
                <tr>
                    <th>&nbsp;</th>
                    <th><a href=`"?C=N&O=$(if ($C -eq 'N' -and $O -eq 'A') { 'D' } else { 'A' })`">Name</a></th>
                    <th><a href=`"?C=M&O=$(if ($C -eq 'M' -and $O -eq 'A') { 'D' } else { 'A' })`">Last Modified</a></th>
                    <th><a href=`"?C=S&O=$(if ($C -eq 'S' -and $O -eq 'A') { 'D' } else { 'A' })`">Size</a></th>
                    <th><a href=`"?C=D&O=$(if ($C -eq 'D' -and $O -eq 'A') { 'D' } else { 'A' })`">Description</a></th>
                </tr>
                <tr>
                    <th colspan=`"5`"><hr /></th>
                </tr>
            </thead>
            <tbody>
            <tr>
                <td valign=`"top`"><img src=`"$($ICONS["back"])`" valign=`"middle`" align=`"left`" alt=`"Return to parent directory`" title=`"Back`"></td>
                <td><a href=`"$ParentDirectory`">Parent Directory</a></td>
                <td>&nbsp;</td>
                <td align=`"right`">-</td>
                <td>&nbsp;</td>
            </tr>
            "
            Get-ChildItem -Path ("." + $Directory) | Sort-Object -Property $Properties | ForEach-Object -Process {
            "<tr>
                <td valign=`"top`"><img src=`"$(if ($_.PSIsContainer) { $ICONS["folder"] } else { GetItemIcon -Extension $_.Extension })`" valign=`"middle`" align=`"left`" /></td>
                <td><a href=`"$([URI]::EscapeUriString($_.Name))$(if ($_.PSIsContainer) {'/'})`">$($_.Name)</a></td>
                <td>$($_.LastWriteTime)</td>
                <td align=`"right`">$(
                    if (!$_.PSIsContainer) {
                        if ($_.Length -gt 1kb) { 
                            GetShortFilesize -Filesize $_.Length 
                        } else {
                            $_.Length
                        }
                    } else {
                        '-'
                    }
                )</td>
                <td>$($_.VersionInfo.FileDescription)</td>
            </tr>
            "
            }
            "<tr>
                <td colspan=`"5`"><hr /></td>
            </tr>
            </tbody>
        </table></pre>
        <address>$(GetServerInformation)</address>
    </body>
</html>"
    }

    # Response with an error code 
    function ErrorResponse {
        param([int] $StatusCode)

        switch ($StatusCode) {
            404 {
                $Description = "Not Found"
                $Details = "The requested URL {0} was not found on this server." -f $request.RawUrl
                break
            }
            403 {
                $Description = "Forbidden"
                $Details = "You don't have permission to access this resource."
                break
            }
            401 {
                $Description = "Unauthorized"
                $Details = "This server could not verify that you are authorized to access the document requested. Either you supplied the wrong credentials (e.g., bad password), or your browser doesn't understand how to supply the credentials required."
                break
            }
            400 {
                $Description = "Bad Request"
                $Details = "Your browser sent a request that this server could not understand."
                break
            }
            default {
                $StatusCode = 500
                $Description = "Internal Server Error"
                $Details = "The Server encountered an internal error or misconfiguration and was unable to complete your request.",
                           "More information about this error may be available in the server error log."
                break
            }
        }

        $content = "<!DOCTYPE html>
<html>
    <head>
        <title>$Description</title>
    </head>
    <body>
        <h1>$Description</h1>
        $($Details | ForEach-Object { "<p>$_</p>" })
        <hr />
        <address>$(GetServerInformation)</address>
    </body>
</html>"

        $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($content)

        $response.StatusCode = $StatusCode
        $response.StatusDescription = $StatusDescription
        $response.ContentLength64 = $fileBytes.Length
        $response.ContentType = "text/html; charset=UTF-8"
        $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
        $response.OutputStream.Close()
    }
     
    while ($serverRunning.Value -and $listener.IsListening) {
        try {
            $context = $listener.GetContext()

            $request = $context.Request
            $response = $context.Response
            
            $clientIP = $request.UserHostAddress.ToString()

            $filePath = "." + [URI]::UnescapeDataString($request.RawUrl.Split('?')[0])
            
            $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            # Check if file exists
            if (Test-Path -Path $filePath) {
                if (Test-Path -Path $filePath -PathType Leaf) {
                    $contentType = "application/octet-stream" # Default to binary content type

                    $fileExtension = [System.IO.Path]::GetExtension($filePath)

                    if ($MIMETYPES.ContainsKey($fileExtension)) {
                        $contentType = $MIMETYPES[$fileExtension]
                    }
                    
                    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                } else {
                    $contentType = "text/html; charset=UTF-8"

                    $indexPath = $filePath + "\index.html"
                    
                    # Check if index file exists
                    if (Test-Path $indexPath) {
                        $fileBytes = [System.IO.File]::ReadAllBytes($indexPath)
                    } else {
                        if (!$request.Url.AbsolutePath.EndsWith('/')) {
                            $response.Redirect($request.Url.AbsolutePath + '/')
                            continue
                        }
                        $fileBytes = [System.Text.Encoding]::UTF8.GetBytes((ViewDirectoryContent -Request $request))
                    }
                }

                $response.ContentLength64 = $fileBytes.Length
                $response.ContentType = $contentType
                $response.StatusCode = 200
                $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                $response.OutputStream.Close()
            } else {
                # Return 404 if file not found
                ErrorResponse -StatusCode 404
            }
        }
        catch {
            Write-Host "[!] Error occurred: $_, " 
            ErrorResponse -StatusCode 500
        } 
        finally {
            Write-Host "[+] [$currentDateTime] $clientIP [$($response.StatusCode)]: $($request.HttpMethod) $($request.RawUrl)"
            $response.Close()
            $response.Dispose()
        }
    }
}

$serverRunning = $true

$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.Open()

# Run a separate PS Instance to allow exiting server by pressing CTRL+C
$PSInstance = [powershell]::Create()
$PSInstance.AddScript($httphandler).AddArgument($listener).AddArgument([ref]$serverRunning) | Out-Null
$PSInstance.Streams.ClearStreams()
$PSInstance.Runspace = $Runspace
$PSInstance.BeginInvoke() | Out-Null

try {
    while ($listener.IsListening) {
        Start-Sleep -Milliseconds 500
        $PSInstance.Streams.Debug | Write-Debug
        $PSInstance.Streams.Output | Write-Output
        $PSInstance.Streams.Information | Write-Host
        $PSInstance.Streams.Verbose | Write-Verbose
        $PSInstance.Streams.Warning | Write-Warning
        $PSInstance.Streams.ClearStreams()
    }
} finally {
    Write-Host "[*] Stopping the server..."
    $serverRunning = $false
    Start-Sleep -Milliseconds 500
    $listener.Stop()
    $listener.Close()
    $PSInstance.Stop()
    $PSInstance.Dispose()
    $Runspace.Close()
    $Runspace.Dispose()
    Write-Host "[*] Server stopped."
}
