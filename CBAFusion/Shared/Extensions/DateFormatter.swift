//
//  DateFormatter.swift
//  CBAFusion
//
//  Created by Cole M on 1/10/22.
//

import Foundation
extension DateFormatter {    
    func getFormattedDateFromDate(currentFormat: String, newFormat: String, date: Date) -> String {
         let dateFormatter = self
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current

        dateFormatter.dateFormat = currentFormat

        let oldDate = date

        let converToNewFormat = self
        converToNewFormat.dateFormat = newFormat

        return converToNewFormat.string(from: oldDate)
     }
}
