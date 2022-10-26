extension RangeReplaceableCollection {
    @usableFromInline
     internal mutating func remove(while predicate: (Element) throws -> Bool) rethrows {
        guard let index = try indices.first(where: { try !predicate(self[$0]) }) else {
            removeAll()
            return
        }
        removeSubrange(..<index)
    }
    
    @usableFromInline
    internal mutating func removeLast(while predicate: (Element) throws -> Bool) rethrows {
        guard let index = try indices.reversed().first(where: { try !predicate(self[$0]) }) else {
            removeAll()
            return
        }
        removeSubrange(self.index(after: index)...)
    }
}
