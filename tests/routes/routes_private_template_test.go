package routes

import (
	"fmt"
	certmanager "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
	istioNetworking "istio.io/client-go/pkg/apis/networking/v1beta1"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

// TestRoutesPrivateTemplate Test Routes Charts for Private Inputs.
func TestRoutesPrivateTemplate(t *testing.T) {
	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/routes")

	releaseName := "helm-routes" + strings.ToLower(random.UniqueId())
	namespaceName := "medieval-" + strings.ToLower(random.UniqueId())
	require.NoError(t, err)

	logger.Log(t, "Namespace: %s\n", namespaceName)

	// Set up the args. For this test, we will set the following input values:
	// - containerImageRepo=nginx
	// - containerImageTag=1.15.8
	options := &helm.Options{
		SetValues: map[string]string{
			"name":          "test",
			"environment":   "dpl",
			"subdomains.0":  "test",
			"subdomains.1":  "vibin",
			"upstream.name": "vibin",
			"upstream.port": "1234",
		},
		KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
	}

	t.Run("virtualservice_private_test", func(t *testing.T) {
		var virtualService istioNetworking.VirtualService
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/virtualservice.yaml"}),
			&virtualService,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, options.SetValues["name"], virtualService.Name)

		// Verify the gateway name matches the expected supplied name in values.
		require.Equal(t, options.SetValues["name"], virtualService.Spec.Gateways[0])

		// Verify length of Hosts in VirtualService is 2.
		require.Equal(t, 2, len(virtualService.Spec.Hosts))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.0"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			virtualService.Spec.Hosts[0],
		)

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.1"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			virtualService.Spec.Hosts[1],
		)

		require.NotEqual(t, "Private Paths", virtualService.Spec.Http[0].Name)
		require.Equal(t, "default", virtualService.Spec.Http[0].Name)
		portNumber, _ := strconv.Atoi(options.SetValues["upstream.port"])
		require.Equal(t, options.SetValues["upstream.name"], virtualService.Spec.Http[0].Route[0].Destination.Host)
		require.Equal(t, uint32(portNumber), virtualService.Spec.Http[0].Route[0].Destination.Port.Number)
		require.Equal(t, int32(3), virtualService.Spec.Http[0].Retries.Attempts)
		require.Equal(t, int32(100000000), virtualService.Spec.Http[0].Retries.PerTryTimeout.GetNanos())
		require.Equal(t, "gateway-error,connect-failure,refused-stream", virtualService.Spec.Http[0].Retries.RetryOn)
	})

	t.Run("gateway_private_test", func(t *testing.T) {
		var gateway istioNetworking.Gateway
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/gateway.yaml"}),
			&gateway,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, options.SetValues["name"], gateway.Name)

		// Verify the gateway selector type is private.
		require.Equal(t, "private", gateway.Spec.Selector["type"])

		// Verify length of Servers is 2.
		require.Equal(t, 2, len(gateway.Spec.Servers))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.0"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			gateway.Spec.Servers[0].Hosts[0],
		)
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.0"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			gateway.Spec.Servers[1].Hosts[0],
		)

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.1"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			gateway.Spec.Servers[0].Hosts[1],
		)
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.1"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			gateway.Spec.Servers[1].Hosts[1],
		)

		// Verify certificateName
		require.Equal(t,
			options.SetValues["name"]+"-tls",
			gateway.Spec.Servers[1].Tls.CredentialName,
		)
	})

	t.Run("certificate_private_test", func(t *testing.T) {
		var certificate certmanager.Certificate
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/certificate.yaml"}),
			&certificate,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, options.SetValues["name"], certificate.Name)

		// Verify the namespace is istio-system.
		require.Equal(t, "istio-system", certificate.Namespace)

		// Verify the certificate secret name is correct.
		require.Equal(t, options.SetValues["name"]+"-tls", certificate.Spec.SecretName)

		// Verify length of Servers is 2.
		require.Equal(t, 2, len(certificate.Spec.DNSNames))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.0"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			certificate.Spec.DNSNames[0],
		)

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s.%s",
				options.SetValues["subdomains.1"],
				options.SetValues["environment"],
				"usxpress.io",
			),
			certificate.Spec.DNSNames[1],
		)
	})
}
