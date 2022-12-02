package unit

import (
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/mitchellh/mapstructure"
	"github.com/stretchr/testify/assert"
)

type subnet struct {
	name                                          string
	id                                            string
	Address_prefixes                              []string    `mapstructure:"address_prefixes"`
	Nat_gateway                                   *natGw      `mapstructure:"nat_gateway, omitempty"`
	Network_security_group                        *nsg        `mapstructure:"network_security_group,omitempty"`
	Private_endpoint_network_policies_enabled     bool        `mapstructure:"private_endpoint_network_policies_enabled"`
	Private_link_service_network_policies_enabled bool        `mapstructure:"private_link_service_network_policies_enabled"`
	Route_table                                   *routeTable `mapstructure:"route_table,omitempty"`
	Service_endpoints                             []string    `mapstructure:"service_endpoints,omitempty"`
	Service_endpoint_policy_ids                   []string    `mapstructure:"service_endpoint_policy_ids,omitempty"`
	Delegations                                   []struct {
		Name               string `mapstructure:"name"`
		Service_delegation struct {
			Name    string   `mapstructure:"name,omitempty"`
			Actions []string `mapstructure:"actions,omitempty"`
		} `mapstructure:"service_delegation,omitempty"`
	} `mapstructure:"delegations,omitempty"`
}

func (s subnet) toMap() (m map[string]interface{}) {
	_ = mapstructure.Decode(&s, &m)
	return
}

type nsg struct {
	Id string `mapstructure:"id"`
}

type routeTable struct {
	Id string `mapstructure:"id"`
}

type natGw struct {
	Id string `mapstructure:"id"`
}

var (
	baseSubnet = subnet{
		name:             "baseSubnet",
		id:               "baseSubnet_id",
		Address_prefixes: []string{"10.0.0.0/24"},
	}
	subnetWithRt = subnet{
		name:             "subnetWithRt",
		id:               "subnetWithRt_id",
		Address_prefixes: []string{"10.0.1.0/24"},
		Route_table:      &routeTable{Id: "rt_id"},
	}
	subnetWithNsg = subnet{
		name:                   "subnetWithNsg",
		id:                     "subnetWithNsg_id",
		Address_prefixes:       []string{"10.0.2.0/24"},
		Network_security_group: &nsg{Id: "nsg_id"},
	}
	subnetWithNatGw = subnet{
		name:             "subnetWithNatGw",
		id:               "subnetWithNatGw_id",
		Address_prefixes: []string{"10.0.3.0/24"},
		Nat_gateway:      &natGw{Id: "nat_gw_id"},
	}
)

func TestSubnetWithRouteTableShouldCreateRouteTableAssociation(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "unit-test-fixture", terraform.Options{
		Upgrade: false,
		Vars:    mockVariables(),
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		rt := output["azurerm_subnet_route_table_association"].(map[string]interface{})
		assert.Equal(t, 1, len(rt))
		rtSubnet, ok := rt[subnetWithRt.name]
		assert.True(t, ok)
		assert.NotNil(t, rtSubnet)
		association := rtSubnet.(map[string]interface{})
		outputs := association["outputs"].(map[string]interface{})
		rtId, ok := outputs["route_table_id"]
		assert.True(t, ok)
		assert.Equal(t, subnetWithRt.Route_table.Id, rtId)
		subnetId, ok := outputs["subnet_id"]
		assert.True(t, ok)
		assert.Equal(t, subnetWithRt.id, subnetId)
	})
}

func TestSubnetWithNsgShouldCreateNsgAssociation(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "unit-test-fixture", terraform.Options{
		Upgrade: false,
		Vars:    mockVariables(),
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		rt := output["azurerm_subnet_network_security_group_association"].(map[string]interface{})
		assert.Equal(t, 1, len(rt))
		nsgSubnet, ok := rt[subnetWithNsg.name]
		assert.True(t, ok)
		assert.NotNil(t, nsgSubnet)
		association := nsgSubnet.(map[string]interface{})
		outputs := association["outputs"].(map[string]interface{})
		nsgId, ok := outputs["network_security_group_id"]
		assert.True(t, ok)
		assert.Equal(t, subnetWithNsg.Network_security_group.Id, nsgId)
		subnetId, ok := outputs["subnet_id"]
		assert.True(t, ok)
		assert.Equal(t, subnetWithNsg.id, subnetId)
	})
}

func TestSubnetWithNatGwShouldCreateNatGwAssociation(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "unit-test-fixture", terraform.Options{
		Upgrade: false,
		Vars:    mockVariables(),
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		rt := output["azurerm_subnet_nat_gateway_association"].(map[string]interface{})
		assert.Equal(t, 1, len(rt))
		natGwSubnet, ok := rt[subnetWithNatGw.name]
		assert.True(t, ok)
		assert.NotNil(t, natGwSubnet)
		association := natGwSubnet.(map[string]interface{})
		outputs := association["outputs"].(map[string]interface{})
		natGwId, ok := outputs["nat_gateway_id"]
		assert.True(t, ok)
		assert.Equal(t, subnetWithNatGw.Nat_gateway.Id, natGwId)
		subnetId, ok := outputs["subnet_id"]
		assert.True(t, ok)
		assert.Equal(t, subnetWithNatGw.id, subnetId)
	})
}

func dummyVariables() map[string]interface{} {
	return map[string]interface{}{
		"resource_group_name":           "dummyRg",
		"virtual_network_address_space": []string{"10.0.0.0/16"},
		"virtual_network_location":      "eastus",
		"virtual_network_name":          "dummyVnet",
	}
}

func mockVariables() map[string]interface{} {
	vars := dummyVariables()
	vars["azurerm_subnets"] = map[string]string{
		baseSubnet.name:      baseSubnet.id,
		subnetWithRt.name:    subnetWithRt.id,
		subnetWithNsg.name:   subnetWithNsg.id,
		subnetWithNatGw.name: subnetWithNatGw.id,
	}
	vars["subnets"] = map[string]interface{}{
		baseSubnet.name:      baseSubnet.toMap(),
		subnetWithRt.name:    subnetWithRt.toMap(),
		subnetWithNsg.name:   subnetWithNsg.toMap(),
		subnetWithNatGw.name: subnetWithNatGw.toMap(),
	}
	return vars
}
