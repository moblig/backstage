#!/bin/bash

banner() {
  # Colors for output
  RED='\033[0;31m'
  NC='\033[0m' 

  echo -e "${RED}   ____             __   ____                 ${NC}"
  echo -e "${RED}  / __ )____ ______/ /__/ __ \____ ___________${NC}"
  echo -e "${RED} / __  / __ \`/ ___/ //_/ /_/ / __ \`/ ___/ ___/${NC}"
  echo -e "${RED}/ /_/ / /_/ / /__/ ,< / ____/ /_/ (__  |__  ) ${NC}"
  echo -e "${RED}/_____/\__,_/\___/_/|_/_/    \__,_/____/____/  ${NC}"
  echo -e "${RED}                                               ${NC}"
}

check_unauthenticated_api() {
  response=$(curl -s -o /dev/null -w "%{http_code}" "$1/api/catalog/entities")
  if [[ "$response" -eq 200 ]]; then
    content=$(curl -s "$1/api/catalog/entities")
    if echo "$content" | jq -e . >/dev/null 2>&1; then
      echo -e "${GREEN}Unauthenticated API found${NC}"
      return 0
    fi
  fi
  return 1
}

check_guest_auth() {
  echo "Testing for guest auth"
  response=$(curl -s -o /dev/null -w "%{http_code}" "$1/api/auth/guest/refresh")
  if [[ "$response" -eq 200 ]]; then
    content=$(curl -s "$1/api/auth/guest/refresh")
    token=$(echo "$content" | jq -r .backstageIdentity.token)
    if [[ -n "$token" && "$token" != "null" ]]; then
      echo "Token found, appending to fuzzer"
      export TOKEN="$token"
      return 0
    fi
  fi
  echo -e "${RED}Instance not vulnerable${NC}"
  return 1
}

fuzz_endpoints() {
  endpoints=(
    "/api/catalog/entity-facets?facet=metadata.tags"
    "/api/catalog/entity-facets?facet=kind"
    "/api/catalog/entities/by-name/user/default/guest"
    "/api/search/query?term=m"
    "/api/search/query?term=admin&pageLimit=100"
    "/api/catalog/entities/by-query"
    "/api/proxy/onboarding/backend/api/v1/list-requests"
    "/api/catalog/entities/by-name/api/default/user-data/ancestry"
    "/api/proxy/gitlabci/projects/"
    "/api/devtools/info"
    "/api/announcements/announcements?max=10&page=1"
    "/api/auth/guest/refresh"
    "/api/devtools/config"
    "/api/scaffolder/v2/tasks"
    "/api/scaffolder/v2/actions"
    "/api/catalog/entities"
    "/api/catalog/entity-facets"
    "/api/catalog/entity"
    "/api/catalog/entities/by-name/component/default/my-service"
    "/api/catalog/refresh"
    "/api/catalog/analyze-location"
    "/api/catalog/locations"
    "/api/cicd-statistics/builds"
    "/api/techdocs/static/docs"
    "/api/techdocs/discovery"
    "/api/techdocs/sync/:namespace/:kind/:name"
    "/api/techdocs/metadata/:namespace/:kind/:name"
    "/api/techdocs/pages/:namespace/:kind/:name/*"
    "/api/kubernetes/clusters"
    "/api/kubernetes/namespaces"
    "/api/kubernetes/pods"
    "/api/kubernetes/services"
    "/api/kubernetes/nodes"
    "/api/kubernetes/deployments"
    "/api/kubernetes/replicasets"
    "/api/kubernetes/configmaps"
    "/api/kubernetes/secrets"
    "/api/kubernetes/events"
    "/api/proxy/jira/issues"
    "/api/proxy/github/repos"
    "/api/proxy/gitlab/projects"
    "/api/proxy/sonarqube/measures"
    "/api/proxy/prometheus/query"
    "/api/proxy/grafana/dashboards"
    "/api/proxy/grafana/api/api/dashboards/uid/NTHiM7fVk"
    "/api/proxy/jenkins/jobs"
    "/api/proxy/aws-cost/api"
    "/api/azure-devops/repos"
    "/api/azure-devops/pipelines"
    "/api/proxy/sentry/events"
    "/api/proxy/cloudbuild/builds"
    "/api/proxy/artifactory/repos"
    "/api/proxy/nexus/assets"
    "/api/proxy/todolist/tasks"
    "/api/proxy/aws-cf/resources"
    "/api/proxy/bitbucket/pipelines"
    "/api/cost-insights/projects"
    "/api/cost-insights/products"
    "/api/cost-insights/reports"
    "/api/lighthouse/audit"
    "/api/techdocs/sync/default/component/all"
    "/api/lighthouse/reports"
    "/api/proxy/pagerduty/services"
    "/api/proxy/pagerduty/incidents"
    "/api/proxy/pagerduty/alerts"
    "/api/proxy/vault/secrets"
    "/api/proxy/circleci/projects"
    "/api/proxy/elastic/search"
    "/api/proxy/gitlabci/pipelines"
    "/api/proxy/gitlabci/runners"
    "/api/notifications/read"
    "/api/notifications/unread"
    "/api/rollbar/items"
    "/api/proxy/todo/comments"
    "/api/sentry/events"
    "/api/catalog-metadata"
    "/api/proxy/argo-cd/applications"
    "/api/proxy/firebase/functions"
    "/api/proxy/datadog/monitors"
    "/api/proxy/slack/conversations"
    "/api/proxy/slack/messages"
    "/api/proxy/okta/users"
    "/api/proxy/okta/groups"
    "/api/proxy/pingdom/checks"
    "/api/proxy/newrelic/alerts"
    "/api/proxy/terraform-cloud/runs"
    "/api/proxy/azure/pipelines"
    "/api/proxy/azure/repos"
    "/api/proxy/google/gke/clusters"
    "/api/proxy/google/iam/roles"
    "/api/proxy/cloudflare/zones"
    "/api/proxy/fastly/services"
    "/api/proxy/dynatrace/metrics"
    "/api/proxy/splunk/search"
    "/api/proxy/launchdarkly/flags"
    "/api/proxy/databricks/jobs"
    "/api/proxy/travis-ci/repositories"
    "/api/proxy/kafka/clusters"
    "/api/proxy/kibana/dashboard"
    "/api/proxy/harbor/projects"
    "/api/proxy/snyk/projects"
    "/api/proxy/sumo-logic/logs"
    "/api/proxy/appdynamics/applications"
    "/api/proxy/consul/services"
    "/api/proxy/aws/lambda/functions"
    "/api/proxy/github/repos/{owner}/{repo}/actions"
    "/api/proxy/quay/api/v1/repository"
    "/api/proxy/victorops/incidents"
    "/api/proxy/opsgenie/v2/schedules"
    "/api/proxy/grafana/api/search"
    "/api/proxy/grafana/api/api/search/"
    "/api/proxy/grafana/api/api/user"
  )

  # First check /api/catalog/entities for emails
  if [[ -n "$TOKEN" ]]; then
    content=$(curl -s -H "Authorization: Bearer $TOKEN" "$1/api/catalog/entities")
  else
    content=$(curl -s "$1/api/catalog/entities")
  fi
  
  if echo "$content" | jq -e . >/dev/null 2>&1; then
    emails=$(echo "$content" | grep -Eo "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" | sort -u)
    if [[ -n "$emails" ]]; then
      echo -e "${PURPLE}The following email addresses were found:\n$emails${NC}"
    fi
  fi

  # proceed with testing all endpoints
  for endpoint in "${endpoints[@]}"; do
    if [[ -n "$TOKEN" ]]; then
      response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$1$endpoint")
      if [[ "$response" -eq 200 ]]; then
        GREEN='\033[0;32m'
        NC='\033[0m'
        echo -e "${GREEN}$endpoint - 200 OK${NC}"
      fi
    else
      response=$(curl -s -o /dev/null -w "%{http_code}" "$1$endpoint")
      if [[ "$response" -eq 200 ]]; then
        GREEN='\033[0;32m'
        NC='\033[0m'
        echo -e "$endpoint - ${GREEN}200 OK${NC}"
      fi
    fi
  done
}

