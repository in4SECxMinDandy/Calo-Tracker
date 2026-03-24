# Calo-Tracker API Test Script
# Tests the AI food recognition API endpoints

# ============================================================================
# CONFIGURATION
# ============================================================================

$ApiKey = "sk-proj-69981a1c7a6c4bb3ad6f5c34f274cadd"
$ApiUrl = "https://taphoaapi.info.vn/v1/messages"
$Model = "claude-3-5-sonnet-latest"

# ============================================================================
# TEST 1: Simple text-only request (no image)
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST 1: Simple text request (no image)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$body = @{
    model = $Model
    max_tokens = 50
    messages = @(
        @{
            role = "user"
            content = "Reply with a simple hello"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-WebRequest -Uri $ApiUrl `
        -Method Post `
        -Headers @{
            "x-api-key" = $ApiKey
            "Authorization" = "Bearer $ApiKey"
            "anthropic-version" = "2023-06-01"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -TimeoutSec 30

    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================================
# TEST 2: Test with Vietnamese food recognition prompt
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST 2: Food recognition prompt test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$foodPrompt = @"
You are a Vietnamese food expert. Return ONLY a JSON object:
{"foods":[{"name":"Phở bò","name_en":"Beef Noodle Soup","estimated_weight_grams":400,"confidence_score":0.9,"macros_per_100g":{"protein_g":8,"carbs_g":15,"fat_g":4}}]}
"@

$body2 = @{
    model = $Model
    max_tokens = 200
    messages = @(
        @{
            role = "user"
            content = $foodPrompt
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response2 = Invoke-WebRequest -Uri $ApiUrl `
        -Method Post `
        -Headers @{
            "x-api-key" = $ApiKey
            "Authorization" = "Bearer $ApiKey"
            "anthropic-version" = "2023-06-01"
            "Content-Type" = "application/json"
        } `
        -Body $body2 `
        -TimeoutSec 30

    Write-Host "Status: $($response2.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response2.Content
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================================
# TEST 3: Check API key validity
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST 3: API Key Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Testing with wrong API key..." -ForegroundColor Yellow

$body3 = @{
    model = $Model
    max_tokens = 50
    messages = @(
        @{
            role = "user"
            content = "Hello"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response3 = Invoke-WebRequest -Uri $ApiUrl `
        -Method Post `
        -Headers @{
            "x-api-key" = "invalid-key-12345"
            "Content-Type" = "application/json"
        } `
        -Body $body3 `
        -TimeoutSec 30

    Write-Host "Status: $($response3.StatusCode)" -ForegroundColor Yellow
} catch {
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor $(if($_.Exception.Response.StatusCode.value__ -eq 401){"Green"}else{"Red"})
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "If all tests show Status 200 = API is working" -ForegroundColor Green
Write-Host "If you see 401/403 = API key issue" -ForegroundColor Yellow
Write-Host "If you see connection errors = Network/proxy issue" -ForegroundColor Red
