// QuotientCompliance
//
// Placeholder for Session 1. Full implementation lands in Session 2:
// - State disclosure library (top 10 + IA first)
// - NMLS helpers
// - ATR/QM decision tree (versioned rule tables consumed by
//   QuotientFinance.calculateQMStatus via rule-version lookup)
// - Disclaimer templates (EN + ES)
//
// Note on `ComplianceRuleVersion`: the type lives in QuotientFinance so the
// finance engine can stamp it on `QMDetermination` without introducing a
// circular dependency (Session 2's Compliance library will import Finance
// for `Loan`, `LoanType`, etc.).

import Foundation

/// Intentionally empty for Session 1; here only so the target compiles.
public enum QuotientCompliance {
    public static let placeholder = "session-2"
}
