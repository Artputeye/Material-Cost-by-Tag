MATERIAL COST BY TAG/
├── data/
│   └── prices.json
├── icons/
│   └── material_cost_icon_32.png
├── src/
│   ├── core/
│   │   ├── calculator.rb
│   │   ├── csv_handler.rb
│   │   ├── model_collector.rb
│   │   ├── price_store.rb
│   │   └── tag_measurer.rb
│   └── main.rb
├── ui/
│   ├── app.js
│   ├── dialog_manager.rb
│   ├── index.html
│   └── styles.css
├── build.ps1
├── build.rb
├── context.md
├── MaterialCostByTag.rb
├── MaterialCostByTag.rbz
├── plan.md
├── README.md
├── Structure.md
└── Temp.txt

Note: `build.rb` is currently empty, while `MaterialCostByTag.rbz` is an existing package file.

File and Module Responsibilities

1. Root Loader and Entry Point
- `MaterialCostByTag.rb`: Loads `sketchup.rb` and `extensions.rb`, then creates and registers a `SketchupExtension` pointing to `src/main.rb`, with its name, creator, version, and description.
- `src/main.rb`: Loads the Core files and `ui/dialog_manager.rb` with `require_relative`, then creates the Material Cost menu/Toolbar command and connects it to `DialogManager.show_dialog`.

2. Core Modules
- `MaterialCostByTag::Calculator` (`src/core/calculator.rb`): Converts quantities from SketchUp internal units (inches) to `m`, `m2`, `m3`, `ft`, `ft2`, `ft3`, or `yd3`, and calculates costs using Factor, Waste%, and Tax%.
- `MaterialCostByTag::TagMeasurer` (`src/core/tag_measurer.rb`): Measures the longest edge, largest Face area, and volume of Groups and ComponentInstances by Tag, returning `m`, `m2`, and `m3` values.
- `MaterialCostByTag::ModelCollector` (`src/core/model_collector.rb`): Reads Tag names from the active model's Layers and selects matching Groups and ComponentInstances for highlighting.
- `MaterialCostByTag::PriceStore` (`src/core/price_store.rb`): Saves and loads price data in the model Attribute Dictionary (`MaterialCostByTag_Data`) and backs it up to `data/prices.json`, sanitizing data before saving.
- `MaterialCostByTag::CsvExporter` and `MaterialCostByTag::CsvImporter` (`src/core/csv_handler.rb`): Export the schedule as CSV and import CSV files to update existing rows or add new rows by matching Tag and Description.

3. UI
- `MaterialCostByTag::DialogManager` (`ui/dialog_manager.rb`): Creates `UI::HtmlDialog`, opens `ui/index.html`, and registers the `get_tags`, `get_all_saved_data`, `get_tag_measurements`, `save_tag_cost_data`, `export_csv_data`, and `import_csv_data` callbacks.
- `ui/index.html`: Defines the web layout, material schedule table, total cost/weight summary, and import/export/save buttons.
- `ui/app.js`: Manages the table, quantity, weight, and cost calculations, totals, data save/import/export, and communication with Ruby through `window.sketchup`.
- `ui/styles.css`: Provides the UI styling.

4. Build and Supporting Files
- `build.ps1`: Compresses `MaterialCostByTag.rb`, `data`, `icons`, `src`, and `ui` into `MaterialCostByTag.rbz`.
- `data/prices.json`: Price data file used as a backup and storage source.
- `icons/material_cost_icon_32.png`: Icon used by the Toolbar command.