#!/usr/bin/env bash
# Creates the remaining Platito issues, with labels and weekly milestones.
# Skips any issue whose title already exists (open or closed), so it is safe to re-run.
# Requirements: GitHub CLI (gh) installed and logged in with `gh auth login`.
# Run from inside your platito repo folder (Git Bash on Windows works).
set -e

echo "Creating labels..."
gh label create "setup"        --color "0E8A16" --description "Project setup"             --force
gh label create "api"          --color "1D76DB" --description "USDA API work"             --force
gh label create "recipes"      --color "5319E7" --description "Recipe data and logic"     --force
gh label create "ui"           --color "FBCA04" --description "Screens and layouts"       --force
gh label create "crud"         --color "D93F0B" --description "Create/read/update/delete" --force
gh label create "quality"      --color "006B75" --description "Code quality and testing"  --force
gh label create "release"      --color "B60205" --description "Release preparation"       --force
gh label create "docs"         --color "0075CA" --description "Documentation"             --force
gh label create "nice-to-have" --color "C5DEF5" --description "Only if there is time"     --force

echo "Creating milestones..."
for m in "Week 1" "Week 2" "Week 3" "Week 4"; do
  gh api "repos/{owner}/{repo}/milestones" -f title="$m" >/dev/null 2>&1 || echo "Milestone '$m' already exists, skipping"
done

# Fetch titles of ALL existing issues (open and closed), lowercase, to avoid duplicates.
existing=$(gh issue list --state all --limit 500 --json title --jq '.[].title' | tr '[:upper:]' '[:lower:]')

new_issue () {
  # $1 title, $2 body, $3 labels, $4 milestone
  local lower
  lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  if echo "$existing" | grep -qxF "$lower"; then
    echo "SKIPPED (already exists): $1"
    return
  fi
  gh issue create --title "$1" --body "$2" --label "$3" --milestone "$4" --assignee "@me"
}

echo "Creating issues..."
new_issue "Create NutritionCalculator with unit tests" \
  "Scale per-100g nutrients by grams, total each recipe, and compute protein per peso. Guard against a cost of 0. Add unit tests." \
  "recipes,quality" "Week 2"

new_issue "Build Home screen" \
  "Category tiles (Budget Meals, High Protein, Bulking, Cutting) and popular recipe cards." \
  "ui" "Week 2"

new_issue "Build Recipe List screen with sorting" \
  "Receives the selected category, shows recipe cards, and sorts by protein, cost, or protein per peso." \
  "ui,recipes" "Week 2"

new_issue "Build Recipe Detail screen with USDA nutrition" \
  "Receives the selected Recipe and fetches each ingredient's nutrition from USDA, with loading and error states." \
  "ui,api" "Week 2"

new_issue "Set up local storage for user recipes" \
  "Use Hive or shared_preferences so user-created recipes are kept after the app restarts." \
  "crud" "Week 2"

new_issue "Build My Recipes screen with edit and delete" \
  "List user recipes. Edit opens the Add/Edit form, delete asks for confirmation. Show an empty state when there are no recipes." \
  "crud,ui" "Week 3"

new_issue "Add Favorites" \
  "Heart button on recipe cards and Recipe Detail, plus a Favorites tab in My Recipes." \
  "crud,nice-to-have" "Week 3"

new_issue "Add editable ingredient prices" \
  "Add PriceProvider so users can update ingredient prices; recipe costs recalculate automatically." \
  "crud,nice-to-have" "Week 3"

new_issue "Add Filipino ingredient name mapping" \
  "Map local names to English search terms, e.g. itlog -> egg, manok -> chicken." \
  "api,nice-to-have" "Week 3"

new_issue "Add Meal Plan and Goals" \
  "Place recipes on days of the week and compare daily totals with protein and calorie targets." \
  "nice-to-have" "Week 3"

new_issue "Create reusable widgets" \
  "Extract RecipeCard, MacroBar, CostBadge, and EmptyState, each used on 2+ screens." \
  "quality,ui" "Week 3"

new_issue "Fix flutter analyze and dart format issues" \
  "Reach zero analyzer warnings and format all files with dart format." \
  "quality" "Week 3"

new_issue "Document a DevTools debugging case" \
  "Record a real bug: screenshot, how DevTools or the stack trace found it, and the fix. Add it to the README." \
  "quality,docs" "Week 3"

new_issue "Add app icon, splash screen, and app name" \
  "Use flutter_launcher_icons and flutter_native_splash, and set the app label to Platito." \
  "release" "Week 3"

new_issue "Build debug and release APKs" \
  "Build both APKs and document the build steps and the differences between them." \
  "release" "Week 3"

new_issue "Write documentation paper" \
  "All 9 required sections. Technical Implementation must reference real files, classes, and endpoints." \
  "docs" "Week 4"

echo "Done! Check the Issues tab on GitHub."
