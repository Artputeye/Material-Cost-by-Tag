# Material Cost by Tag

SketchUp Extension for creating material schedules and calculating model costs by Tag.

## Features

- Load Tags from the active model.
- Measure Group and ComponentInstance quantities by Tag as `m`, `m2`, and `m3`.
- Calculate total weight and cost using Quantity, Factor, Weight/Unit, Unit Cost, Waste%, and Tax%.
- Save data to the model Attribute Dictionary and back it up to `data/prices.json`.
- Import and export material schedules as CSV files.
- Sort, delete, and drag to reorder table rows.

## Installation

1. Open SketchUp.
2. Go to `Window > Extension Manager`.
3. Select `Install Extension...`.
4. Select `MaterialCostByTag.rbz`.
5. Open `Material Cost` from the Plugins menu or Toolbar.

## Usage

1. Select a Tag from the dropdown.
2. Add a row and enter Description, Factor, Weight/Unit, Unit Cost, Waste%, and Tax%.
3. Select `m`, `m2`, or `m3` to use the measured quantity from the model.
4. Review the row totals and grand totals in the table.
5. Click `SAVE` to store the data.
6. Use the Import/Export CSV buttons to transfer data between files.

The cost formula for each row is:

```text
Cost = Quantity x Factor x Unit Cost
       x (1 + Waste% / 100)
       x (1 + Tax% / 100)
```

## Project Structure

```text
MaterialCostByTag.rb        # Registers the SketchUp Extension
src/main.rb                 # Loads modules and creates the menu/Toolbar
src/core/calculator.rb      # Unit conversion and cost calculations
src/core/tag_measurer.rb    # Measures length, area, and volume by Tag
src/core/model_collector.rb # Reads Tags and selects objects by Tag
src/core/price_store.rb     # Stores data in the model and prices.json
src/core/csv_handler.rb     # CSV import/export
ui/dialog_manager.rb        # Creates the HtmlDialog and callbacks
ui/index.html               # UI structure
ui/app.js                   # UI table and calculations
ui/styles.css               # UI styling
build.ps1                   # Builds the .rbz package
```

## Building the RBZ Package

Use Windows PowerShell and run the command from the project directory:

```powershell
.\build.ps1
```

The script creates or replaces `MaterialCostByTag.rbz` and includes only the Loader, `data`, `icons`, `src`, and `ui` files.

## Notes

- The Ruby code must run inside SketchUp because it uses the SketchUp Ruby API and `UI::HtmlDialog`.
- Measurements are taken from top-level Groups and ComponentInstances in the model.
- `MaterialCostByTag.rbz` is the existing package; `build.rb` is currently empty.
