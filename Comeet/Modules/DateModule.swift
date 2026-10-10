//
//  DateModule.swift
//  Comeet
//
//  Created by Michael Ross on 3/7/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import Foundation

struct RelativeDateStyle: FormatStyle {

  // The formatter will take dates as inputs, and
  // output strings.
  typealias FormatInput = Date
  typealias FormatOutput = String

  // Format the date.
  func format(_ value: Date) -> String {
    let formatter = Self.customFormatStyle(for: value)
    return formatter.format(value)
  }

  // Return an instance of Date.FormatStyle that's different depending
  // on the date passed in.
  private static func customFormatStyle(for date: Date) -> Date.FormatStyle {
    if date.isSameDateAs(date: .now) {
      return Date.FormatStyle(date: .omitted, time: .shortened)
    }
    if date.isInTheLast(numberOfDays: 7) {
      return Date.FormatStyle().weekday()
    }
    if date.isSameYearAs(date: .now) {
      return Date.FormatStyle().day().month()
    }
    return Date.FormatStyle(date: .abbreviated, time: .omitted)
  }
}

// Some convenience functions for checking when dates occur.
extension Date {
  private func isSameAs(date dateToCompareTo: Date, componentsToCompare: Set<Calendar.Component>) -> Bool {
    let dateComponentsForSelf = Calendar.current.dateComponents(componentsToCompare, from: self)
    let dateComponentsForDateToCompareTo = Calendar.current.dateComponents(componentsToCompare, from: dateToCompareTo)
    return dateComponentsForSelf == dateComponentsForDateToCompareTo
  }

  func isSameDateAs(date dateToCompareTo: Date) -> Bool {
    return isSameAs(date: dateToCompareTo, componentsToCompare: [.day, .month, .year])
  }

  func isSameYearAs(date dateToCompareTo: Date) -> Bool {
    return isSameAs(date: dateToCompareTo, componentsToCompare: [.year])
  }

  func isInTheLast(numberOfDays days: Int) -> Bool {
    return self > Calendar.current.date(byAdding: .day, value: (days * -1), to: Date())!
  }
}

extension FormatStyle where Self == RelativeDateStyle {
  static var relative: RelativeDateStyle {
    return RelativeDateStyle()
  }
}
