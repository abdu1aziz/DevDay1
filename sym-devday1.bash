#!/bin/bash

####################################################################################################
#
# Setup Your Mac via swiftDialog
# Author: Abdul Aziz ( @abdu1aziz )
#
####################################################################################################


####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Kandji Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.8.0-Kandji"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
scriptLog="${4:-"/var/log/org.nm.devday1.log"}"                                 # Parameter 4: Script Log Location [ /var/log/org.nm.devday1.log ] (i.e., Your organization's default location for client-side logs)
debugMode="${5:-"verbose"}"                                                     # Parameter 5: Debug Mode [ false (default) | true | verbose ]
welcomeDialog="${6:-"false"}"                                                   # Parameter 6: Welcome dialog [ false (default for developers) | userInput | video ]
requiredMinimumBuild="${7:-"disabled"}"                                         # Parameter 7: Required Minimum Build [ disabled (default) | 22D ] (i.e., Your organization's required minimum build of macOS to allow users to proceed; use "22D" for macOS 13.2.x)
outdatedOsAction="${8:-"/System/Library/CoreServices/Software Update.app"}"     # Parameter 8: Outdated OS Action [ /System/Library/CoreServices/Software Update.app (default) | kandji://library ] (i.e., Kandji Self Service library for operating system upgrades)
symConfiguration="${9:-"Complete"}"                                             # Parameter 9: Default Configuration [ Complete (default) | Required | Recommended ]
# Completion action is hardcoded to Restart for developer setup



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Operating System, currently logged-in user and default Exit Code
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

