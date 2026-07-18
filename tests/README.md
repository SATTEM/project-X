# GUT unit tests

This project pins GUT 9.6.1, which supports Godot 4.6.

The suite covers deterministic core game rules without loading a battle scene:

- character health, block, healing, damage, and buff lifetime;
- player energy, drawing, hand overflow, discard, and reshuffling;
- card creation, deep copies, and card-modifying buffs;
- monster card-selection and energy-allocation strategies;
- battle target validation and front-line protection;
- persistent run-state reset, battle result, deck, and summon-binding rules.

Run all tests from PowerShell:

```powershell
.\tests\run_tests.ps1
```

When Godot is not on `PATH`, provide the executable explicitly:

```powershell
.\tests\run_tests.ps1 -GodotPath "C:\path\to\Godot_v4.6-stable_win64.exe"
```

Each run writes two report artifacts:

- `test-reports/gut-results.xml`: JUnit-compatible structured report;
- `test-reports/gut-console.txt`: readable GUT console output.

The generated reports are intentionally ignored by Git. The test configuration is stored in `.gutconfig.json`, and the same suite can also be run from the GUT panel inside the Godot editor.
