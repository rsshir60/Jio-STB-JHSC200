# E2E Test Infra: Jio STB Projectivy Launcher Modernization

## Test Philosophy
- Opaque-box, requirement-driven derived from ORIGINAL_REQUEST.md.
- Verification executed directly against the physical/target STB at `192.168.137.28:5555` via ADB.
- Methodology: Category-Partition + Boundary Value Analysis + Combinatorial + Real-World STB Workload.

## Feature Inventory
| # | Feature | Source | Tier 1 | Tier 2 | Tier 3 |
|---|---------|--------|:------:|:------:|:------:|
| 1 | F1_ACQUIRE_INSTALL | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 2 | F2_HOME_INTEGRATION | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 3 | F3_RAM_OPTIMIZATION | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 4 | F4_DYNAMIC_WALLPAPER | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 5 | F5_VISUAL_STYLING | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 6 | F6_ROW_CATEGORIZATION | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 7 | F7_NAV_AUTOMATION_TEST | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 8 | F8_MEMINFO_VERIFICATION | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 9 | F9_SCREENSHOT_CAPTURE | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |

## Test Architecture
- Test Runner: PowerShell test suite `scripts/run_e2e_tests.ps1` with exit code 0 on complete pass.
- Target IP: `192.168.137.28:5555`
- Test Output: Formatted JUnit/TAP/Console report and validation of screenshot artifact `projectivy_homescreen.png`.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Cold Home Key Interception after app launch | F2, F4, F7, F8 | High |
| 2 | D-Pad Row Traversal between OTT and Tools | F4, F6, F7 | Medium |
| 3 | Memory Stress and Background Stability | F3, F8 | High |
| 4 | Visual Banner and Wallpaper Rendering Integrity | F4, F5, F9 | High |
| 5 | Reboot / Launcher Persistence Resilience | F1, F2, F4 | High |

## Coverage Thresholds
- Tier 1: ≥5 per feature (isolated validation of packages, intents, services, keys, memory)
- Tier 2: ≥5 boundary & corner tests (rapid key inputs, low-memory dumpsys checks, disabled package conflicts)
- Tier 3: Pairwise cross-feature interactions (Home press from OTT app -> returns to categorized Projectivy row)
- Tier 4: ≥5 realistic TV usage scenarios
