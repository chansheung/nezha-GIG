//go:build windows

package temperature

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strconv"
	"strings"

	"github.com/nezhahq/agent/model"
	"github.com/shirou/gopsutil/v4/sensors"
	"github.com/yusufpapurcu/wmi"
)

var sensorIgnoreList = []string{
	"PMU tcal",
	"noname",
}

// MSAcpiThermalZoneTemperature represents ACPI thermal zone temperature.
type MSAcpiThermalZoneTemperature struct {
	InstanceName string
	Temperature  uint32 // in tenths of Kelvin
}

// MSStorageDriverFailurePredictStatus represents disk drive temperature.
type MSStorageDriverFailurePredictStatus struct {
	InstanceName   string
	PredictFailure bool
	Temperature    uint32 // in Celsius
}

// Win32_ThermalZoneInformation represents CPU thermal zone temperature from performance counters.
type Win32ThermalZoneInformation struct {
	Name        string
	Temperature uint32 // in Kelvin
}

// MSFTStorageReliabilityCounter represents disk reliability counter with temperature.
type MSFTStorageReliabilityCounter struct {
	DeviceId    string
	Temperature uint8 // directly in Celsius
}

// diskTempResult represents the JSON output from the PowerShell disk query.
type diskTempResult struct {
	DeviceId     string `json:"DeviceId"`
	Temperature  int    `json:"Temperature"`
	FriendlyName string `json:"FriendlyName"`
}

// ---- nvidia-smi discovery ----

// nvidiaSmiPaths caches the found nvidia-smi executable path.
var nvidiaSmiPath string

// findNvidiaSmi searches for nvidia-smi executable in common locations.
// Returns the full path or empty string if not found.
func findNvidiaSmi() string {
	if nvidiaSmiPath != "" {
		return nvidiaSmiPath
	}

	// Candidates to search
	candidates := []string{
		"nvidia-smi",                               // via PATH
		filepath.Join(os.Getenv("ProgramFiles"), "NVIDIA Corporation", "NVSMI", "nvidia-smi.exe"),
		filepath.Join(os.Getenv("ProgramW6432"), "NVIDIA Corporation", "NVSMI", "nvidia-smi.exe"),
		filepath.Join(os.Getenv("SystemDrive")+"\\", "Program Files", "NVIDIA Corporation", "NVSMI", "nvidia-smi.exe"),
		filepath.Join(os.Getenv("SystemDrive")+"\\", "Program Files (x86)", "NVIDIA Corporation", "NVSMI", "nvidia-smi.exe"),
	}

	for _, candidate := range candidates {
		path, err := exec.LookPath(candidate)
		if err == nil {
			nvidiaSmiPath = path
			return path
		}
		// Also try as absolute path
		if _, err := os.Stat(candidate); err == nil {
			nvidiaSmiPath = candidate
			return candidate
		}
	}
	return ""
}

// ---- WMI sensor readers ----

// getCpuTemperatures queries Win32_PerfFormattedData_Counters_ThermalZoneInformation for CPU temps.
func getCpuTemperatures() []model.SensorTemperature {
	var zones []Win32ThermalZoneInformation
	q := "SELECT Name, Temperature FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation"
	err := wmi.Query(q, &zones)
	if err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for i, z := range zones {
		// Temperature is in Kelvin
		tempC := float64(z.Temperature) - 273.15
		if tempC <= 0 || tempC > 150 {
			continue
		}
		name := fmt.Sprintf("CPU_%d", i)
		if z.Name != "" {
			// Use a short name derived from the instance name
			parts := strings.Split(z.Name, "\\")
			shortName := parts[len(parts)-1]
			name = "CPU_" + shortName
		}
		result = append(result, model.SensorTemperature{
			Name:        name,
			Temperature: math.Round(tempC*10) / 10,
		})
	}
	return result
}

// getACPIThermalZones queries WMI for ACPI thermal zone temperatures.
func getACPIThermalZones() []model.SensorTemperature {
	var zones []MSAcpiThermalZoneTemperature
	q := "SELECT InstanceName, Temperature FROM MSAcpi_ThermalZoneTemperature"
	if err := wmi.Query(q, &zones); err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for i, z := range zones {
		// Temperature is in tenths of Kelvin
		tempC := float64(z.Temperature)/10.0 - 273.15
		if tempC <= 0 || tempC > 150 {
			continue
		}
		name := fmt.Sprintf("CPU_%d", i)
		result = append(result, model.SensorTemperature{
			Name:        name,
			Temperature: math.Round(tempC*10) / 10,
		})
	}
	return result
}