main() {
  banner
  
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  PURPLE='\033[0;35m'
  NC='\033[0m'

  while getopts "u:l:" opt; do
    case ${opt} in
      u )
        urls=($OPTARG)
        ;;
      l )
        if [[ -f "$OPTARG" ]]; then
          mapfile -t urls < "$OPTARG"
        else
          echo "File $OPTARG not found"
          exit 1
        fi
        ;;
      \? )
        echo "Usage: $0 [-u url] [-l url_list_file]"
        exit 1
        ;;
    esac
  done

  if [[ ${#urls[@]} -eq 0 ]]; then
    echo "No URLs provided"
    echo "Usage: $0 [-u url] [-l url_list_file]"
    exit 1
  fi

  for url in "${urls[@]}"; do
    echo -e "\n${GREEN}Testing URL: $url ${NC}"
    
    url_with_protocol="$url"
    if ! [[ "$url" =~ ^http?:// ]]; then
      url_with_protocol="https://$url"
    fi

    # Reset TOKEN for each new URL
    unset TOKEN

    # check for unauthenticated API
    if check_unauthenticated_api "$url_with_protocol"; then
      echo -e "${GREEN}Starting endpoint fuzzing with unauthenticated access...${NC}"
      fuzz_endpoints "$url_with_protocol"
    else
      # Try guest auth if unauthenticated check fails
      echo -e "${RED}No unauthenticated access found, trying guest auth...${NC}"
      if check_guest_auth "$url_with_protocol"; then
        echo -e "${GREEN}Starting endpoint fuzzing with guest auth token...${NC}"
        fuzz_endpoints "$url_with_protocol"
      else
        echo -e "${RED}No authentication methods available, running fuzzer without authentication...${NC}"
        fuzz_endpoints "$url_with_protocol"
      fi
    fi

    echo -e "${GREEN}----------------------------------------${NC}"
  done
}

main "$@"