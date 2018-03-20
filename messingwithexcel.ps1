Install-Module ImportExcel
$reportLines = Import-Excel C:\code\Book1.xlsx 
$reportLines | ForEach-Object {Write-Host $_.test2, $_.test}

$xl = New-Object -ComObject Excel.Application

$xl.Visible = $true

$xl.Workbooks.Add()

$file = "C:\code\Book1.xlsx"
$sheetName = "Sheet1"

$objExcel = New-Object -ComObject Excel.Application
$workbook = $objExcel.Workbooks.Open($file)
$sheet = $workbook.Worksheets.Item($sheetName)
$objExcel.Visible=$false

$rowMax = ($sheet.UsedRange.Rows).count

$rowName,$colName = 1,1
$rowAge,$colAge = 1,2
$rowCity,$colCity = 1,3

for ($i=1; $i -le $rowMax-1; $i++)
{
$name = $sheet.Cells.Item($rowName+$i,$colName).text
$age = $sheet.Cells.Item($rowAge+$i,$colAge).text
$city = $sheet.Cells.Item($rowCity+$i,$colCity).text

}
$objExcel.quit()