// getDiskTemperaturesStorage queries MSFT_StorageReliabilityCounter for disk temperatures.
func getDiskTemperaturesStorage() []model.SensorTemperature {
	var counters []MSFTStorageReliabilityCounter
	q := "SELECT DeviceId, Temperature FROM MSFT_StorageReliabilityCounter"
	err := wmi.Query(q, &counters, "ROOT/Microsoft/Windows/Storage")
	if err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for _, c := range counters {
		if c.Temperature == 0 || c.Temperature > 150 {
			continue
		}
		result = append(result, model.SensorTemperature{
			Name:        "Disk_" + c.DeviceId,
			Temperature: float64(c.Temperature),
		})
	}
	return result
}

// getDiskTemperatures queries WMI for disk drive temperatures via MSStorageDriver.
func getDiskTemperatures() []model.SensorTemperature {
	var diskStatuses []MSStorageDriverFailurePredictStatus
	q := "SELECT InstanceName, PredictFailure, Temperature FROM MSStorageDriver_FailurePredictStatus"
	if err := wmi.Query(q, &diskStatuses); err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for _, d := range diskStatuses {
		if d.Temperature == 0 || d.Temperature > 150 {
			continue
		}
		// Try to get a readable name for this disk
		name := resolveDiskName(d.InstanceName)
		result = append(result, model.SensorTemperature{
			Name:        name,
			Temperature: float64(d.Temperature),
		})
	}
	return result
}

// resolveDiskName attempts to get a human-readable name for a disk.
func resolveDiskName(instanceName string) string {
	// If the instance name contains NVMe, try to extract a meaningful name
	name := strings.ReplaceAll(instanceName, " ", "_")
	// Truncate if too long
	if len(name) > 60 {
		// Try to extract just the disk model/type part
		parts := strings.Split(name, "\\")
		if len(parts) >= 2 {
			return parts[len(parts)-1]
		}
		name = name[:60]
	}
	return name
}

// getGopsutilTemperatures uses gopsutil as fallback for sensor temperatures.
func getGopsutilTemperatures() []model.SensorTemperature {
	temperatures, err := sensors.SensorsTemperatures()
	if err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for _, t := range temperatures {
		if t.Temperature > 0 && !slices.Contains(sensorIgnoreList, t.SensorKey) {
			result = append(result, model.SensorTemperature{
				Name:        t.SensorKey,
				Temperature: t.Temperature,
			})
		}
	}
	return result
}

// ---- nvidia-smi GPU reader ----

// getNvidiaGpuTemps queries nvidia-smi for GPU temperatures and memory usage.
func getNvidiaGpuTemps() []model.SensorTemperature {
	// Find nvidia-smi first
	nvidiaSmi := findNvidiaSmi()
	if nvidiaSmi == "" {
		return nil
	}

	out, err := exec.Command(nvidiaSmi, "--query-gpu=index,name,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits").Output()
	if err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, ", ", 5)
		if len(parts) < 5 {
			continue
		}
		idx := strings.TrimSpace(parts[0])
		tempStr := strings.TrimSpace(parts[2])
		memUsedStr := strings.TrimSpace(parts[3])
		memTotalStr := strings.TrimSpace(parts[4])

		temp, err := strconv.ParseFloat(tempStr, 64)
		if err == nil && temp > 0 {
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx,
				Temperature: temp,
			})
		}

		memUsed, err1 := strconv.ParseFloat(memUsedStr, 64)
		memTotal, err2 := strconv.ParseFloat(memTotalStr, 64)
		if err1 == nil && err2 == nil && memTotal > 0 {
			memPct := math.Round(memUsed/memTotal*1000) / 10
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx + "_mem",
				Temperature: memPct,
			})
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx + "_mem_used",
				Temperature: memUsed,
			})
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx + "_mem_total",
				Temperature: memTotal,
			})
		}
	}
	return result
}

