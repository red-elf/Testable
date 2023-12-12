#!/bin/bash

if [ -z "$SUBMODULES_HOME" ]; then

  echo "ERROR: SUBMODULES_HOME not available"
  exit 1
fi

echo "Starting the test procedure"

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

if test -e "$RECIPES"; then

  echo "Using recipes from: $RECIPES"

  RUN_SONARQUBE_TESTS() {

    if [ -n "$SONARQUBE_SERVER" ]; then

      SCRIPT_SONAR_SCAN="$SUBMODULES_HOME/Software-Toolkit/Utils/SonarQube/sonar_scan.sh"

      if ! test -e "$SCRIPT_SONAR_SCAN"; then

        echo "ERROR: Scrript not found '$SCRIPT_SONAR_SCAN'"
        exit 1
      fi

      if sh "$SCRIPT_SONAR_SCAN" "$MODULE"; then

        echo "Obtaining the Qulity Gate badge"

        # TODO: Code quality badges
        #
        # http://general-server.local:9102/api/project_badges/measure?project=HelixTrack_Core.1.0.0&metric=alert_status&token=sqb_349b1a2ac1ee21e016f235b4c175b06bcbe7782a
        # Assets/Generated_SonarQube_Measure.svg


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

  BRING_SONARQUBE_UP() {

    if test -e "$RECIPE_SONAR_CUBE"; then

      # shellcheck disable=SC1090
      . "$RECIPE_SONAR_CUBE"

      if [ -n "$SONARQUBE_NAME" ]; then
        
        echo "$SONARQUBE_NAME test starting"

      else
        
        echo "ERROR: SONARQUBE_NAME is not provided"
        exit 1
      fi

      if [ -z "$SONARQUBE_PORT" ]; then
        
        SONARQUBE_PORT="9000"
      fi

      echo "To bind the port: $SONARQUBE_PORT"

      if test -e "$SCRIPT_GET_SONARQUBE_FULL_PATH"; then

        if [ -n "$DB_USER" ]; then

          if [ -z "$DB_PASSWORD" ]; then
        
            echo "ERROR: Password parameter is mandatory when DB user is provided for the test"
            exit 1
          fi

          if [ -n "$ADMIN_PASSWORD" ]; then
        
            if sh "$SCRIPT_GET_SONARQUBE_FULL_PATH" "$SONARQUBE_NAME" "$SONARQUBE_PORT" "$DB_USER" "$DB_PASSWORD" "$ADMIN_PASSWORD"; then

              echo "SonarQube is ready"

            else

              echo "ERROR: SonarQube is not ready (2)"
              exit 1
            fi

          else

            if sh "$SCRIPT_GET_SONARQUBE_FULL_PATH" "$SONARQUBE_NAME" "$SONARQUBE_PORT" "$DB_USER" "$DB_PASSWORD"; then

              echo "SonarQube is ready"

            else

              echo "ERROR: SonarQube is not ready (1)"
              exit 1
            fi
          fi
          
        else

          echo "ERROR: DB user parameter is mandatory"
          exit 1
        fi

      else

        echo "ERROR: Not found '$SCRIPT_GET_SONARQUBE_FULL_PATH'"
        exit 1
      fi
    fi
  }

  SCRIPT_GET_SONARQUBE="get_sonar_qube.sh"
  RECIPE_SONAR_CUBE="$RECIPES/SonarQube/installation_parameters_sonarqube.sh"
  SCRIPT_GET_SONARQUBE_FULL_PATH="$SUBMODULES_HOME/Software-Toolkit/Utils/SonarQube/$SCRIPT_GET_SONARQUBE"

  if [ -n "$SONARQUBE_SERVER" ]; then

    echo "Using external SonarQube instance: $SONARQUBE_SERVER"

  else

    BRING_SONARQUBE_UP
  fi

  RUN_TESTS

else

  echo "ERROR: '$RECIPES' directory does not exist (2)"
  exit 1
fi
