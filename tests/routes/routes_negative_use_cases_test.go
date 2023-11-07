package routes

import (
	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
	"path/filepath"
	"strings"
	"testing"
)

// TestRoutesNegativeTemplate Test Routes Charts for Public Inputs.
func TestRoutesNegativeTemplate(t *testing.T) {
	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/routes")

	releaseName := "helm-routes" + strings.ToLower(random.UniqueId())
	namespaceName := "medieval-" + strings.ToLower(random.UniqueId())
	require.NoError(t, err)

	logger.Log(t, "Namespace: %s\n", namespaceName)

	t.Run("no_subdomains_template_test", func(t *testing.T) {
		options := &helm.Options{
			KubectlOptions: k8s.NewKubectlOptions("", "", namespaceName),
		}
		_, err := helm.RenderTemplateE(t, options, helmChartPath, releaseName, []string{})
		require.Error(t, err)

		require.Contains(t, err.Error(), "There should be at least 1 subdomain provided")
	})
}
