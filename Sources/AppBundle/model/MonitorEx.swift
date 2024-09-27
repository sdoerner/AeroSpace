extension Monitor {
    /// todo make 1-based
    /// 0-based index
    var monitorId: Int? {
        let sorted = sortedMonitors
        let origin = self.rect.topLeftCorner
        return sorted.firstIndex { $0.rect.topLeftCorner == origin }
    }
}
