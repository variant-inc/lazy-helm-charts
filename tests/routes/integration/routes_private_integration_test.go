//go:build integration

package templates

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/helm"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
	"github.com/variant-inc/lazy-helm-charts/tests/routes"
	"net"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// TestRoutesPrivateIntegration Test Routes Charts for Private Inputs.
func TestRoutesPrivateIntegration(t *testing.T) {
	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../../charts/routes")

	releaseName := "helm-routes-private" + strings.ToLower(random.UniqueId())
	namespaceName := "test-charts-routes-" + strings.ToLower(random.UniqueId())
	require.NoError(t, err)

	// Use default kubectl options to create a new namespace for this test, and then update the namespace for kubectl
	kubectlOptions := k8s.NewKubectlOptions("", "", namespaceName)
	istioSystemKubectlOptions := k8s.NewKubectlOptions("", "", "istio-system")

	logger.Log(t, "Namespace: %s\n", namespaceName)

	defer k8s.DeleteNamespace(t, kubectlOptions, namespaceName)
	k8s.CreateNamespace(t, kubectlOptions, namespaceName)

	values := routes.Routes{
		Global: routes.Global{
			Environment: "dpl",
			Upstream: routes.Upstream{
				Name: "octopusdeploy.octopus.svc.cluster.local",
				Port: 80,
			},
			Issuer: "letsencrypt-staging",
		},
		Subdomains: []routes.Subdomain{
			{
				App:     "foo",
				Product: "bar",
			},
			{
				App:     "honey",
				Product: "bar",
				Type:    "api",
			},
		},
	}

	subdomain1, _ := json.Marshal(values.Subdomains[0])
	subdomain2, _ := json.Marshal(values.Subdomains[1])
	global, _ := json.Marshal(values.Global)

	// Set up the args. For this test, we will set the following input values:
	// - containerImageRepo=nginx
	// - containerImageTag=1.15.8
	options := &helm.Options{
		SetJsonValues: map[string]string{
			"global":       string(global),
			"subdomains.0": string(subdomain1),
			"subdomains.1": string(subdomain2),
		},
		KubectlOptions: kubectlOptions,
		ExtraArgs: map[string][]string{
			"upgrade": {"--install"},
		},
	}

	defer helm.Delete(t, options, releaseName, true)

	helm.Install(t, options, helmChartPath, releaseName)

	k8s.WaitUntilSecretAvailable(t,
		istioSystemKubectlOptions,
		releaseName+"-tls", 30, 5*time.Second)

	crtSecret, _ := k8s.RunKubectlAndGetOutputE(t,
		istioSystemKubectlOptions,
		"get", "secret", releaseName+"-tls", "-o", "json")

	logger.Log(t, crtSecret)
	defer k8s.KubectlDeleteFromString(t, istioSystemKubectlOptions,
		crtSecret)

	endpoints := []string{
		fmt.Sprintf(
			"%s.%s.%s.%s",
			values.Subdomains[0].Product,
			values.Subdomains[0].App,
			values.Global.Environment,
			"usxpress.io",
		),
		fmt.Sprintf(
			"%s.%s.%s.%s.%s",
			values.Subdomains[1].Type,
			values.Subdomains[1].Product,
			values.Subdomains[1].App,
			values.Global.Environment,
			"usxpress.io",
		),
	}

	logger.Log(t, "Wait for 45s...")

	time.Sleep(45 * time.Second)

	for _, host := range endpoints {
		http_helper.HttpGetWithRetryWithCustomValidation(
			t,
			fmt.Sprintf("https://%s", host),
			&tls.Config{
				InsecureSkipVerify: true,
			},
			5,
			10*time.Second,
			func(statusCode int, body string) bool {
				return statusCode == 200
			},
		)

		ips, _ := net.LookupIP(host)
		_, subnet, _ := net.ParseCIDR("10.0.0.0/8")
		for _, ip := range ips {
			if ipv4 := ip.To4(); ipv4 != nil {
				require.True(t, subnet.Contains(ipv4))
			}
		}
	}
}
