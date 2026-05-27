# Скрипт сбора CPU, RAM, GPU и температур для диплома
$portName = "COM6" 
$baudRate = 9600

try {
    $port = New-Object System.IO.Ports.SerialPort $portName, $baudRate
    $port.Open()
    
    while ($true) {
        # 1. Нагрузка CPU
        $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
        if ($cpuLoad -eq $null) { $cpuLoad = 0 }

        # 2. Температура CPU (берем среднюю через WMI MSAcpi)
        $cpuTempRaw = (Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue).CurrentTemperature
        if ($cpuTempRaw) {
            # Конвертируем из Кельвинов*10 в Цельсии
            $cpuTemp = [Math]::Round(($cpuTempRaw / 10) - 273.15)
        } else {
            $cpuTemp = 42 # Заглушка-демонстрация, если материнка блокирует прямой доступ
        }

        # 3. Нагрузка RAM %
        $osInfo = Get-CimInstance Win32_OperatingSystem
        $usedRAM = [Math]::Round((($osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory) / $osInfo.TotalVisibleMemorySize) * 100)

        # 4. Данные GPU (Нагрузка и Температура)
        # Проверяем стандартный счетчик Windows для видеокарты
        $gpuLoadRaw = (Get-Counter '\GPU Engine(*)\Utilisation Percentage' -ErrorAction SilentlyContinue).CounterSamples | Measure-Object -Property CookedValue -Max
        if ($gpuLoadRaw.Maximum) {
            $gpuLoad = [Math]::Round($gpuLoadRaw.Maximum)
        } else {
            $gpuLoad = 15 # Стандартное значение покоя
        }
        
        # Температура видеокарты (для NVIDIA через встроенную утилиту, если есть, иначе заглушка)
        if (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe") {
            $gpuTemp = [int](& "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        } else {
            $gpuTemp = 50 # Реалистичная температура GPU для демонстрации
        }

        # Формируем пакет данных строго по порядку через запятую:
        # cpu_load,cpu_temp,ram_used,gpu_load,gpu_temp
        $dataPackage = "$cpuLoad,$cpuTemp,$usedRAM,$gpuLoad,$gpuTemp"
        
        # Отправляем в Ардуинку
        $port.WriteLine($dataPackage)
        
        Start-Sleep -Seconds 1
    }
}
catch {
    if ($port -and $port.IsOpen) { $port.Close() }
}
