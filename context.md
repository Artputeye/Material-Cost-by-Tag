Program Overview

This SketchUp Extension creates material schedules and calculates costs by Tag from a 3D model. It consists of a Ruby backend connected to the SketchUp API and an HTML/CSS/JavaScript frontend running inside `UI::HtmlDialog`.

1. Extension Loading and Dialog Startup
- `MaterialCostByTag.rb` registers the Extension and points it to `src/main.rb`.
- `src/main.rb` loads the Core Modules and `ui/dialog_manager.rb`, then creates the Material Cost command in the Plugins menu and Toolbar.
- `DialogManager` opens `ui/index.html` and connects Ruby callbacks to the JavaScript bridge.

2. Tag Reading and Quantity Measurement
- `ModelCollector.get_all_tags` reads the layer list from the active model, removes duplicates, and sorts the names.
- `TagMeasurer.get_tag_measurements` checks top-level Groups and ComponentInstances with the selected Tag.
- For each object, the system finds the longest edge, largest Face area, and volume, then converts the results to `m`, `m2`, and `m3`.
- `ModelCollector.highlight_tag` can select Groups and ComponentInstances by Tag in the SketchUp Selection, but no current UI callback calls this function.

3. Ruby and UI Communication
- When the UI calls `get_tags`, `get_all_saved_data`, or `get_tag_measurements`, Ruby sends JSON data back using `execute_script()`.
- The UI calls Ruby through `window.sketchup` for `save_tag_cost_data`, `export_csv_data`, and `import_csv_data`.
- Row calculations, total weight, and total cost are handled in `ui/app.js` and update immediately when input values change.

4. Cost and Weight Calculation
- The user enters Quantity, Factor, Weight/Unit, Unit Cost, Waste%, and Tax%.
- Cost formula:
  `Cost = Quantity x Factor x Unit Cost x (1 + Waste% / 100) x (1 + Tax% / 100)`
- Row weight is calculated as `Quantity x Factor x Weight/Unit` and summed as Total Weight (kg).
- The UI supports `m`, `m2`, and `m3`, using the measurement returned for the selected Tag.

5. Data Storage and Transfer
- `PriceStore` sanitizes each item before saving and stores JSON in the model Attribute Dictionary `MaterialCostByTag_Data`.
- If no data is found in the model, the system loads data from `data/prices.json`.
- `CsvExporter` exports the schedule as CSV with a UTF-8 BOM for convenient use with Excel.
- `CsvImporter` matches existing rows by Tag and Description. Matching rows are updated; unmatched rows are added.