//go:build unit

package templates

import (
	"encoding/json"
	"fmt"
	certmanager "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
	"github.com/variant-inc/lazy-helm-charts/tests/routes"
	istioNetworking "istio.io/client-go/pkg/apis/networking/v1beta1"
	"path/filepath"
	"strings"
	"testing"
)

// TestRoutesPublicDisableAuthTemplate Test Routes Charts for Public Inputs.
func TestRoutesPublicDisableAuthTemplate(t *testing.T) {
	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../../charts/routes")

	releaseName := "helm-routes" + strings.ToLower(random.UniqueId())
	namespaceName := "medieval-" + strings.ToLower(random.UniqueId())
	require.NoError(t, err)

	logger.Log(t, "Namespace: %s\n", namespaceName)

	values := routes.Routes{
		Global: routes.Global{
			Upstream: routes.Upstream{
				Name: "vibin",
				Port: 1234,
			},
		},
		Subdomains: []routes.Subdomain{
			{
				Product: "bar",
			},
		},
		Public: routes.Public{
			Enabled:     true,
			DisableAuth: true,
		},
	}
	subdomain1, _ := json.Marshal(values.Subdomains[0])
	global, _ := json.Marshal(values.Global)
	public, _ := json.Marshal(values.Public)

	// Set up the args. For this test, we will set the following input values:
	// - containerImageRepo=nginx
	// - containerImageTag=1.15.8
	options := &helm.Options{
		SetJsonValues: map[string]string{
			"global":       string(global),
			"subdomains.0": string(subdomain1),
			"public":       string(public),
		},
		KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
	}

	t.Run("virtualservice_private_test", func(t *testing.T) {
		var virtualService istioNetworking.VirtualService
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/private/virtualservice.yaml"}),
			&virtualService,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, releaseName+"-private", virtualService.Name)

		// Verify the gateway name matches the expected supplied name in values.
		require.Equal(t, releaseName+"-private", virtualService.Spec.Gateways[0])

		// Verify length of Hosts in VirtualService is 2.
		require.Equal(t, 1, len(virtualService.Spec.Hosts))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.internal.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			virtualService.Spec.Hosts[0],
		)

		require.NotEqual(t, "Private Paths", virtualService.Spec.Http[0].Name)
		require.Equal(t, "default", virtualService.Spec.Http[0].Name)
		require.Equal(t, values.Global.Upstream.Name, virtualService.Spec.Http[0].Route[0].Destination.Host)
		require.Equal(t, uint32(values.Global.Upstream.Port), virtualService.Spec.Http[0].Route[0].Destination.Port.Number)
		require.Equal(t, int32(3), virtualService.Spec.Http[0].Retries.Attempts)
		require.Equal(t, int32(100000000), virtualService.Spec.Http[0].Retries.PerTryTimeout.GetNanos())
		require.Equal(t, "gateway-error,connect-failure,refused-stream", virtualService.Spec.Http[0].Retries.RetryOn)
	})

	t.Run("gateway_private_test", func(t *testing.T) {
		var gateway istioNetworking.Gateway
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/private/gateway.yaml"}),
			&gateway,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, releaseName+"-private", gateway.Name)

		// Verify the gateway selector type is private.
		require.Equal(t, "private", gateway.Spec.Selector["type"])

		// Verify length of Servers is 2.
		require.Equal(t, 2, len(gateway.Spec.Servers))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.internal.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			gateway.Spec.Servers[0].Hosts[0],
		)
		require.Equal(t,
			fmt.Sprintf(
				"%s.internal.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			gateway.Spec.Servers[1].Hosts[0],
		)

		// Verify certificateName
		require.Equal(t,
			releaseName+"-tls",
			gateway.Spec.Servers[1].Tls.CredentialName,
		)
	})

	t.Run("virtualservice_public_test", func(t *testing.T) {
		var virtualService istioNetworking.VirtualService
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/virtualservice.yaml"}),
			&virtualService,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, releaseName, virtualService.Name)

		// Verify the gateway name matches the expected supplied name in values.
		require.Equal(t, releaseName, virtualService.Spec.Gateways[0])

		// Verify length of Hosts in VirtualService is 2.
		require.Equal(t, 1, len(virtualService.Spec.Hosts))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			virtualService.Spec.Hosts[0],
		)

		require.Equal(t, 2, len(virtualService.Spec.Http))

		require.Equal(t, "Private Paths", virtualService.Spec.Http[0].Name)
		require.Equal(t, 3, len(virtualService.Spec.Http[0].Match))
		require.Equal(
			t,
			fmt.Sprintf(
				"%s.internal.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			virtualService.Spec.Http[0].Redirect.Authority)
		require.Equal(t, uint32(307), virtualService.Spec.Http[0].Redirect.RedirectCode)

		require.Equal(t, "default", virtualService.Spec.Http[1].Name)
		require.Empty(t, virtualService.Spec.Http[1].Match)
		require.Equal(t, values.Global.Upstream.Name, virtualService.Spec.Http[1].Route[0].Destination.Host)
		require.Equal(t, uint32(values.Global.Upstream.Port), virtualService.Spec.Http[1].Route[0].Destination.Port.Number)
		require.Equal(t, int32(3), virtualService.Spec.Http[1].Retries.Attempts)
		require.Equal(t, int32(100000000), virtualService.Spec.Http[1].Retries.PerTryTimeout.GetNanos())
		require.Equal(t, "gateway-error,connect-failure,refused-stream", virtualService.Spec.Http[1].Retries.RetryOn)
	})

	t.Run("gateway_public_test", func(t *testing.T) {
		var gateway istioNetworking.Gateway
		helm.UnmarshalK8SYaml(
			t,
			helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/gateway.yaml"}),
			&gateway,
		)

		// Verify the name matches the expected supplied name in values.
		require.Equal(t, releaseName, gateway.Name)

		// Verify the gateway selector type is private.
		require.Equal(t, "public", gateway.Spec.Selector["type"])

		// Verify length of Servers is 2.
		require.Equal(t, 2, len(gateway.Spec.Servers))

		// Verify the host name matches the expected supplied name in values.

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			gateway.Spec.Servers[0].Hosts[0],
		)
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			gateway.Spec.Servers[1].Hosts[0],
		)

		// Verify certificateName
		require.Equal(t,
			releaseName+"-tls",
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
		require.Equal(t, releaseName, certificate.Name)

		// Verify the namespace is istio-system.
		require.Equal(t, "istio-system", certificate.Namespace)

		// Verify the certificate secret name is correct.
		require.Equal(t, releaseName+"-tls", certificate.Spec.SecretName)

		// Verify length of Servers is 2.
		require.Equal(t, 2, len(certificate.Spec.DNSNames))

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			certificate.Spec.DNSNames[0],
		)

		// Verify the host name matches the expected supplied name in values.
		require.Equal(t,
			fmt.Sprintf(
				"%s.internal.%s",
				values.Subdomains[0].Product,
				"usxpress.io",
			),
			certificate.Spec.DNSNames[1],
		)
	})
}