osVersion=$( sw_vers -productVersion )
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
reconOptions=""
exitCode="0"



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {
    if [[ "${loggedInUser}" != "loginwindow" ]]; then
        launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON with awk (thanks, @thisisadamj!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value() {
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Setup Your Mac dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateSetupYourMac() {
    echo "$1" >> "$setupYourMacCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Welcome dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateWelcome() {
    echo "$1" >> "$welcomeCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Internet Speed (Simple Test)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getInternetSpeed() {
    # Test URL (10MB file from a fast CDN)
    testURL="http://speedtest.ftp.otenet.gr/files/test10Mb.db"
    
    # Download and measure speed
    downloadSpeed=$(curl -o /dev/null -w '%{speed_download}' -s --max-time 5 "$testURL" 2>/dev/null)
    
    if [[ -n "$downloadSpeed" ]] && [[ "$downloadSpeed" != "0.000" ]]; then
        # Convert bytes/sec to Mbps
        downloadMbps=$(echo "scale=1; $downloadSpeed / 131072" | bc 2>/dev/null || echo "0")
        echo "${downloadMbps} Mbps"
    else
        echo "N/A"
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Build System Information for Infobox
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function buildSystemInfo() {
    # Get internet speed (runs in background to avoid blocking)
    local internetSpeed=$(getInternetSpeed)
    
    # Build the infobox content
    local systemInfo="**System Information**  \n\n"
    systemInfo+="**Serial Number:** ${serialNumber}  \n"
    systemInfo+="**User Name:** ${loggedInUserFullname}  \n"
    systemInfo+="**User ID:** ${loggedInUser}  \n"
    systemInfo+="**macOS:** ${macOSproductVersion} (${macOSbuildVersion})  \n"
    systemInfo+="**Download Speed:** ${internetSpeed}  \n"
    
    echo "$systemInfo"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finalise (i.e., display 'Complete!' message)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function finalise() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    if [[ "${kandjiLibraryItemFailure}" == "failed" ]]; then
        updateScriptLog "FINALISE: Failures detected; exit code: ${exitCode}"
        dialogUpdateSetupYourMac "title: Sorry, something went wrong"
        dialogUpdateSetupYourMac "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateSetupYourMac "progresstext: Failures detected. Please try again."
        dialogUpdateSetupYourMac "button1text: Close"
        dialogUpdateSetupYourMac "button1: enable"
        dialogUpdateSetupYourMac "progress: reset"
    else
        updateScriptLog "FINALISE: All library items installed successfully"
        dialogUpdateSetupYourMac "title: Setup Your Mac is complete!"
        dialogUpdateSetupYourMac "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        dialogUpdateSetupYourMac "progresstext: Your Mac is ready!"
        dialogUpdateSetupYourMac "progress: complete"
        dialogUpdateSetupYourMac "button1text: Restart"
        dialogUpdateSetupYourMac "button1: enable"
    fi

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Policy Execution (Trigger Kandji Library Item)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function confirmPolicyExecution() {

    libraryItem="${1}"
    validation="${2}"

    # Pre-validation: Check if item already exists locally to skip execution
    if [[ "${validation}" == "None" ]]; then
        updateScriptLog "CONFIRM POLICY EXECUTION: Validation is 'None', proceeding with execution"
    elif [[ "${validation}" =~ ^/ ]]; then
        # Absolute path validation - check if already exists
        if [[ -d "${validation}" ]] || [[ -f "${validation}" ]]; then
            updateScriptLog "CONFIRM POLICY EXECUTION: ${validation} already exists locally, skipping Kandji execution"
            alreadyInstalled="true"
            return 0
        else
            updateScriptLog "CONFIRM POLICY EXECUTION: ${validation} not found, proceeding with installation"
        fi
    fi

    updateScriptLog "CONFIRM POLICY EXECUTION: Triggering Kandji library item: ${libraryItem}"
    alreadyInstalled="false"
    
    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]]; then
        updateScriptLog "CONFIRM POLICY EXECUTION: DEBUG MODE - Would execute: ${kandjiBinary} library --item \"${libraryItem}\" -F"
        sleep 2
    else
        if [[ -n "${libraryItem}" ]]; then
            updateScriptLog "CONFIRM POLICY EXECUTION: Executing: ${kandjiBinary} library --item \"${libraryItem}\" -F"
            "${kandjiBinary}" library --item "${libraryItem}" -F
            sleep 10
        else
            updateScriptLog "CONFIRM POLICY EXECUTION: Empty trigger, skipping execution"
        fi
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Policy Result
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validatePolicyResult() {

    libraryItem="${1}"
    validation="${2}"

    updateScriptLog "VALIDATE POLICY RESULT: Validating ${libraryItem} with method: ${validation}"

    # Check if already installed (skipped execution)
    if [[ "${alreadyInstalled}" == "true" ]]; then
        updateScriptLog "VALIDATE POLICY RESULT: Item was already installed, marking as success"
        dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Already Installed"
        return 0
    fi

    case "${validation}" in

        "None" )
            updateScriptLog "VALIDATE POLICY RESULT: Validation: None; skipping validation"
            if [[ -z "${libraryItem}" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Skipped"
            else
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Completed"
            fi
            ;;

        /* )
            # Absolute path validation
            if [[ -d "${validation}" ]]; then
                # It's a directory (like an .app bundle)
                if [[ -d "${validation}" ]]; then
                    updateScriptLog "VALIDATE POLICY RESULT: ${validation} exists (directory)"
                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
                else
                    updateScriptLog "VALIDATE POLICY RESULT: ${validation} NOT found (directory)"
                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                    kandjiLibraryItemFailure="failed"
                    exitCode="1"
                fi
            elif [[ -f "${validation}" ]]; then
                # It's a file (like a binary)
                updateScriptLog "VALIDATE POLICY RESULT: ${validation} exists (file)"
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
            else
                updateScriptLog "VALIDATE POLICY RESULT: ${validation} NOT found"
                dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                kandjiLibraryItemFailure="failed"
                exitCode="1"
            fi
            ;;

        * )
            updateScriptLog "VALIDATE POLICY RESULT: Unknown validation type: ${validation}"
            dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Error"
            ;;

    esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Setup Your Mac (${scriptVersion})\n# By: Abdul Aziz & Temo Zamduio\n###\n"
updateScriptLog "Pre-flight Check: Initiating..."



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "Pre-flight Check: This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Verify Kandji MDM is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "/usr/local/bin/kandji" ]]; then
    echo "ERROR: Kandji MDM is not installed on this device."
    echo "ERROR: Cannot proceed with Setup Your Mac script."
    echo "ERROR: Please enroll this device with Kandji before running this script."
    updateScriptLog "Pre-flight Check: Kandji binary not found at /usr/local/bin/kandji; exiting."
    exit 1
else
    kandjiVersion=$( /usr/local/bin/kandji version 2>/dev/null || echo "unknown" )
    updateScriptLog "Pre-flight Check: Kandji MDM detected (version: ${kandjiVersion})"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Setup Assistant has completed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

while pgrep -q -x "Setup Assistant"; do
    updateScriptLog "Pre-flight Check: Setup Assistant is still running; pausing for 2 seconds"
    sleep 2
done

updateScriptLog "Pre-flight Check: Setup Assistant is no longer running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
    updateScriptLog "Pre-flight Check: Finder & Dock are NOT running; pausing for 1 second"
    sleep 1
done

updateScriptLog "Pre-flight Check: Finder & Dock are running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Operating System Version and Build
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${requiredMinimumBuild}" == "disabled" ]]; then

    updateScriptLog "Pre-flight Check: 'requiredMinimumBuild' has been set to ${requiredMinimumBuild}; skipping OS validation."
    updateScriptLog "Pre-flight Check: macOS ${osVersion} (${osBuild}) installed"

else

    # Since swiftDialog requires at least macOS 11 Big Sur, first confirm the major OS version
    # shellcheck disable=SC2086 # purposely use single quotes with osascript
    if [[ "${osMajorVersion}" -ge 11 ]] ; then

        updateScriptLog "Pre-flight Check: macOS ${osMajorVersion} installed; checking build version ..."

        # Confirm the Mac is running `requiredMinimumBuild` (or later)
        if [[ "${osBuild}" > "${requiredMinimumBuild}" ]]; then

            updateScriptLog "Pre-flight Check: macOS ${osVersion} (${osBuild}) installed; proceeding ..."

        # When the current `osBuild` is older than `requiredMinimumBuild`; exit with error
        else
            updateScriptLog "Pre-flight Check: The installed operating system, macOS ${osVersion} (${osBuild}), needs to be updated to Build ${requiredMinimumBuild}; exiting with error."
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Setup Your Mac: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
            updateScriptLog "Pre-flight Check: Executing /usr/bin/open '${outdatedOsAction}' …"
            su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
            exit 1

        fi

    # The Mac is running an operating system older than macOS 11 Big Sur; exit with error
    else

        updateScriptLog "Pre-flight Check: swiftDialog requires at least macOS 11 Big Sur and this Mac is running ${osVersion} (${osBuild}), exiting with error."
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Setup Your Mac: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
        updateScriptLog "Pre-flight Check: Executing /usr/bin/open '${outdatedOsAction}' …"
        su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
        exit 1

    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure computer does not go to sleep during SYM (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Pre-flight Check: Caffeinating this script (PID: $$)"
caffeinate -dimsu -w $$ &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
    updateScriptLog "Pre-flight Check: No user logged-in; exiting."
    exit 1
else
    loggedInUserFullname=$( id -F "${loggedInUser}" )
    loggedInUserFirstname=$( echo "$loggedInUserFullname" | cut -d " " -f 1 )
    loggedInUserID=$( id -u "${loggedInUser}" )
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Keep Kandji agent enabled (required for library installs)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Pre-flight Check: Kandji agent remains enabled to allow 'kandji library --item' installs"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "Pre-flight Check: # # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"
    
    # Maximum retry attempts
    maxAttempts=3
    attempt=0
    installSuccess=false

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        updateScriptLog "Pre-flight Check: Dialog not found. Installing..."

        while [[ $attempt -lt $maxAttempts ]] && [[ "$installSuccess" == "false" ]]; do
            
            attempt=$((attempt + 1))
            updateScriptLog "Pre-flight Check: Installation attempt $attempt of $maxAttempts"

            # Get the URL of the latest PKG From the Dialog GitHub repo
            dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

            if [[ -z "$dialogURL" ]]; then
                updateScriptLog "Pre-flight Check: Failed to get download URL from GitHub API"
                sleep 2
                continue
            fi

            # Create temporary working directory
            workDirectory=$( /usr/bin/basename "$0" )
            tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

            # Download the installer package
            updateScriptLog "Pre-flight Check: Downloading from: $dialogURL"
            /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

            # Verify the download exists and has size
            if [[ ! -f "$tempDirectory/Dialog.pkg" ]] || [[ ! -s "$tempDirectory/Dialog.pkg" ]]; then
                updateScriptLog "Pre-flight Check: Download failed or file is empty"
                /bin/rm -Rf "$tempDirectory"
                sleep 2
                continue
            fi

            # Verify the download
            teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

            # Install the package if Team ID validates
            if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

                updateScriptLog "Pre-flight Check: Team ID verified: $teamID"
                /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
                sleep 2
                
                # Verify installation succeeded
                if [[ -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
                    dialogVersion=$( /usr/local/bin/dialog --version )
                    updateScriptLog "Pre-flight Check: swiftDialog version ${dialogVersion} installed successfully"
                    installSuccess=true
                else
                    updateScriptLog "Pre-flight Check: Installation completed but Dialog.app not found"
                fi

            else

                updateScriptLog "Pre-flight Check: Team ID verification failed. Expected: $expectedDialogTeamID, Got: $teamID"
                
            fi

            # Remove the temporary working directory
            /bin/rm -Rf "$tempDirectory"

        done

        # If all attempts failed, show error and quit
        if [[ "$installSuccess" == "false" ]]; then
            updateScriptLog "Pre-flight Check: Failed to install swiftDialog after $maxAttempts attempts"
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Failed to install swiftDialog after multiple attempts\r• Team ID verification failed or download corrupted\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
            exitCode="1"
            exit 1
        fi

    else

        updateScriptLog "Pre-flight Check: swiftDialog version $(dialog --version) found; proceeding..."

    fi

}

if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
    dialogCheck
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Pre-flight Check: Complete"



####################################################################################################
# Dialog Variables
#
# infobox-related variables
####################################################################################################

macOSproductVersion="$( sw_vers -productVersion )"
macOSbuildVersion="$( sw_vers -buildVersion )"
serialNumber=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
dialogVersion=$( /usr/local/bin/dialog --version )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reflect Debug Mode in `infotext` (i.e., bottom, left-hand corner of each dialog)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${debugMode} in
    "true"      ) scriptVersion="DEBUG MODE | Dialog: v${dialogVersion} • Setup Your Mac: v${scriptVersion}" ;;
    "verbose"   ) scriptVersion="VERBOSE DEBUG MODE | Dialog: v${dialogVersion} • Setup Your Mac: v${scriptVersion}" ;;
esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog path, Command Files, Kandji binary, log files and currently logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
dialogBinary="/usr/local/bin/dialog"
welcomeCommandFile=$( mktemp /var/tmp/dialogWelcome.XXX )
setupYourMacCommandFile=$( mktemp /var/tmp/dialogSetupYourMac.XXX )
kandjiBinary="/usr/local/bin/kandji"
forceQuitFlag="/var/tmp/sym-forcequit"

# Clear any previous force-quit flag
rm -f "${forceQuitFlag}"

# Set proper permissions on command files so logged-in user can read them
chmod 644 "${welcomeCommandFile}"
chmod 644 "${setupYourMacCommandFile}"



####################################################################################################
# Setup Your Mac dialog
# "Setup Your Mac" dialog Title, Message, Overlay Icon and Icon
####################################################################################################

title="Setting up ${loggedInUserFirstname}'s Mac"
message="Please wait while the following apps are installed …"
bannerImage="https://img.freepik.com/free-photo/yellow-watercolor-paper_95678-446.jpg"
bannerText="Setting up ${loggedInUserFirstname}'s Mac"
helpmessage="If you need assistance, please contact the Global Service Department:  \n- **Telephone:** +1 (801) 555-1212  \n- **Email:** support@domain.org  \n- **Knowledge Base Article:** KB0057050  \n\n**Computer Information:** \n\n- **Operating System:**  ${macOSproductVersion} ($macOSbuildVersion)  \n- **Serial Number:** ${serialNumber}  \n- **Dialog:** ${dialogVersion}  \n- **Started:** ${timestamp}"
infobox="Analyzing input …" # Customize at "Update Setup Your Mac's infobox"
selfServiceBrandingImage="/Applications/Kandji Self Service.app/Contents/Resources/AppIcon.icns"
if [[ ! -f "${selfServiceBrandingImage}" ]]; then
    overlayicon="https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/a4/ae/ce/a4aeced8-22d1-c111-624e-9c19f2ed2e5c/AppIcon-0-1x_U007emarketing-0-8-0-85-220-0.png/200x200ia-75.webp"
else
    overlayicon="${selfServiceBrandingImage}"
fi

# Set initial icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
    icon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
else
    icon="SF=desktopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogSetupYourMacCMD="$dialogBinary \
--bannerimage \"$bannerImage\" \
--bannertext \"$bannerText\" \
--title \"$title\" \
--message \"$message\" \
--helpmessage \"$helpmessage\" \
--icon \"$icon\" \
--infobox \"${infobox}\" \
--progress \
--progresstext \"Initializing configuration …\" \
--button1text \"Wait\" \
--button1disabled \
--button2text \"Force Quit\" \
--button2action \"touch ${forceQuitFlag}\" \
--infotext \"$scriptVersion\" \
--titlefont 'shadow=true, size=40' \
--messagefont 'size=14' \
--height '780' \
--position 'centre' \
--ontop \
--overlayicon \"$overlayicon\" \
--quitkey k \
--commandfile \"$setupYourMacCommandFile\" "

# Line 767: --blurscreen \

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# shellcheck disable=SC1112 # use literal slanted single quotes for typographic reasons
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Icon prefix URL (can use Kandji icons or custom URLs)
setupYourMacPolicyArrayIconPrefixUrl="https://ics.services.jamfcloud.com/icon/hash_"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Developer Configuration - Single policyJSON (no case statement needed)
# shellcheck disable=SC1112 # use literal slanted single quotes for typographic reasons
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function policyJSONConfiguration() {

    updateScriptLog "PolicyJSON Configuration: Developer Setup"

    policyJSON='
    {
        "steps": [
            {
                "listitem": "Rosetta",
                "icon": "8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                "trigger_list": [
                    {
                        "trigger": "ROSETTA-LIBRARY-ITEM-ID",
                        "validation": "/Library/Apple/usr/libexec/oah"
                    }
                ]
            },
            {
                "listitem": "Computer Inventory",
                "icon": "90958d0e1f8f8287a86a1198d21cded84eeea44886df2b3357d909fe2e6f1296",
                "progresstext": "Your Macs inventory will be updated with Kandji.",
                "trigger_list": [
                    {
                        "trigger": "",
                        "validation": "None"
                    }
                ]
            }
        ]
    }
    '

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    else
        updateScriptLog "The '$process' process isn't running."
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Completion Action (i.e., Wait, Sleep, Logout, Restart or Shutdown)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function completionAction() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
        # If Debug Mode is enabled, display simple dialog and exit without restarting
        runAsUser osascript -e 'display dialog "Setup Your Mac is operating in Debug Mode.\r\rMac will NOT restart automatically.\r\r" with title "Setup Your Mac: Debug Mode" buttons {"Close"} with icon note'
        exitCode="0"
    else
        # Always restart after completion (developer setup)
        updateScriptLog "Restart: User clicked Restart button"
        killProcess "Kandji Self Service"
        updateScriptLog "Restart: Mac will restart in 5 seconds"
        sleep 5 && shutdown -r now &
    fi

    exit "${exitCode}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @abdu1aziz)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    updateScriptLog "QUIT SCRIPT: Exiting …"

    # Stop `caffeinate` process
    updateScriptLog "QUIT SCRIPT: De-caffeinate …"
    killProcess "caffeinate"

    # Remove welcomeCommandFile
    if [[ -e ${welcomeCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${welcomeCommandFile} …"
        rm "${welcomeCommandFile}"
    fi

    # Remove setupYourMacCommandFile
    if [[ -e ${setupYourMacCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${setupYourMacCommandFile} …"
        rm "${setupYourMacCommandFile}"
    fi

    # Remove force-quit flag
    if [[ -e ${forceQuitFlag} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${forceQuitFlag} …"
        rm "${forceQuitFlag}"
    fi

    # Remove any default dialog file
    if [[ -e /var/tmp/dialog.log ]]; then
        updateScriptLog "QUIT SCRIPT: Removing default dialog file …"
        rm /var/tmp/dialog.log
    fi

    # Check for user clicking "Quit" at Welcome dialog
    if [[ "${welcomeReturnCode}" == "2" ]]; then
        exitCode="1"
        exit "${exitCode}"
    else
        updateScriptLog "QUIT SCRIPT: Executing Restart completion action …"
        completionAction
    fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Debug Mode Logging Notification
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
    updateScriptLog "\n\n###\n# ${scriptVersion}\n###\n"
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# If Debug Mode is enabled, replace `blurscreen` with `movable`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
    welcomeJSON=${welcomeJSON//blurscreen/moveable}
    dialogSetupYourMacCMD=${dialogSetupYourMacCMD//blurscreen/moveable}
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Auto-populate variables for developer mode (when welcomeDialog is false)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${welcomeDialog}" == "false" ]]; then
    updateScriptLog "AUTO-POPULATE: Automatically setting user information for developer setup"
    
    # Get hostname and use it for both computer name and asset tag
    hostName=$( scutil --get ComputerName )
    computerName="${hostName}"
    assetTag="${hostName}"
    
    # Get logged-in username
    userName="${loggedInUser}"
    
    # Department can be left empty or set a default
    department="Developer"
    
    updateScriptLog "AUTO-POPULATE: Computer Name: ${computerName}"
    updateScriptLog "AUTO-POPULATE: User Name: ${userName}"
    updateScriptLog "AUTO-POPULATE: Asset Tag: ${assetTag}"
    updateScriptLog "AUTO-POPULATE: Configuration: ${symConfiguration}"
    updateScriptLog "AUTO-POPULATE: Department: ${department}"
    
    # Select policyJSON based on configuration
    policyJSONConfiguration
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Build list of items for Setup Your Mac dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

policy_array_length=$(get_json_value "${policyJSON}" "steps.length")
for (( i=0; i<policy_array_length; i++ )); do
    listitem=$(get_json_value "${policyJSON}" "steps[$i].listitem")
    icon=$(get_json_value "${policyJSON}" "steps[$i].icon")
    if [[ -n "$icon" ]]; then
        dialogSetupYourMacCMD+="--listitem \"${listitem},icon=${setupYourMacPolicyArrayIconPrefixUrl}${icon}\" "
    else
        dialogSetupYourMacCMD+="--listitem \"${listitem}\" "
    fi
done

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Setup Your Mac dialog (Developer Mode - No Welcome Dialog)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "DEVELOPER MODE: Launching Setup Your Mac dialog immediately"

eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
dialogSetupYourMacProcessID=$!
until pgrep -q -x "Dialog"; do
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
    updateScriptLog "DEVELOPER MODE: Waiting to display 'Setup Your Mac' dialog; pausing"
    sleep 0.5
done
updateScriptLog "DEVELOPER MODE: 'Setup Your Mac' dialog displayed; ensure it's the front-most app"
runAsUser osascript -e 'tell application "Dialog" to activate'

# Quit script if user presses quitkey (k) in Dialog
(
    wait "$dialogSetupYourMacProcessID"
    dialogReturnCode=$?
    if [[ "$dialogReturnCode" == "2" ]]; then
        updateScriptLog "QUITKEY: User pressed 'k' to quit; exiting script"
        welcomeReturnCode="2"
        quitScript
    fi
) &

# Force-quit watcher (button2)
(
    while [[ ! -f "${forceQuitFlag}" ]]; do
        sleep 0.5
    done
    updateScriptLog "FORCE QUIT: User pressed Force Quit; exiting script"
    welcomeReturnCode="2"
    quitScript
) &

# Update infobox with system information
updateScriptLog "DEVELOPER MODE: Fetching system information for infobox..."
systemInfoBox=$(buildSystemInfo)
updateScriptLog "DEVELOPER MODE: Updating infobox display..."
dialogUpdateSetupYourMac "infobox: ${systemInfoBox}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Iterate through policyJSON to construct the list for swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

# Initialize SECONDS
SECONDS="0"

# Determine the number of steps in the policyJSON
policy_array_length=$(get_json_value "${policyJSON}" "steps.length")
updateScriptLog "SETUP YOUR MAC DIALOG: ${policy_array_length} items to install"

# Set progress increment value based on the number of steps
progressIncrementValue=$(( 100 / policy_array_length ))
updateScriptLog "SETUP YOUR MAC DIALOG: Progress increment value: ${progressIncrementValue}"

# Loop through each step in the policyJSON
for (( i=0; i<policy_array_length; i++ )); do

    # Creating initial variables
    listitem=$(get_json_value "${policyJSON}" "steps[$i].listitem")
    icon=$(get_json_value "${policyJSON}" "steps[$i].icon")
    progresstext=$(get_json_value "${policyJSON}" "steps[$i].progresstext")
    trigger_list_length=$(get_json_value "${policyJSON}" "steps[$i].trigger_list.length")

    # If there's a value in the variable, update running swiftDialog
    if [[ -n "$listitem" ]]; then
        updateScriptLog "\n\n# # #\n# SETUP YOUR MAC DIALOG: policyJSON > listitem: ${listitem}\n# # #\n"
        dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Installing …, "
    fi
    if [[ -n "$icon" ]]; then dialogUpdateSetupYourMac "icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon}"; fi
    if [[ -n "$progresstext" ]]; then dialogUpdateSetupYourMac "progresstext: $progresstext"; fi
    if [[ -n "$trigger_list_length" ]]; then

        for (( j=0; j<trigger_list_length; j++ )); do

            # Setting variables within the trigger_list (now library_item_list for Kandji)
            # Each library item uses Kandji's Audit & Remediation:
            # - Audit checks if already installed (exit 0 = skip, exit 1 = install)
            # - Remediation only runs if audit fails
            libraryItem=$(get_json_value "${policyJSON}" "steps[$i].trigger_list[$j].trigger")
            validation=$(get_json_value "${policyJSON}" "steps[$i].trigger_list[$j].validation")
            case ${validation} in
                "Local" | "Remote" | "KandjiAPI" )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Skipping Library Item Installation due to '${validation}' validation"
                    ;;
                * )
                    confirmPolicyExecution "${libraryItem}" "${validation}"
                    ;;
            esac

        done

    fi

    validatePolicyResult "${libraryItem}" "${validation}"

    # Increment the progress bar
    dialogUpdateSetupYourMac "progress: increment ${progressIncrementValue}"

    # Record duration
    updateScriptLog "SETUP YOUR MAC DIALOG: Elapsed Time: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"

done


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete processing and enable the "Done" button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

finalise
