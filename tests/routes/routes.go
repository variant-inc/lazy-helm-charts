package routes

type Routes struct {
	Global     Global      `json:"global"`
	Subdomains []Subdomain `json:"subdomains"`
	Public     Public      `json:"public,omitempty"`
}

type Global struct {
	Domain      string            `json:"domain,omitempty"`
	Issuer      string            `json:"issuer,omitempty"`
	Environment string            `json:"environment,omitempty"`
	Upstream    Upstream          `json:"upstream"`
	Revision    string            `json:"revision,omitempty"`
	Tags        map[string]string `json:"tags,omitempty"`
}

type Upstream struct {
	Name string `json:"name,omitempty"`
	Port int64  `json:"port"`
}

type Public struct {
	Enabled      bool     `json:"enabled,omitempty"`
	DisableAuth  bool     `json:"disableAuth,omitempty"`
	PrivatePaths []string `json:"privatePaths,omitempty"`
}

type Subdomain struct {
	App     string `json:"app,omitempty"`
	Product string `json:"product,omitempty"`
	Type    string `json:"type,omitempty"`
}
