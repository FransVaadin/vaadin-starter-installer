#!/usr/bin/env bash
# This script installs any specified starter project automatically



base_starter_flow_osgi_result="Not Tested"
skeleton_starter_flow_cdi_result="Not Tested"
skeleton_starter_flow_spring_result="Not Tested"
base_starter_spring_gradle_result="Not Tested"
base_starter_flow_quarkus_result="Not Tested"
vaadin_flow_karaf_example_result="Not Tested"

setup_result=""


# exit with instructions if not given three args
usage(){
  echo -e "usage: ./vaadin-starter-installer.sh project version branch
  example: ./vaadin-starter-installer.sh skeleton-starter-flow-spring 23.0.1 v23" >&2
  exit 1
}


# check-directory checks if you already have a previous project directory and optionally removes it
check-directory(){

  if [[ -d "$1" ]]; then

    read -p "$1 already exists! Do you want to remove the existing one? y/n " remove

    if [[ "$remove" == "y" ]] || [[ "$remove" == "Y" ]]; then
      rm -rf "$1" || fail "ERROR: Failed to remove $1!"
      return

    elif [[ "$remove" == "n" ]] || [[ "$remove" == "N" ]]; then
      echo "ERROR: Remove or rename the old directory before trying again." 2>/dev/null
      exit 1

    else
      echo "Please enter a valid answer(y/n)!" >&2
      check-directory
    fi
  fi
}


# clone-repo clones a git repo and changes the branch
clone-repo(){

  version="$2"

  git clone https://github.com/vaadin/$1.git || echo "\nERROR: Failed to git clone: vaadin/$1.git Are you sure that "\"$1\"" is the correct project?\n" 2>/dev/null


}

# check and automatically kill the server if successful
check-server-return(){

  sleep "$2"

  grep -q 'HTTP/1.1 200' <(curl --fail -I localhost:$1)
  exit_status=$?

  if [[ "$exitStatus" -eq 0 ]]; then
    kill -2 $(lsof -t -i:$1)
  else
    fail "$3 ERROR: Server did not exit with an HTTP exit code of 200!"
  fi

}

# setup the directory
setup-directory(){

  cd "$1" || fail "ERROR: Failed to cd into $1"

  git checkout "$3" || fail "ERROR: Failed to change branch to $3"

}


# sounds the bell
play-bell(){
  while [[ 1 ]]; do
    echo -ne "\a"
    sleep 1
  done
}

# change the spring port from 8080 to 8081
change-spring-port(){
  sed -i '' -e 's/PORT:8080/PORT:8081/' ./src/main/resources/application.properties
}

# turn off automatic browser launch in development mode
turn-off-spring-browser(){
  sed -i '' -e 's/vaadin.launch-browser=true/vaadin.launch-browser=false/' ./src/main/resources/application.properties
}


# check-server tests for any running server on port 8080 and optionally kills it
check-server(){

  lsof -i:$1 >/dev/null
  exitValue=$?

  if [[ $exitValue -eq 0 ]]; then

    play-bell &
    bell_pid=$!
    read -p "WARNING: You already have a server running on port 8080. This will cause a conflict. Do you want to kill the running server? y/n " answer1
    kill $bell_pid &>/dev/null

  else
    # set setup_result to OK. This is needed when calling the show-result() function
    setup_result="OK"
    return
  fi

  if [[ "$answer1" == "y" ]] || [[ "$answer1" == "Y" ]]; then

      kill $(lsof -t -i:$1) &>/dev/null
      lsof -i:$1 >/dev/null && kill -9 $(lsof -t -i:$1) &>/dev/null
      lsof -i:$1 >/dev/null && fail "ERROR: Failed to kill the running server!"

  elif [[ "$answer1" == "n" ]] || [[ "$answer1" == "N" ]]; then
    fail "ERROR: Stop the running server before you start the script!"

  else
    echo "Please enter a valid answer(y/n)!" >&2
    check-server
  fi

  # set setup_result to OK. This is needed when calling the show-result() function
  setup_result="OK"

}


