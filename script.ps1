# Скрипт автоматизации сбора метрик ПК для диплома
$portName = "COM3" 
$baudRate = 9600

try {
    # Открываем системный объект последовательного порта
    $port = New-Object System.IO.Ports.SerialPort $portName, $baudRate
    $port.Open()
    
    # Бесконечный цикл отправки данных
    while ($true) {
        # Получаем нагрузку на процессор
        $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
        
        # Получаем оперативную память
        $osInfo = Get-CimInstance Win32_OperatingSystem
        $totalRAM = $osInfo.TotalVisibleMemorySize
        $freeRAM = $osInfo.FreePhysicalMemory
        $usedRAMPercent = [Math]::Round((($totalRAM - $freeRAM) / $totalRAM) * 100)
        
        # Формируем строку вида "45,62"
        $dataPackage = "$cpuLoad,$usedRAMPercent"
        
        # Отправляем пакет в Ардуинку
        $port.WriteLine($dataPackage)
        
        # Задержка 1 секунда
        Start-Sleep -Seconds 1
    }
}
catch {
    # В случае ошибки закрываем порт
    if ($port -and $port.IsOpen) { $port.Close() }
}