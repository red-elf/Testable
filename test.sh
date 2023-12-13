#!/bin/bash

HERE=$(pwd)

if [ -z "$SUBMODULES_HOME" ]; then

  echo "ERROR: SUBMODULES_HOME not available"
  exit 1
fi

if [ -n "$1" ]; then

  RECIPES="$1"

else

  echo "ERROR: Path to the recipes directory is mandatory"
  exit 1
fi

if [ -n "$2" ]; then

  MODULE="$2"

else

  MODULE="$RECIPES"
fi

SCRIPT_ENV="$SUBMODULES_HOME/Software-Toolkit/Utils/Sys/environment.sh"
RECIPE_SONAR_CUBE="$RECIPES/SonarQube/installation_parameters_sonarqube.sh"
SCRIPT_GET_JQ="$SUBMODULES_HOME/Software-Toolkit/Utils/Sys/Programs/get_jq.sh"
SCRIPT_GET_SONARQUBE="$SUBMODULES_HOME/Software-Toolkit/Utils/SonarQube/get_sonar_qube.sh"

if ! test -e "$SCRIPT_ENV"; then

    echo "ERROR: Script not found '$SCRIPT_ENV'"
    exit 1
fi

if ! test -e "$SCRIPT_GET_JQ"; then

    echo "ERROR: Script not found '$SCRIPT_GET_JQ'"
    exit 1
fi

# shellcheck disable=SC1090
. "$SCRIPT_ENV"

echo "Starting the test procedure"

