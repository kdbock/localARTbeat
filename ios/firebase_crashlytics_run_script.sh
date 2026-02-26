# Firebase Crashlytics Build Phase Script
# Add this as a "Run Script" build phase in Xcode (after "Embed Frameworks")

if [[ "${CONFIGURATION}" == "Release" || "${CONFIGURATION}" == "Profile" ]]; then
    echo "Firebase Crashlytics: processing dSYMs for ${CONFIGURATION} build"

    # Workaround for missing App Store symbol warning on Flutter objective_c.framework.
    # Generate a UUID-matching dSYM in the standard build dSYM folder so archive upload includes it.
    OBJECTIVE_C_BIN="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/objective_c.framework/objective_c"
    OBJECTIVE_C_DSYM_BUNDLE="${DWARF_DSYM_FOLDER_PATH}/objective_c.framework.dSYM"

    if [[ -f "${OBJECTIVE_C_BIN}" && -n "${DWARF_DSYM_FOLDER_PATH}" ]]; then
        if [[ ! -d "${OBJECTIVE_C_DSYM_BUNDLE}" ]]; then
            echo "Generating objective_c.framework.dSYM"
            xcrun dsymutil "${OBJECTIVE_C_BIN}" -o "${OBJECTIVE_C_DSYM_BUNDLE}" || true
        fi
    fi

    # Path to Firebase Crashlytics run script
    CRASHLYTICS_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/run"

    if [[ -f "${CRASHLYTICS_SCRIPT}" ]]; then
        echo "Uploading dSYMs via Firebase Crashlytics script"
        "${CRASHLYTICS_SCRIPT}"
        echo "dSYM upload completed"
    else
        echo "Firebase Crashlytics script not found at: ${CRASHLYTICS_SCRIPT}"
        echo "Make sure Firebase/Crashlytics pod is properly installed"
    fi
else
    echo "Skipping Firebase Crashlytics dSYM upload (not a Release/Profile build)"
fi
