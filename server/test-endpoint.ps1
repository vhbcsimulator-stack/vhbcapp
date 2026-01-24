try {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $jsonPath = Join-Path $scriptPath "test-request.json"
    
    $response = Invoke-WebRequest -Uri 'http://localhost:3000/api/chat' -Method POST -Headers @{'Content-Type'='application/json'} -InFile $jsonPath -UseBasicParsing
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)"
    Write-Host "`nResponse:"
    Write-Host $response.Content
} catch {
    Write-Host "❌ FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "`nResponse Body:"
        Write-Host $responseBody
    }
}