if test -e "$RECIPES"; then

  echo "Using recipes from: $RECIPES"

  RUN_SONARQUBE_TESTS() {

    if [ -n "$SONARQUBE_SERVER" ]; then

      SCRIPT_SONAR_SCAN="$SUBMODULES_HOME/Software-Toolkit/Utils/SonarQube/sonar_scan.sh"

      if ! test -e "$SCRIPT_SONAR_SCAN"; then

        echo "ERROR: Scrript not found '$SCRIPT_SONAR_SCAN'"
        exit 1
      fi

      echo "Starting the scan"

      # shellcheck disable=SC1090
      if exec bash -c "$SCRIPT_SONAR_SCAN $MODULE"; then

        if [ -n "$SONARQUBE_TOKEN" ]; then

          echo "Obtaining the Qulity Gate badge"

          SCRIPT_VERSION="$HERE/Version/version.sh"

          if ! test -e "$SCRIPT_VERSION"; then

              echo "ERROR: Version file not found '$SCRIPT_VERSION'"
              exit 1
          fi

          # shellcheck disable=SC1090
          . "$SCRIPT_VERSION"

          if [ -z "$VERSIONABLE_VERSION_PRIMARY" ]; then

              echo "ERROR: 'VERSIONABLE_VERSION_PRIMARY' variable not set"
              exit 1
          fi

          if [ -z "$VERSIONABLE_VERSION_SECONDARY" ]; then

              echo "ERROR: 'VERSIONABLE_VERSION_SECONDARY' variable not set"
              exit 1
          fi

          if [ -z "$VERSIONABLE_VERSION_PATCH" ]; then

              echo "ERROR: 'VERSIONABLE_VERSION_PATCH' variable not set"
              exit 1
          fi

          if [ -z "$VERSIONABLE_NAME_NO_SPACE" ]; then

              echo "ERROR: 'VERSIONABLE_NAME_NO_SPACE' variable not set"
              exit 1
          fi

          SONARQUBE_PROJECT="${VERSIONABLE_NAME_NO_SPACE}_$VERSIONABLE_VERSION_PRIMARY.$VERSIONABLE_VERSION_SECONDARY.$VERSIONABLE_VERSION_PATCH"
          BADGE_TOKEN_OBTAIN_URL="$SONARQUBE_SERVER/api/project_badges/token?project=$SONARQUBE_PROJECT"
          BADGE_TOKEN_JSON=$(curl "$BADGE_TOKEN_OBTAIN_URL")

          if [ "$BADGE_TOKEN_JSON" = "" ] || echo "$BADGE_TOKEN_JSON" | grep "errors\":" >/dev/null 2>&1; then

            echo "ERROR: No badge token has been generated"
              
              if [ ! "$BADGE_TOKEN_JSON" = "" ]; then

                echo "$BADGE_TOKEN_JSON"
              fi
              
              exit 1

          else

            if bash "$SCRIPT_GET_JQ" >/dev/null 2>&1; then
              
              EXTRACTED_TOKEN=$(echo "$BADGE_TOKEN_JSON" | jq -r '.token')

              echo "Badge token: $EXTRACTED_TOKEN"

              BADGE_URL="$SONARQUBE_SERVER/api/project_badges/measure?project=$SONARQUBE_PROJECT&metric=alert_status&token=$EXTRACTED_TOKEN"

              echo "Badge URL: $BADGE_URL"

              # TODO:
              #
              # - Here use the proper token to obtain the badge
              # - Write the code quality badge and re-generated PDF from README file: Assets/Generated_SonarQube_Measure.svg

            else

                echo "ERROR: JQ not available"
                exit 1
            fi
          fi

        else

          echo "ERROR: The 'SONARQUBE_TOKEN' is not defined."
          exit 1
        fi
      fi

    fi
  }

  RUN_CODEBASE_TESTS() {

    echo "ERROR: Codebase tests are not yet implemented"
  }

  RUN_TESTS() {

    RUN_SONARQUBE_TESTS
    RUN_CODEBASE_TESTS
  }

  LOAD_SONARQUBE_RECIPE() {

    echo "Loading the SonarQube recipe: '$RECIPE_SONAR_CUBE'"

    if test -e "$RECIPE_SONAR_CUBE"; then

      # shellcheck disable=SC1090
      . "$RECIPE_SONAR_CUBE"

      if [ -n "$SONARQUBE_NAME" ]; then
        
        echo "SonarQube container: $SONARQUBE_NAME"

      else
        
        echo "ERROR: SONARQUBE_NAME is not provided"
        exit 1
      fi

      echo "Te SonarQube recipe has been loaded: '$RECIPE_SONAR_CUBE'"

    else

      echo "WARNING: Could not found recipe to load: '$RECIPE_SONAR_CUBE'"
    fi
  }

  BRING_SONARQUBE_UP() {

    LOAD_SONARQUBE_RECIPE

    if [ -z "$SONARQUBE_PORT" ]; then
      
      SONARQUBE_PORT="9000"
    fi

    echo "To bind the port: $SONARQUBE_PORT"

    if test -e "$SCRIPT_GET_SONARQUBE"; then

      if [ -n "$DB_USER" ]; then

        if [ -z "$DB_PASSWORD" ]; then
      
          echo "ERROR: Password parameter is mandatory when DB user is provided for the test"
          exit 1
        fi

        ADD_SONARQUBE_SERVER_VARIABLE() {

          if [ -z "$1" ]; then

            echo "ERROR: Hostname parameter is mandatory"
            exit 1
          fi

          if [ -z "$2" ]; then

            echo "ERROR: Port parameter is mandatory"
            exit 1
          fi

          PORT_TO_SET="$2"
          HOST_NAME_TO_SET="$1"
          
          SONARQUBE_SERVER="http://$HOST_NAME_TO_SET:$PORT_TO_SET"
          
          ADD_VARIABLE "SONARQUBE_SERVER" "$SONARQUBE_SERVER"

          export SONARQUBE_SERVER
        }

        if [ -n "$ADMIN_PASSWORD" ]; then
      
          # shellcheck disable=SC1090
          if bash "$SCRIPT_GET_SONARQUBE" "$SONARQUBE_NAME" "$SONARQUBE_PORT" "$DB_USER" "$DB_PASSWORD" "$ADMIN_PASSWORD"; then

            ADD_SONARQUBE_SERVER_VARIABLE "localhost" "$SONARQUBE_PORT"

          else

            echo "ERROR: SonarQube is not ready (1)"
            exit 1
          fi

        else

          # shellcheck disable=SC1090
          if bash "$SCRIPT_GET_SONARQUBE" "$SONARQUBE_NAME" "$SONARQUBE_PORT" "$DB_USER" "$DB_PASSWORD"; then

            ADD_SONARQUBE_SERVER_VARIABLE "localhost" "$SONARQUBE_PORT"

          else

            echo "ERROR: SonarQube is not ready (2)"
            exit 1
          fi
        fi
        
      else

        echo "ERROR: DB user parameter is mandatory"
        exit 1
      fi

    else

      echo "ERROR: Script not found '$SCRIPT_GET_SONARQUBE'"
      exit 1
    fi
  }

  if [ -n "$SONARQUBE_SERVER" ]; then

    if [ "$SONARQUBE_SERVER" = "localhost" ] || [ "$SONARQUBE_SERVER" = "127.0.0.1" ]; then

      LOAD_SONARQUBE_RECIPE

      DOCKER_CONTAINER_PREFIX="sonarqube"
      DOCKER_CONTAINER="$DOCKER_CONTAINER_PREFIX.$SONARQUBE_NAME"

      echo "Checking: $DOCKER_CONTAINER"

      if docker ps -a | grep "$DOCKER_CONTAINER"; then

        echo "Using localhost SonarQube instance"

      else

        BRING_SONARQUBE_UP

      fi

    else

      echo "Using external SonarQube instance: $SONARQUBE_SERVER"
    fi

  else

    BRING_SONARQUBE_UP
  fi

  RUN_TESTS

else

  echo "ERROR: '$RECIPES' directory does not exist (2)"
  exit 1
fi
