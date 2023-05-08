#!/bin/bash

RECIPES="Recipes"
DIR_VOLUMES="_Volumes"
RECIPE_SONAR_CUBE="$RECIPES/sonar_qube_parameters.sh"

HERE="$(dirname -- "${BASH_SOURCE[0]}")"
SCRIPT_GET_SONAR_QUBE="get_sonar_qube.sh"

DIR_VOLUMES_FULL_PATH="$(pwd)/$DIR_VOLUMES"
SCRIPT_GET_SONAR_QUBE_FULL_PATH="$HERE/../Toolkit/Utils/SonarQube/$SCRIPT_GET_SONAR_QUBE"

if test -e "$RECIPES"; then

  if test -e "$RECIPE_SONAR_CUBE"; then

    . "$RECIPE_SONAR_CUBE"

    if [ -n "$PARAM_SONARQUBE_NAME" ]; then
      
      echo "$PARAM_SONARQUBE_NAME test starting"

    else
      
      echo "ERROR: PARAM_SONARQUBE_NAME is not provided"
      exit 1
    fi

    if [ -z "$PARAM_SONARQUBE_PORT" ]; then
      
      PARAM_SONARQUBE_PORT="9000"
    fi

    echo "To bind the port: $PARAM_SONARQUBE_PORT"

    if test -e "$SCRIPT_GET_SONAR_QUBE_FULL_PATH"; then

      if sh "$SCRIPT_GET_SONAR_QUBE_FULL_PATH" "$PARAM_SONARQUBE_NAME" "$DIR_VOLUMES_FULL_PATH" "$PARAM_SONARQUBE_PORT"; then

        echo "SonarQube is ready"

      else

        echo "ERROR: SonarQube is not ready"
        exit 1
      fi

    else

      echo "ERROR: Not found '$SCRIPT_GET_SONAR_QUBE_FULL_PATH'"
      exit 1
    fi

    echo "ERROR: Sonar Cube support to be implemented"
    exit 1
  fi

else

  echo "ERROR: '$RECIPES' installation directory does not exist"
  exit 1
fi