// getDiskTemperaturesPS uses PowerShell to query disk temperatures and friendly names.
func getDiskTemperaturesPS() []model.SensorTemperature {
	psScript := `Get-PhysicalDisk | ForEach-Object {
    $disk = $_
    $rel = $_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    if ($rel -and $rel.Temperature -gt 0) {
        [PSCustomObject]@{
            DeviceId = $rel.DeviceId
            Temperature = $rel.Temperature
            FriendlyName = $disk.FriendlyName
        }
    }
} | ConvertTo-Json -Compress`

	cmd := exec.Command("powershell", "-NoProfile", "-Command", psScript)
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	text := strings.TrimSpace(string(out))
	if text == "" || text == "null" {
		return nil
	}

	var result []model.SensorTemperature

	// Try parsing as array
	var disks []diskTempResult
	if err := json.Unmarshal([]byte(text), &disks); err != nil {
		// Try single object
		var disk diskTempResult
		if err := json.Unmarshal([]byte(text), &disk); err != nil {
			return nil
		}
		disks = []diskTempResult{disk}
	}

	for _, d := range disks {
		if d.Temperature <= 0 || d.Temperature > 150 {
			continue
		}
		// Use FriendlyName as the sensor name - this is already clean (e.g. "sn580")
		name := strings.TrimSpace(d.FriendlyName)
		if name == "" {
			name = "Disk_" + d.DeviceId
		} else {
			// Replace spaces with underscores for URL/sensor name safety
			name = strings.ReplaceAll(name, " ", "_")
		}
		result = append(result, model.SensorTemperature{
			Name:        name,
			Temperature: float64(d.Temperature),
		})
	}

	return result
}

// getCpuTemperaturesPS uses typeperf to read thermal zone temperature performance counters.
func getCpuTemperaturesPS() []model.SensorTemperature {
	cmd := exec.Command("typeperf", "\\Thermal Zone Information(*)\\Temperature", "-sc", "1")
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) < 3 {
		return nil
	}

	headers := strings.Split(lines[1], ",")
	values := strings.Split(lines[2], ",")

	var result []model.SensorTemperature
	zoneIndex := 0
	for i := 1; i < len(headers) && i < len(values); i++ {
		header := strings.TrimSpace(headers[i])
		value := strings.TrimSpace(values[i])

		if !strings.Contains(strings.ToLower(header), "temperature") {
			continue
		}

		value = strings.Trim(value, "\"")
		if value == "" {
			continue
		}

		temp, err := strconv.ParseFloat(value, 64)
		if err != nil || temp <= 0 || temp > 150 {
			continue
		}

		zoneName := fmt.Sprintf("CPU_%d", zoneIndex)
		if start := strings.Index(header, "("); start >= 0 {
			if end := strings.Index(header[start:], ")"); end >= 0 {
				name := header[start+1 : start+end]
				if name != "" {
					zoneName = "CPU_" + name
				}
			}
		}

		result = append(result, model.SensorTemperature{
			Name:        zoneName,
			Temperature: math.Round(temp*10) / 10,
		})
		zoneIndex++
	}

	return result
}

// GetState returns all sensor temperatures on Windows.
func GetState(_ context.Context) ([]model.SensorTemperature, error) {
	var tempStat []model.SensorTemperature
	seen := make(map[string]bool)

	// Helper to add deduplicated entries
	addUnique := func(t model.SensorTemperature) {
		if t.Temperature <= 0 || seen[t.Name] {
			return
		}
		if slices.Contains(sensorIgnoreList, t.Name) {
			return
		}
		seen[t.Name] = true
		tempStat = append(tempStat, t)
	}

	// 1. CPU thermal zones via Win32_PerfFormattedData_Counters_ThermalZoneInformation (Win 10/11)
	for _, t := range getCpuTemperatures() {
		addUnique(t)
	}

	// 2. CPU via ACPI thermal zones (fallback)
	for _, t := range getACPIThermalZones() {
		addUnique(t)
	}

	// 3. Disk temperatures via MSFT_StorageReliabilityCounter (most reliable on Win 10/11)
	for _, t := range getDiskTemperaturesStorage() {
		addUnique(t)
	}

	// 3a. Disk temperatures via PowerShell Get-PhysicalDisk (most reliable on Win desktop)
	for _, t := range getDiskTemperaturesPS() {
		addUnique(t)
	}

	// 4. Disk temperatures via MSStorageDriver_FailurePredictStatus (fallback)
	for _, t := range getDiskTemperatures() {
		addUnique(t)
	}

	// 5. GPU from nvidia-smi
	for _, t := range getNvidiaGpuTemps() {
		addUnique(t)
	}

	// 5a. CPU via typeperf performance counters (fallback)
	for _, t := range getCpuTemperaturesPS() {
		addUnique(t)
	}

	// 6. If we still have no data, try gopsutil as broad fallback
	if len(tempStat) == 0 {
		for _, t := range getGopsutilTemperatures() {
			addUnique(t)
		}
	}

	// Sort by name
	slices.SortFunc(tempStat, func(a, b model.SensorTemperature) int {
		return strings.Compare(a.Name, b.Name)
	})

	return tempStat, nil
}