# if an error occurs, call this function
fail(){

  kill "$3" &>/dev/null

  echo -e "$2 - $1" >&2

  # tests what function failed and sets its status to failed
  case "$2" in
    base-starter-flow-osgi)
    base_starter_flow_osgi_result="Failed";
    ;;
    skeleton-starter-flow-cdi)
    skeleton_starter_flow_cdi_result="Failed";
    ;;
    skeleton-starter-flow-spring)
    skeleton_starter_flow_spring_result="Failed";
    ;;
    base-starter-spring-gradle)
    base_starter_spring_gradle_result="Failed";
    ;;
    base-starter-flow-quarkus)
    base_starter_flow_quarkus_result="Failed";
    ;;
    vaadin-flow-karaf-example)
    vaadin_flow_karaf_example_result="Failed";
    ;;
  esac


  show-results

  exit 1
}


# this function shows the results of the installation of the project(s)
show-results(){

    # this function always gets called at the end when running through all tests or if any test failed
    if [[ "$setup_result" == "OK" ]]; then
      echo -e "\nResults:\n
      base-starter-flow-osgi: ${base_starter_flow_osgi_result}
      skeleton-starter-flow-cdi: ${skeleton_starter_flow_cdi_result}
      skeleton-starter-flow-spring: ${skeleton_starter_flow_spring_result}
      base-starter-spring-gradle: ${base_starter_spring_gradle_result}
      base-starter-flow-quarkus: ${base_starter_flow_quarkus_result}
      vaadin-flow-karaf-example: ${vaadin_flow_karaf_example_result}
      "
    fi

}


mvn-clean-install(){

    mvn clean install >/dev/null && echo "mvn clean install succeeded!" || fail "ERROR: mvn clean install failed!" "$1"

}


base-starter-flow-osgi(){

  mvn-clean-install "$FUNCNAME"

  mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version >/dev/null \
  && echo "mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version succeeded!" \
  || fail "ERROR: mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version failed!" "$FUNCNAME"

  mvn-clean-install "$FUNCNAME"

  base_starter_flow_osgi_result="Successful"

  echo -e "\n--------------------------------------------\n| base-starter-flow-osgi build successful! |\n--------------------------------------------\n"

  return

}

mvn-verify(){

  mvn verify -Pit,production >/dev/null && echo "mvn verify -Pit,production succeeded!" || fail "ERROR: mvn verify -Pit,production failed!" "$1"

}


# cdi server starts on port 8080
skeleton-starter-flow-cdi(){


  #check-wildfly-server

  mvn-verify "$FUNCNAME"

                              #20 for fast computers
  check-server-return "8080" "40" &
  timer_pid=$!

  mvn wildfly:run >/dev/null && echo "mvn wildfly:run succeeded!" || fail "ERROR: mvn wildfly:run failed!" "$timer_pid"


  mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version >/dev/null \
  && echo "mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version succeeded!" \
  || fail "ERROR: mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version failed!" "$FUNCNAME"

  mvn-verify "$FUNCNAME"

  skeleton_starter_flow_cdi_result="Successful"

  echo -e "\n-----------------------------------------------\n| skeleton-starter-flow-cdi build successful! |\n-----------------------------------------------\n"


  return
}


gradlew-boot(){

   # There seems to be no way of stopping the gradlew server gracefully, so we can't test for errors here(since Ctrl-C will trigger an error)
  ./gradlew clean bootRun --args='--server.port=8082' >/dev/null && echo "./gradlew clean bootRun succeeded!" || kill "$2" &>/dev/null

}


