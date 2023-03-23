#!/bin/bash

RECIPES="Recipes"
RECIPE_SONAR_CUBE="$RECIPES/sonar_cube_parameters.sh"

if test -e "$RECIPES"; then

  if test -e "$RECIPE_SONAR_CUBE"; then

    . "$RECIPE_SONAR_CUBE"

    echo "$PARAM_SONARQUBE_NAME test stating"

    echo "ERROR: Sonar Cube support to be implemented"
    exit 1
  fi
else

  echo "ERROR: '$RECIPES' installation directory does not exist"
  exit 1
fi
