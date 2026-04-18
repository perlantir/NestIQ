// USState.swift
// All 50 states + District of Columbia, as a type-safe enum. USPS two-letter
// codes as raw values keep persistence compact and interoperate with
// contact records / address autocomplete.

import Foundation

public enum USState: String, Sendable, Hashable, Codable, CaseIterable {
    case AL, AK, AZ, AR, CA, CO, CT, DE, FL, GA
    case HI, ID, IL, IN, IA, KS, KY, LA, ME, MD
    case MA, MI, MN, MS, MO, MT, NE, NV, NH, NJ
    case NM, NY, NC, ND, OH, OK, OR, PA, RI, SC
    case SD, TN, TX, UT, VT, VA, WA, WV, WI, WY
    case DC

    /// Full proper-case display name (e.g., `"California"`).
    public var displayName: String {
        switch self {
        case .AL: return "Alabama"
        case .AK: return "Alaska"
        case .AZ: return "Arizona"
        case .AR: return "Arkansas"
        case .CA: return "California"
        case .CO: return "Colorado"
        case .CT: return "Connecticut"
        case .DE: return "Delaware"
        case .FL: return "Florida"
        case .GA: return "Georgia"
        case .HI: return "Hawaii"
        case .ID: return "Idaho"
        case .IL: return "Illinois"
        case .IN: return "Indiana"
        case .IA: return "Iowa"
        case .KS: return "Kansas"
        case .KY: return "Kentucky"
        case .LA: return "Louisiana"
        case .ME: return "Maine"
        case .MD: return "Maryland"
        case .MA: return "Massachusetts"
        case .MI: return "Michigan"
        case .MN: return "Minnesota"
        case .MS: return "Mississippi"
        case .MO: return "Missouri"
        case .MT: return "Montana"
        case .NE: return "Nebraska"
        case .NV: return "Nevada"
        case .NH: return "New Hampshire"
        case .NJ: return "New Jersey"
        case .NM: return "New Mexico"
        case .NY: return "New York"
        case .NC: return "North Carolina"
        case .ND: return "North Dakota"
        case .OH: return "Ohio"
        case .OK: return "Oklahoma"
        case .OR: return "Oregon"
        case .PA: return "Pennsylvania"
        case .RI: return "Rhode Island"
        case .SC: return "South Carolina"
        case .SD: return "South Dakota"
        case .TN: return "Tennessee"
        case .TX: return "Texas"
        case .UT: return "Utah"
        case .VT: return "Vermont"
        case .VA: return "Virginia"
        case .WA: return "Washington"
        case .WV: return "West Virginia"
        case .WI: return "Wisconsin"
        case .WY: return "Wyoming"
        case .DC: return "District of Columbia"
        }
    }
}
