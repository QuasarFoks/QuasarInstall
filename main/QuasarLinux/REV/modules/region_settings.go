package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	fmt.Println("Выберите регион:")

	fmt.Println("1)  Северная Америка")
	fmt.Println("2)  Европа")
	fmt.Println("3)  Азия")
	fmt.Println("4)  Африка")
	fmt.Println("5)  Антарктида")
	fmt.Println("6)  Арктика")
	fmt.Println("7)  Атлантика")
	fmt.Println("8)  Австралия")
	fmt.Println("9)  Бразилия")
	fmt.Println("10) Канада")
	fmt.Println("11) Etc")
	fmt.Print("Выберите [1-11]: ")

	var input string
	fmt.Scanln(&input)

	var choice int
	_, err := fmt.Sscanf(input, "%d", &choice)
	if err != nil {
    		fmt.Println("Ошибка ввода")
    		return
	}

	var region string
	switch choice {
		case 1:
			region = "US"
		case 2:
			region = "Europe"
		case 3:
			region = "Asia"
		case 4:
			region = "Africa"
		case 5:
			region = "Antarctica"
		case 6:
			region = "Arctic"   
		case 7:
			region = "Atlantic"
		case 8:
			region = "Australia"
		case 9:
			region = "Brazil"
		case 10:
			region = "Canada"
		case 11:
			region = "Etc"
		default:
			fmt.Println("Неверный выбор!")
			return
	}

	// Запускаем ./region с полным доступом к терминалу
	cmd := exec.Command("./region", region)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		fmt.Printf("Ошибка: %v\n", err)
	}
}
