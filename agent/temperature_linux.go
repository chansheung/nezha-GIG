//go:build linux

package temperature

import (
	"bufio"
	"context"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strconv"
	"strings"

	"github.com/nezhahq/agent/model"
)

var sensorIgnoreList = []string{
	"PMU tcal",
	"noname",
}

// resolveMountName resolves the display name for an NVMe sensor.
// It checks:
//  1. Direct mount in /proc/mounts (e.g., /dev/nvme0n1p1 -> /mnt/data)
//  2. Software RAID membership (mdadm) - if the NVMe is part of an md array,
//     uses the md device's mount point name (e.g., /dev/md1 -> /mnt/m2_16t)
//  3. Falls back to "nvmeX"
func resolveMountName(nvmeNum string) string {
	// Step 1: Try direct mount
	devPath := "/dev/nvme" + nvmeNum + "n1"
	if name := findMountPointName(devPath); name != "" {
		if name != "/" && name != "/boot" && name != "/boot/efi" {
			return filepath.Base(name)
		}
		return "system"
	}

	// Step 2: Check if NVMe is a member of a software RAID array
	if mdName := findRaidForNvme(nvmeNum); mdName != "" {
		if name := findMountPointName("/dev/" + mdName); name != "" {
			return filepath.Base(name)
		}
		return mdName
	}

	// Step 3: Fallback
	return "nvme" + nvmeNum
}

// findMountPointName checks /proc/mounts for the first mount entry whose
// device field starts with the given prefix. Returns the mount path, or ""
// if not found.
func findMountPointName(devPath string) string {
	f, err := os.Open("/proc/mounts")
	if err != nil {
		return ""
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) >= 2 && strings.HasPrefix(fields[0], devPath) {
			return fields[1]
		}
	}
	return ""
}

// findRaidForNvme checks /sys/block/md*/slaves/ to see if the given NVMe
// device (by number, e.g. "0" for nvme0n1) is a member of a software RAID
// array. Returns the md device name (e.g. "md1") or "" if not found.
func findRaidForNvme(nvmeNum string) string {
	devName := "nvme" + nvmeNum + "n1"
	mdDirs, err := filepath.Glob("/sys/block/md*")
	if err != nil {
		return ""
	}
	for _, mdDir := range mdDirs {
		info, err := os.Stat(mdDir)
		if err != nil || !info.IsDir() {
			continue
		}
		slavePath := filepath.Join(mdDir, "slaves", devName)
		if _, err := os.Stat(slavePath); err == nil {
			return filepath.Base(mdDir)
		}
	}
	return ""
}

// getNvidiaGpuTemps queries nvidia-smi for GPU temperatures and memory usage.
// Returns sensor entries named "GPU_0", "GPU_1", etc. (temperature)
// and "GPU_0_mem", "GPU_1_mem", etc. (memory usage percentage).
func getNvidiaGpuTemps() []model.SensorTemperature {
	// Query GPU temperature and memory in one call
	out, err := exec.Command("nvidia-smi", "--query-gpu=index,name,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits").Output()
	if err != nil {
		return nil
	}
	var result []model.SensorTemperature
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		// Format: index, name, temp.gpu, memory.used, memory.total
		parts := strings.SplitN(line, ", ", 5)
		if len(parts) < 5 {
			continue
		}
		idx := strings.TrimSpace(parts[0])
		tempStr := strings.TrimSpace(parts[2])
		memUsedStr := strings.TrimSpace(parts[3])
		memTotalStr := strings.TrimSpace(parts[4])

		// GPU temperature
		temp, err := strconv.ParseFloat(tempStr, 64)
		if err == nil && temp > 0 {
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx,
				Temperature: temp,
			})
		}

		// GPU memory usage percentage
		memUsed, err1 := strconv.ParseFloat(memUsedStr, 64)
		memTotal, err2 := strconv.ParseFloat(memTotalStr, 64)
		if err1 == nil && err2 == nil && memTotal > 0 {
			memPct := math.Round(memUsed/memTotal*1000) / 10
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx + "_mem",
				Temperature: memPct,
			})
			// GPU memory used (MiB)
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx + "_mem_used",
				Temperature: memUsed,
			})
			// GPU memory total (MiB)
			result = append(result, model.SensorTemperature{
				Name:        "GPU_" + idx + "_mem_total",
				Temperature: memTotal,
			})
		}
	}
	return result
}

func GetState(_ context.Context) ([]model.SensorTemperature, error) {
	var tempStat []model.SensorTemperature

	hwmons, err := filepath.Glob("/sys/class/hwmon/hwmon*")
	if err != nil {
		return nil, err
	}

	for _, hwmonDir := range hwmons {
		link, err := os.Readlink(hwmonDir)
		if err != nil {
			continue
		}
		hwmonPath := filepath.Clean(filepath.Join(hwmonDir, link))

		nameBytes, err := os.ReadFile(filepath.Join(hwmonDir, "name"))
		if err != nil {
			continue
		}
		chipName := strings.TrimSpace(string(nameBytes))

		prefix := chipName
		if chipName == "nvme" {
			parts := strings.Split(hwmonPath, "/nvme/nvme")
			if len(parts) >= 2 {
				nvmeNum := strings.Split(parts[1], "/")[0]
				prefix = resolveMountName(nvmeNum)
			}
		}
		isK10temp := chipName == "k10temp"

		inputs, _ := filepath.Glob(filepath.Join(hwmonDir, "temp*_input"))
		for _, input := range inputs {
			base := strings.TrimSuffix(input, "_input")
			labelBytes, _ := os.ReadFile(base + "_label")
			label := ""
			if len(labelBytes) > 0 {
				label = strings.TrimSpace(string(labelBytes))
			}

			sensorKey := prefix
			if label != "" {
				if isK10temp {
					labelLower := strings.ToLower(label)
					if labelLower == "tctl" {
						sensorKey = "CPU"
					} else if strings.HasPrefix(labelLower, "tccd") {
						sensorKey = "CPU_" + labelLower[4:]
					} else {
						sensorKey = prefix + "_" + strings.ReplaceAll(labelLower, " ", "_")
					}
				} else {
					labelLower := strings.ToLower(label)
					if labelLower == "composite" {
						labelLower = "zcomposite"
					}
					sensorKey = prefix + "_" + strings.ReplaceAll(labelLower, " ", "_")
				}
			}

			if slices.Contains(sensorIgnoreList, sensorKey) {
				continue
			}

			tempBytes, err := os.ReadFile(input)
			if err != nil {
				continue
			}
			tempMilli, err := strconv.ParseFloat(strings.TrimSpace(string(tempBytes)), 64)
			if err != nil {
				continue
			}
			temp := tempMilli / 1000.0
			if temp <= 0 {
				continue
			}

			tempStat = append(tempStat, model.SensorTemperature{
				Name:        sensorKey,
				Temperature: temp,
			})
		}
	}

	gpuTemps := getNvidiaGpuTemps()
	tempStat = append(tempStat, gpuTemps...)

	slices.SortFunc(tempStat, func(a, b model.SensorTemperature) int {
		return strings.Compare(a.Name, b.Name)
	})

	return tempStat, nil
}