base-starter-spring-gradle(){

                              #35 for fast computers
  check-server-return "8082" "50" &
  timer_pid=$!

  gradlew-boot "$FUNCNAME" "$timer_pid"

  perl -pi -e "s/vaadinVersion=.*/vaadinVersion=$version/" gradle.properties || fail "ERROR: Could not edit gradle.properties!" "$FUNCNAME" "$timer_pid"


  # Edit the string and replacement string if they change in the future
  build_gradle_string='mavenCentral\(\)'
  build_gradle_replace="mavenCentral\(\)\n\tmaven { setUrl('https:\/\/maven.vaadin.com\/vaadin-prereleases') }"

  perl -pi -e "s/$build_gradle_string/$build_gradle_replace/" build.gradle || fail "ERROR: Could not edit build.gradle!" "$FUNCNAME"


  # Edit the string and replacement string if they change in the future
  setting_gradle_string='pluginManagement {'
  setting_gradle_replace="pluginManagement {\n  repositories {\n\tmaven { url = 'https:\/\/maven.vaadin.com\/vaadin-prereleases' }\n\tgradlePluginPortal()\n}"

  perl -pi -e "s/$setting_gradle_string/$setting_gradle_replace/" settings.gradle || fail "ERROR: Could not edit settings.gradle!" "$FUNCNAME"

                              #35 for fast computers
  check-server-return "8082" "50" &
  timer_pid=$!

  gradlew-boot "$FUNCNAME" "$timer_pid"

  base_starter_spring_gradle_result="Successful"

  echo -e "\n------------------------------------------------\n| base-starter-spring-gradle build successful! |\n------------------------------------------------\n"

  return

}


mvn-install(){

  mvn install >/dev/null && echo "mvn install succeeded!" || fail "ERROR: mvn install failed!" "$1"

}


remove-node-modules(){

  rm -rf ./main-ui/node_modules >/dev/null && return 0 || return 1

}

vaadin-flow-karaf-example(){


  mvn-install "$FUNCNAME"

  mvn -pl main-ui install -Prun >/dev/null && echo "mvn -pl main-ui install -Prun succeeded!" || fail "ERROR: mvn -pl main-ui install -Prun failed!" "$FUNCNAME"

  mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version >/dev/null \
  && echo "mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version succeeded!" \
  || fail "ERROR: mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version failed!" "$FUNCNAME"

  mvn-install "$FUNCNAME"

  remove-node-modules && mvn install >/dev/null && echo "remove-node-modules && mvn install succeeded!" || fail "ERROR: rm -rf ./main-ui/node_modules && mvn install failed!" "$FUNCNAME"

  mvn -pl main-ui install -Prun >/dev/null && echo "mvn -pl main-ui install -Prun succeeded!" || fail "ERROR: mvn -pl main-ui install -Prun failed!" "$FUNCNAME"


  vaadin_flow_karaf_example_result="Successful"

  echo -e "\n-----------------------------------------------\n| vaadin-flow-karaf-example build successful! |\n-----------------------------------------------\n"

  return

}


mvnw-package-production(){

  ./mvnw package -Pproduction >/dev/null && echo "mvnw package -Pproduction succeeded!" || fail "ERROR: mvnw package -Pproduction failed!" "$1"

}

mvnw-package-it(){

  ./mvnw package -Pit >/dev/null && echo "mvnw package -Pit succeeded!" || fail "ERROR: mvnw package -Pit failed!" "$1"

}


base-starter-flow-quarkus(){

                              #40 for fast computers
  check-server-return "8080" "60" &
  timer_pid=$!

  ./mvnw >/dev/null && echo "./mvnw succeeded!" || fail "ERROR: ./mvnw failed!" "$FUNCNAME" "$timer_pid"

  mvnw-package-production "$FUNCNAME"

  mvnw-package-it "$FUNCNAME"

  mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version >/dev/null \
  && echo "mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version succeeded!" \
  || fail "ERROR: mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version failed!" "$FUNCNAME"

                              #40 for fast computers
  check-server-return "8080" "60" &
  timer_pid=$!

  ./mvnw >/dev/null && echo "mvnw succeeded!" || fail "ERROR: mvnw failed!" "$FUNCNAME" "$timer_pid"

  mvnw-package-production "$FUNCNAME"

  mvnw-package-it "$FUNCNAME"

  base_starter_flow_quarkus_result="Successful"

  echo -e "\n-----------------------------------------------\n| base-starter-flow-quarkus build successful! |\n-----------------------------------------------\n"

  return

}

