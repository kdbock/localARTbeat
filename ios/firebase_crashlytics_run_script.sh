# Firebase Crashlytics Build Phase Script
# Add this as a "Run Script" build phase in Xcode (after "Embed Frameworks")

if [[ "${CONFIGURATION}" == "Release" || "${CONFIGURATION}" == "Profile" ]]; then
    echo "Firebase Crashlytics: processing dSYMs for ${CONFIGURATION} build"

    # Workaround for missing App Store symbol warning on Flutter objective_c.framework.
    # Native Assets frameworks often lack dSYMs in the standard build pipeline.
    # Search for the binary and generate a UUID-matching dSYM in the standard build dSYM folder.
    
    # Try finding it in the bundle first
    OBJECTIVE_C_BIN="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/objective_c.framework/objective_c"
    
    # If not in bundle (or we want the unstripped one), check Native Assets build folder
    # Flutter usually builds these in build/native_assets/ios/
    NATIVE_ASSETS_BIN="${PROJECT_DIR}/../build/native_assets/ios/objective_c.framework/objective_c"
    
    if [[ ! -f "${OBJECTIVE_C_BIN}" && -f "${NATIVE_ASSETS_BIN}" ]]; then
        echo "Found objective_c binary in native assets folder: ${NATIVE_ASSETS_BIN}"
        OBJECTIVE_C_BIN="${NATIVE_ASSETS_BIN}"
    fi

    OBJECTIVE_C_DSYM_BUNDLE="${DWARF_DSYM_FOLDER_PATH}/objective_c.framework.dSYM"

    if [[ -f "${OBJECTIVE_C_BIN}" && -n "${DWARF_DSYM_FOLDER_PATH}" ]]; then
        if [[ ! -d "${OBJECTIVE_C_DSYM_BUNDLE}" ]]; then
            echo "Generating objective_c.framework.dSYM from ${OBJECTIVE_C_BIN}"
            xcrun dsymutil "${OBJECTIVE_C_BIN}" -o "${OBJECTIVE_C_DSYM_BUNDLE}"
            echo "Generated objective_c.framework.dSYM successfully"
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
