package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// mountChrootDirs — монтирует необходимые файловые системы для chroot
func mountChrootDirs() error {
	dirs := []string{"/dev", "/dev/pts", "/proc", "/sys", "/run"}

	for _, dir := range dirs {
		targetDir := "/mnt" + dir

		// Создаем директорию если её нет
		os.MkdirAll(targetDir, 0755)

		// Монтируем
		var mountArgs []string
		switch dir {
			case "/dev":
				mountArgs = []string{"--bind", "/dev", targetDir}
			case "/dev/pts":
				mountArgs = []string{"--bind", "/dev/pts", targetDir}
			case "/proc":
				mountArgs = []string{"-t", "proc", "proc", targetDir}
			case "/sys":
				mountArgs = []string{"-t", "sysfs", "sysfs", targetDir}
			case "/run":
				mountArgs = []string{"-t", "tmpfs", "tmpfs", targetDir}
		}

		cmd := exec.Command("mount", mountArgs...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("ошибка монтирования %s: %w", dir, err)
		}
	}

	fmt.Println(" * Файловые системы смонтированы для chroot")
	return nil
}

// unmountChrootDirs — отмонтирует файловые системы после работы
func unmountChrootDirs() {
	dirs := []string{"/run", "/sys", "/proc", "/dev/pts", "/dev"}

	for _, dir := range dirs {
		targetDir := "/mnt" + dir
		exec.Command("umount", "-R", targetDir).Run()
	}

	fmt.Println(" * Файловые системы отмонтированы")
}

// runChroot — запускает команду внутри chroot
func runChroot(args ...string) error {
	cmd := exec.Command("chroot", "/mnt")
	cmd.Args = append(cmd.Args, args...)
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// input — читает строку с клавиатуры
func input(prompt string) string {
	fmt.Print(prompt)
	reader := bufio.NewReader(os.Stdin)
	text, _ := reader.ReadString('\n')
	return strings.TrimSpace(text)
}

// addToSudoers — добавляет пользователя в sudoers
func addToSudoers(username string) error {
	fmt.Printf(" Добавляем пользователя %s в sudoers...\n", username)

	// Создаем файл в /etc/sudoers.d/ (более безопасно)
	sudoersFile := fmt.Sprintf("/etc/sudoers.d/%s", username)
	sudoersContent := fmt.Sprintf("%s ALL=(ALL:ALL) ALL\n", username)

	// Записываем конфиг в chroot
	cmd := exec.Command("chroot", "/mnt", "sh", "-c",
			    fmt.Sprintf("echo '%s' > %s", sudoersContent, sudoersFile))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("ошибка создания sudoers файла: %w", err)
	}

	// Устанавливаем правильные права (только root для чтения)
	cmd = exec.Command("chroot", "/mnt", "chmod", "440", sudoersFile)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("ошибка установки прав: %w", err)
	}

	fmt.Printf(" * Пользователь %s добавлен в sudo\n", username)
	return nil
}

// createUser — создаёт пользователя и группу
func createUser() (string, error) {
	username := input("→ Введите имя пользователя: ")
	if username == "" {
		return "", fmt.Errorf("имя пользователя не может быть пустым")
	}
	if username == "root" {
		return "", fmt.Errorf("имя пользователя не может быть root")
	}

	fmt.Printf(" Создаём группу %s...\n", username)
	runChroot("groupadd", username) // игнорируем ошибку, если группа есть

	fmt.Printf(" Создаём пользователя %s...\n", username)
	if err := runChroot("useradd", "-m", "-g", username, "-G", "wheel", username); err != nil {
		return "", fmt.Errorf("не удалось создать пользователя: %w", err)
	}

	fmt.Printf(" Установите пароль для %s:\n", username)
	if err := runChroot("passwd", username); err != nil {
		return "", fmt.Errorf("не удалось установить пароль: %w", err)
	}

	// Добавляем в sudo
	if err := addToSudoers(username); err != nil {
		return "", err
	}

	return username, nil
}

// setRootPassword — устанавливает пароль root
func setRootPassword() error {
	fmt.Println("  Установите пароль для root:")
	return runChroot("passwd")
}

// enableSudoGroup — включает группу wheel в sudo (для совместимости)
func enableSudoGroup() error {
	fmt.Println(" Активируем группу wheel в sudo...")

	// Раскомментируем строку с %wheel в sudoers
	cmd := exec.Command("chroot", "/mnt", "sed", "-i",
			    "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/",
			    "/etc/sudoers")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func main() {
	fmt.Println("=====================================")
	fmt.Println("      Настройка пользователей")
	fmt.Println("=====================================")

	// Монтируем файловые системы для chroot
	if err := mountChrootDirs(); err != nil {
		fmt.Fprintf(os.Stderr, " Ошибка монтирования: %v\n", err)
		os.Exit(1)
	}

	// Гарантируем отмонтирование при выходе
	defer unmountChrootDirs()

	// Включаем группу wheel в sudo
	if err := enableSudoGroup(); err != nil {
		fmt.Printf(" ! Предупреждение: не удалось активировать группу wheel: %v\n", err)
	}

	username, err := createUser()
	if err != nil {
		fmt.Fprintf(os.Stderr, " Ошибка: %v\n", err)
		os.Exit(1)
	}

	fmt.Println()
	if err := setRootPassword(); err != nil {
		fmt.Fprintf(os.Stderr, " Ошибка: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("\n=====================================")
	fmt.Printf("  Пользователь %s успешно создан и добавлен в sudo!\n", username)
	fmt.Println("=====================================")
}
