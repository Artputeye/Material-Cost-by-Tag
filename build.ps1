# build.ps1
$ExtensionName = "MaterialCostByTag"
$OutputFile = "$ExtensionName.rbz"
$TempZip = "$ExtensionName.zip"

# รายการไฟล์และโฟลเดอร์ที่จะรวมเข้าไปใน .rbz
$IncludeItems = @(
    "MaterialCostByTag.rb",
    "data",
    "icons",
    "src",
    "ui"
)

# ลบไฟล์เก่าออกก่อนถ้ามี
if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }
if (Test-Path $TempZip) { Remove-Item $TempZip -Force }

Write-Host "Building $OutputFile..." -ForegroundColor Cyan

# บีบอัดเฉพาะรายการที่กำหนดเป็น .zip
Compress-Archive -Path $IncludeItems -DestinationPath $TempZip -Force

# เปลี่ยนนามสกุลจาก .zip เป็น .rbz
Rename-Item -Path $TempZip -NewName $OutputFile

Write-Host "Build success! Output: $OutputFile" -ForegroundColor Green