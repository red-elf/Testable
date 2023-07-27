#!/bin/bash

RECIPES="Recipes"
RECIPE_SONAR_CUBE="$RECIPES/sonar_qube_parameters.sh"

HERE="$(dirname -- "$0")"
SCRIPT_GET_SONARQUBE="get_sonar_qube.sh"

SCRIPT_GET_SONARQUBE_FULL_PATH="$HERE/../Toolkit/Utils/SonarQube/$SCRIPT_GET_SONARQUBE"

if test -e "$RECIPES"; then

  if test -e "$RECIPE_SONAR_CUBE"; then

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

        if [ -n "$ADMIN_USER" ]; then
      
          if [ -z "$ADMIN_PASSWORD" ]; then
      
            echo "ERROR: Password parameter is mandatory when ADMIN user is provided for the test"
            exit 1
          fi

          if sh "$SCRIPT_GET_SONARQUBE_FULL_PATH" "$SONARQUBE_NAME" "$SONARQUBE_PORT" "$DB_USER" "$DB_PASSWORD" \
            "$ADMIN_USER" "$ADMIN_PASSWORD"; then

            echo "SonarQube is ready"

          else

            echo "ERROR: SonarQube is not ready (3)"
            exit 1
          fi

        else

          if sh "$SCRIPT_GET_SONARQUBE_FULL_PATH" "$SONARQUBE_NAME" "$SONARQUBE_PORT" "$DB_USER" "$DB_PASSWORD"; then

            echo "SonarQube is ready"

          else

            echo "ERROR: SonarQube is not ready (2)"
            exit 1
          fi
        fi
      else

        if sh "$SCRIPT_GET_SONARQUBE_FULL_PATH" "$SONARQUBE_NAME" "$SONARQUBE_PORT"; then

          echo "SonarQube is ready"

        else

          echo "ERROR: SonarQube is not ready"
          exit 1
        fi
      
      fi

    else

      echo "ERROR: Not found '$SCRIPT_GET_SONARQUBE_FULL_PATH'"
      exit 1
    fi

    echo "ERROR: Sonar Cube support to be implemented"
    exit 1
  fi

else

  echo "ERROR: '$RECIPES' installation directory does not exist"
  exit 1
fi
