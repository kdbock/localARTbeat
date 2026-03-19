#!/bin/bash

PROJECT_PATH="/Users/kristybock/artbeat/ios/Runner.xcodeproj/project.pbxproj"
SCRIPT_PATH="/Users/kristybock/artbeat/ios/firebase_crashlytics_run_script.sh"

if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: project.pbxproj not found at $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: firebase_crashlytics_run_script.sh not found at $SCRIPT_PATH"
    exit 1
fi

# Create backup
cp "$PROJECT_PATH" "$PROJECT_PATH.backup"
echo "✅ Created backup: $PROJECT_PATH.backup"

# Use Ruby to modify the pbxproj file (more reliable than sed)
ruby << 'RUBY_SCRIPT'
require 'xcodeproj'

project_path = "/Users/kristybock/artbeat/ios/Runner.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Get the main target (Runner)
target = project.targets.find { |t| t.name == "Runner" }

if target.nil?
  puts "ERROR: Runner target not found"
  exit 1
end

# Create the Crashlytics build phase
build_phase = target.new_shell_script_build_phase("Firebase Crashlytics Upload")
build_phase.shell_path = "/bin/sh"
build_phase.shell_script = "\"${SRCROOT}/firebase_crashlytics_run_script.sh\""

# Move it after "Embed Frameworks" - this is typically the right position
embed_phase = target.build_phases.find { |p| p.display_name == "Embed Frameworks" }
if embed_phase
  target.build_phases.move(build_phase, target.build_phases.index(embed_phase) + 1)
  puts "SUCCESS: Positioned after 'Embed Frameworks'"
else
  puts "WARNING: 'Embed Frameworks' phase not found, using default position"
end

# Save the project
project.save
puts "SUCCESS: Firebase Crashlytics build phase added successfully"
RUBY_SCRIPT

exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "❌ Failed to add build phase. Restoring backup..."
    mv "$PROJECT_PATH.backup" "$PROJECT_PATH"
    exit 1
fi

echo ""
echo "🎉 Build phase configured! Next steps:"
echo "1. Open Runner.xcworkspace in Xcode"
echo "2. Build and archive for Release"
echo "3. dSYMs will be automatically uploaded to Firebase Crashlytics"
