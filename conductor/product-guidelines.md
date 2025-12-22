# Product Guidelines - Crossbar

## Brand Voice
*   **Primary Tone:** Direct, Technical, Concise. Avoid fluff ("floreios") and apologies.
*   **Secondary Tone (Public Facing):** Confident and "Revolutionary." Emphasize the "Universal" (Write Once, Run Everywhere) capability.
*   **Key Descriptor:** "Boring and Obvious" regarding code/architecture; "Revolutionary" regarding capability.

## Documentation Style
*   **Language:** Portuguese (pt-BR) is the operational language for agents/internal comms. English is used for code/public docs.
*   **Format:** Markdown with clear headers and code blocks.
*   **Philosophy:** "Pragmatic over Dogmatic." Explain *why* something is done, not just *what*.

## Visual Identity
*   **Icons:** Native integration (System Tray on Desktop, Widgets on Mobile).
*   **Platform Adherence:**
    *   **Linux:** Squircle icons (`icon_linux.png`) to match GNOME/modern DEs.
    *   **macOS/Windows:** Native tray styling.
    *   **Mobile:** Material Design 3 (Android) and Human Interface Guidelines (iOS).

## Operational Rules (from AGENTS.md)
*   **No Assumptions:** Always verify libraries and file contents.
*   **Testing & Quality:** Strict adherence to code quality. Execute `make precommit` (which wraps analysis, tests, and builds) before every commit.
*   **Coverage:** Minimum 60% (excluding generated code).
*   **Commits:** Conventional Commits (`feat`, `fix`, `docs`, etc.). No co-authors.
*   **Architecture:** Adhere strictly to the "Dual-Binary + Monorepo" structure.
