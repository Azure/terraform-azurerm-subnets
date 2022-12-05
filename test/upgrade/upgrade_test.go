package upgrade

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamples(t *testing.T) {
	examples, err := os.ReadDir(filepath.Clean("../../examples"))
	if err != nil {
		t.Fatalf(err.Error())
	}
	for _, example := range examples {
		if !example.IsDir() {
			continue
		}
		t.Run(example.Name(), func(t *testing.T) {
			testExample(t, fmt.Sprintf("examples/%s", example.Name()))
		})
	}
}

func testExample(t *testing.T, exampleRelativePath string) {
	currentRoot, err := test_helper.GetCurrentModuleRootPath()
	if err != nil {
		t.FailNow()
	}
	currentMajorVersion, err := test_helper.GetCurrentMajorVersionFromEnv()
	if err != nil {
		t.FailNow()
	}
	test_helper.ModuleUpgradeTest(t, "Azure", "terraform-azurerm-subnets", exampleRelativePath, currentRoot, terraform.Options{
		Upgrade: true,
	}, currentMajorVersion)
}
