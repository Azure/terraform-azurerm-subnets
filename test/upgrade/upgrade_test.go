package upgrade

import (
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamples(t *testing.T) {
	examples := []string{
		"exmaples/all_default",
		"examples/complete",
		"examples/new_route",
	}
	for _, example := range examples {
		t.Run(example, func(t *testing.T) {
			testExample(t, example)
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
	test_helper.ModuleUpgradeTest(t, "lonegunmanb", "terraform-azurerm-subnets", exampleRelativePath, currentRoot, terraform.Options{
		Upgrade: true,
	}, currentMajorVersion)
}