mvn-package-production(){

  mvn package -Pproduction >/dev/null && echo "mvn package -Pproduction succeeded!" || fail "ERROR: mvn package -Pproduction failed!" "$1"

}

mvn-package-it(){

  mvn package -Pit >/dev/null && echo "mvn package -Pit succeeded!" || fail "ERROR: mvn package -Pit failed!" "$1"

}


skeleton-starter-flow-spring(){

  # Disable automatic browser statrtup in development mode
  turn-off-spring-browser

  change-spring-port

                              #40 for fast computers
  check-server-return "8081" "60" &
  timer_pid=$!

  mvn >/dev/null || fail "ERROR: mvn failed!" "$FUNCNAME" "$timer_pid"

  mvn-package-production "$FUNCNAME"

  mvn-package-it "$FUNCNAME"

  mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version >/dev/null \
  && echo "mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version succeeded!" \
  || fail "ERROR: mvn versions:set-property -Dproperty=vaadin.version -DnewVersion=$version failed!" "$FUNCNAME"

                              #140 for fast computers
  check-server-return "8081" "160" &
  timer_pid=$!

  mvn >/dev/null || fail "mvn failed!" "$FUNCNAME" "$timer_pid"

  rm -rf node_modules >/dev/null || fail "ERROR: rm -rf node_modules failed!" "$FUNCNAME"

                             #60 for fast computers
  check-server-return "8081" "80" &
  timer_pid=$!

  mvn >/dev/null || fail "ERROR: mvn failed!" "$FUNCNAME" "$timer_pid"

  mvn-package-production "$FUNCNAME"

  mvn-package-it "$FUNCNAME"

  skeleton_starter_flow_spring_result="Successful"

  echo -e "\n--------------------------------------------------\n| skeleton-starter-flow-spring build successful! |\n--------------------------------------------------\n"

  return
}


# this function runs all the starter tests
all(){

  check-server "8080"
  check-server "8081"
  check-server "8082"

  check-directory base-starter-flow-osgi "$2" "$3"
  clone-repo base-starter-flow-osgi "$2" "$3"

  check-directory skeleton-starter-flow-cdi "$2" "$3"
  clone-repo skeleton-starter-flow-cdi "$2" "$3"

  check-directory skeleton-starter-flow-spring "$2" "$3"
  clone-repo skeleton-starter-flow-spring "$2" "$3"

  check-directory base-starter-spring-gradle "$2" "$3"
  clone-repo base-starter-spring-gradle "$2" "$3"

  check-directory base-starter-flow-quarkus "$2" "$3"
  clone-repo base-starter-flow-quarkus "$2" "$3"

  check-directory vaadin-flow-karaf-example "$2" "$3"
  clone-repo vaadin-flow-karaf-example "$2" "$3"


  setup-directory base-starter-flow-osgi "$2" "$3"
  base-starter-flow-osgi
  cd ..

  setup-directory skeleton-starter-flow-cdi "$2" "$3"
  skeleton-starter-flow-cdi
  cd ..

  setup-directory skeleton-starter-flow-spring "$2" "$3"
  skeleton-starter-flow-spring
  cd ..

  setup-directory base-starter-spring-gradle "$2" "$3"
  base-starter-spring-gradle
  cd ..

  setup-directory base-starter-flow-quarkus "$2" "$3"
  base-starter-flow-quarkus
  cd ..

  setup-directory vaadin-flow-karaf-example "$2" "$3"
  vaadin-flow-karaf-example


  show-results

  exit 0
}

# main function
main(){

  [[ "$1" == "all" ]] && all "$@"

  # run all the setups
  check-directory "$@"
  clone-repo "$@"
  check-server "8080"
  check-server "8081"
  check-server "8082"
  setup-directory "$@"

  "$1"

  exit 0

}

# call usage if not given three args
[[ "$#" != 3 ]] && usage

main "$@"
