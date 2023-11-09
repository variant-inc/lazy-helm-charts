#!/bin/bash
set -e

url_encoded_ecr_repository=$(echo "$ECR_REPOSITORY" | sed 's/\//\%2F/g')

echo "::debug::ECR_REPOSITORY: $ECR_REPOSITORY"
echo "::debug::URL_ECR_REPOSITORY: $url_encoded_ecr_repository"

# Try fetching the repository policy
response=$(curl -sSfL "https://$LAZY_API_URL/tenants/apps/profiles/production/regions/$AWS_REGION/ecr/repo/$url_encoded_ecr_repository/repo-policy" \
	--header "x-api-key: $LAZY_API_KEY" || echo "error")

echo "::debug::$response"
# if error then create repo
if [ "$response" == "error" ]; then
	echo "Repository $ECR_REPOSITORY was not found"
	echo "Attempting to create a repository with name ${ECR_REPOSITORY}"
	data=$(
		cat <<EOF
{
  "profile": "production",
  "region": "$AWS_REGION",
  "options": {
    "repositoryName": "$ECR_REPOSITORY",
    "imageTagMutability": "MUTABLE"
  }
}
EOF
	)
	response=$(curl -sSfL -X POST \
		"https://$LAZY_API_URL/tenants/apps/profiles/production/regions/$AWS_REGION/ecr/repo" \
		-d "$data" --header "x-api-key: $LAZY_API_KEY" --header "Content-Type: application/json" || echo "error")

	echo "::debug::$response"
	# If repo cannot be created then exit 1
	if [ "$response" == "error" ]; then
		echo "::error::Failed to create the ECR Repository $ECR_REPOSITORY."
		exit 1
	else
		echo "::notice::ECR Repository $ECR_REPOSITORY successfully created"
	fi
	# repo already exists
else
	echo "::notice::ECR Repository $ECR_REPOSITORY already exists"
fi
