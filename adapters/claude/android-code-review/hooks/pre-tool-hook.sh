#!/bin/bash
# pre-tool-hook.sh — PreToolUse hook for android-code-review
#
# Before Claude edits a file in an Android project, injects
# relevant architectural guidelines based on the file's layer.
# Only activates if the project is detected as Android.

set -euo pipefail

# Read tool context from stdin
INPUT=$(cat)

# Detect Android project — check for key Android files in working directory
ANDROID_PROJECT=false
if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] || [ -f "settings.gradle" ] || [ -f "settings.gradle.kts" ]; then
    if [ -f "app/build.gradle" ] || [ -f "app/build.gradle.kts" ] || find . -maxdepth 3 -name "AndroidManifest.xml" -print -quit 2>/dev/null | grep -q .; then
        ANDROID_PROJECT=true
    fi
fi

if [ "$ANDROID_PROJECT" = false ]; then
    exit 0
fi

# Extract the file path being edited
FILE_PATH=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null <<< "$INPUT" || echo "")

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only apply to Kotlin/Java source files
case "$FILE_PATH" in
    *.kt|*.java) ;;
    *) exit 0 ;;
esac

# Detect file layer from path and name
FILE_LOWER=$(echo "$FILE_PATH" | tr '[:upper:]' '[:lower:]')
FILE_NAME=$(basename "$FILE_PATH")

GUIDELINES=""

case "$FILE_LOWER" in
    *viewmodel*|*vm.kt|*vm.java)
        GUIDELINES="**ViewModel rules:**
- No Android framework imports (Context, View, Activity) — use plain Kotlin/Java
- Expose state via StateFlow/LiveData, not mutable public fields
- Use viewModelScope for coroutines
- No direct repository instantiation — inject via constructor"
        ;;
    *fragment*|*activity*)
        GUIDELINES="**UI Controller rules:**
- Observe ViewModel state, don't hold business logic
- Collect flows in lifecycleScope with repeatOnLifecycle(STARTED)
- No network or database calls directly
- Use viewBinding or compose, avoid findViewById
- Be lifecycle-aware: release resources in onDestroyView/onDestroy"
        ;;
    *repository*|*repo.kt|*repo.java)
        GUIDELINES="**Repository rules:**
- Single source of truth pattern — coordinate between remote and local
- Return Flow or suspend functions, not callbacks
- Handle errors and map to domain models
- Use withContext(Dispatchers.IO) for blocking operations
- No Android framework dependencies"
        ;;
    *adapter*|*viewholder*)
        GUIDELINES="**RecyclerView rules:**
- Use DiffUtil for list updates, not notifyDataSetChanged
- No heavy work in onBindViewHolder (no I/O, no inflation)
- Avoid memory leaks: don't hold Activity/Fragment references
- Use ListAdapter for automatic diffing"
        ;;
    *usecase*|*interactor*)
        GUIDELINES="**UseCase/Interactor rules:**
- Single responsibility: one public operator fun invoke()
- No Android dependencies — pure Kotlin/Java
- Inject repositories via constructor
- Handle errors at this layer, return Result or sealed class"
        ;;
    *di/*|*module*|*component*)
        GUIDELINES="**Dependency Injection rules:**
- Scope components correctly (Singleton, ActivityScoped, ViewModelScoped)
- Don't inject Context where it's not needed
- Prefer constructor injection over field injection
- Avoid circular dependencies"
        ;;
    *dao*|*database*|*entity*)
        GUIDELINES="**Room/Database rules:**
- DAOs return Flow for observable queries, suspend for one-shot
- Entities should be data classes with no logic
- Run queries on Dispatchers.IO, never on main thread
- Use @Transaction for multi-table operations"
        ;;
    *service*|*worker*|*broadcast*)
        GUIDELINES="**Background work rules:**
- Use WorkManager for deferrable work, not Service
- Services must handle their own lifecycle correctly
- Don't hold Activity references from background components
- Use foreground service with notification for long-running tasks"
        ;;
    *)
        # Generic Android guidelines for any source file
        GUIDELINES="**Android general rules:**
- No blocking calls on the main thread
- Avoid memory leaks: don't hold Context/Activity references in long-lived objects
- Use structured concurrency (coroutineScope, viewModelScope)
- No hardcoded secrets or API keys"
        ;;
esac

if [ -n "$GUIDELINES" ]; then
    cat << EOF
## Android Architecture Guidelines (Auto-injected)

Editing: \`$FILE_NAME\`

$GUIDELINES
EOF
fi
